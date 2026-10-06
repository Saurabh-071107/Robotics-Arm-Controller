import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum BluetoothConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal() {
    _initBluetoothStateListener();
  }

  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<Uint8List>? _inputSubscription;

  final ValueNotifier<BluetoothConnectionStatus> statusNotifier =
      ValueNotifier<BluetoothConnectionStatus>(BluetoothConnectionStatus.disconnected);

  final ValueNotifier<BluetoothDevice?> connectedDeviceNotifier =
      ValueNotifier<BluetoothDevice?>(null);

  final ValueNotifier<String?> errorMessageNotifier = ValueNotifier<String?>(null);

  final StreamController<String> _receivedDataController =
      StreamController<String>.broadcast();
  Stream<String> get receivedDataStream => _receivedDataController.stream;

  bool get isConnected =>
      statusNotifier.value == BluetoothConnectionStatus.connected &&
      (_connection?.isConnected ?? false);

  BluetoothDevice? get connectedDevice => _connectedDevice;

  void _initBluetoothStateListener() {
    try {
      if (Platform.isAndroid) {
        FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
          if (state == BluetoothState.STATE_OFF ||
              state == BluetoothState.STATE_TURNING_OFF) {
            if (isConnected) {
              disconnect();
              errorMessageNotifier.value = 'Bluetooth was turned off.';
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Bluetooth state listener init note: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
      final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
      final locationGranted = statuses[Permission.locationWhenInUse]?.isGranted ?? false;

      return connectGranted || scanGranted || locationGranted;
    } catch (e) {
      debugPrint('Permission request error: $e');
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    if (!Platform.isAndroid) return false;
    try {
      final state = await FlutterBluetoothSerial.instance.state;
      return state == BluetoothState.STATE_ON;
    } catch (e) {
      debugPrint('Error checking Bluetooth state: $e');
      return false;
    }
  }

  Future<bool?> requestEnableBluetooth() async {
    if (!Platform.isAndroid) return false;
    try {
      return await FlutterBluetoothSerial.instance.requestEnable();
    } catch (e) {
      debugPrint('Error enabling Bluetooth: $e');
      return false;
    }
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    if (!Platform.isAndroid) return [];
    try {
      await requestPermissions();
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      debugPrint('Error getting bonded devices: $e');
      errorMessageNotifier.value = 'Failed to load paired devices: $e';
      return [];
    }
  }

  Stream<BluetoothDiscoveryResult>? startDiscovery() {
    if (!Platform.isAndroid) return null;
    try {
      return FlutterBluetoothSerial.instance.startDiscovery();
    } catch (e) {
      debugPrint('Error starting discovery: $e');
      errorMessageNotifier.value = 'Discovery failed: $e';
      return null;
    }
  }

  Future<void> cancelDiscovery() async {
    if (!Platform.isAndroid) return;
    try {
      await FlutterBluetoothSerial.instance.cancelDiscovery();
    } catch (e) {
      debugPrint('Error cancelling discovery: $e');
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    if (isConnected) {
      await disconnect();
    }

    statusNotifier.value = BluetoothConnectionStatus.connecting;
    errorMessageNotifier.value = null;

    await cancelDiscovery();
    BluetoothConnection? connection;
    for (var attempt = 1; connection == null; attempt++) {
      try {
        connection = await BluetoothConnection.toAddress(device.address)
            .timeout(const Duration(seconds: 12));
      } catch (e) {
        debugPrint('Connect attempt $attempt failed: $e');
        if (attempt == 3 || statusNotifier.value != BluetoothConnectionStatus.connecting) {
          _connection = null;
          _connectedDevice = null;
          connectedDeviceNotifier.value = null;
          statusNotifier.value = BluetoothConnectionStatus.disconnected;
          errorMessageNotifier.value =
              'Could not connect to ${device.name ?? device.address}. Make sure the HC-05 '
              'is powered (LED blinking fast), within ~10 m, and not connected to another device.';
          return false;
        }
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }

    _connection = connection;
    _connectedDevice = device;
    connectedDeviceNotifier.value = device;
    statusNotifier.value = BluetoothConnectionStatus.connected;

    _inputSubscription = connection.input.listen(
      (Uint8List data) {
        _receivedDataController.add(utf8.decode(data, allowMalformed: true));
      },
      onDone: () => _handleConnectionLost('Connection closed by remote device.'),
      onError: (error) => _handleConnectionLost('Connection error.'),
    );

    return true;
  }

  Future<void> disconnect() async {
    if (statusNotifier.value == BluetoothConnectionStatus.disconnected) return;

    statusNotifier.value = BluetoothConnectionStatus.disconnecting;

    try {
      await _inputSubscription?.cancel();
      _inputSubscription = null;
      await _connection?.close();
    } catch (e) {
      debugPrint('Error closing connection: $e');
    } finally {
      _connection = null;
      _connectedDevice = null;
      connectedDeviceNotifier.value = null;
      statusNotifier.value = BluetoothConnectionStatus.disconnected;
    }
  }

  void _handleConnectionLost(String reason) {
    _connection = null;
    _connectedDevice = null;
    connectedDeviceNotifier.value = null;
    statusNotifier.value = BluetoothConnectionStatus.disconnected;
    errorMessageNotifier.value = 'Bluetooth Disconnected: $reason';
  }

  Future<bool> sendCommand(String command) async {
    if (!isConnected || _connection == null) {
      errorMessageNotifier.value = 'Cannot send command: Bluetooth is disconnected.';
      return false;
    }

    try {
      final formatted = command.endsWith('\n') ? command : '$command\n';
      _connection!.output.add(Uint8List.fromList(utf8.encode(formatted)));
      return true;
    } catch (e) {
      debugPrint('Failed to send command "$command": $e');
      errorMessageNotifier.value = 'Write failed: $e';
      return false;
    }
  }

  void dispose() {
    disconnect();
    _receivedDataController.close();
  }
}
