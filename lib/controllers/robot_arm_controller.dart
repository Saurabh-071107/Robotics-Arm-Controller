import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/joint_model.dart';
import '../services/bluetooth_service.dart';

class RobotArmController extends ChangeNotifier {
  final BluetoothService _bluetoothService = BluetoothService();

  final Map<String, double> _jointAngles = {};

  String _lastCommandSent = 'None';
  String get lastCommandSent => _lastCommandSent;

  final Map<String, Timer?> _throttleTimers = {};
  final Map<String, double> _pendingAngles = {};

  RobotArmController() {
    _initJointDefaults();
    _bluetoothService.statusNotifier.addListener(notifyListeners);
  }

  void _initJointDefaults() {
    for (final joint in JointConfig.defaultJoints) {
      _jointAngles[joint.id] = joint.defaultAngle;
    }
  }

  double getAngle(String jointId) => _jointAngles[jointId] ?? 0;

  bool get isConnected => _bluetoothService.isConnected;

  void setJointAngle(JointConfig config, double requestedAngle) {
    if (!isConnected) return;

    final clampedAngle = requestedAngle.clamp(config.minAngle, config.maxAngle);
    final roundedAngle = clampedAngle.roundToDouble();

    _jointAngles[config.id] = roundedAngle;
    _pendingAngles[config.id] = roundedAngle;
    notifyListeners();

    if (_throttleTimers[config.id]?.isActive ?? false) return;

    _throttleTimers[config.id] = Timer(const Duration(milliseconds: 45), () async {
      final angleToSend = _pendingAngles[config.id];
      if (angleToSend != null && isConnected) {
        final cmd = '${config.id}:${angleToSend.toInt()}\n';
        _lastCommandSent = '${config.id}:${angleToSend.toInt()}';
        notifyListeners();
        await _bluetoothService.sendCommand(cmd);
      }
    });
  }

  Future<void> emergencyStop() async {
    _lastCommandSent = 'STOP:0';
    notifyListeners();

    if (isConnected) {
      await _bluetoothService.sendCommand('STOP:0\n');
    }
  }

  @override
  void dispose() {
    _bluetoothService.statusNotifier.removeListener(notifyListeners);
    for (final timer in _throttleTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }
}
