import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import '../core/app_colors.dart';
import '../services/bluetooth_service.dart';

class BluetoothDeviceDialog extends StatefulWidget {
  final BluetoothService bluetoothService;

  const BluetoothDeviceDialog({super.key, required this.bluetoothService});

  @override
  State<BluetoothDeviceDialog> createState() => _BluetoothDeviceDialogState();
}

class _BluetoothDeviceDialogState extends State<BluetoothDeviceDialog> {
  List<BluetoothDevice> _pairedDevices = [];
  final List<BluetoothDiscoveryResult> _discoveredResults = [];
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;

  bool _isLoadingPaired = true;
  bool _isDiscovering = false;
  String? _connectingAddress;
  String? _errorMessage;

  static const _sectionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.1,
    color: AppColors.textMuted,
  );
  static const _hintStyle = TextStyle(color: AppColors.textFaint, fontSize: 12);

  @override
  void initState() {
    super.initState();
    _loadPairedDevices();
  }

  Future<void> _loadPairedDevices() async {
    setState(() {
      _isLoadingPaired = true;
      _errorMessage = null;
    });

    final isPermitted = await widget.bluetoothService.requestPermissions();
    if (!isPermitted && mounted) {
      setState(() {
        _isLoadingPaired = false;
        _errorMessage = 'Bluetooth & Location permissions are required to scan.';
      });
      return;
    }

    final isEnabled = await widget.bluetoothService.isBluetoothEnabled();
    if (!isEnabled && mounted) {
      setState(() {
        _isLoadingPaired = false;
        _errorMessage = 'Bluetooth is currently turned OFF. Please enable Bluetooth.';
      });
      return;
    }

    final devices = await widget.bluetoothService.getPairedDevices();
    if (mounted) {
      setState(() {
        _pairedDevices = devices;
        _isLoadingPaired = false;
      });
    }
  }

  void _startDiscovery() async {
    final isPermitted = await widget.bluetoothService.requestPermissions();
    if (!isPermitted) {
      if (mounted) setState(() => _errorMessage = 'Bluetooth scanning permission denied.');
      return;
    }

    setState(() {
      _isDiscovering = true;
      _discoveredResults.clear();
      _errorMessage = null;
    });

    _discoverySubscription?.cancel();
    _discoverySubscription = widget.bluetoothService.startDiscovery()?.listen(
      (result) {
        if (!mounted) return;
        final i = _discoveredResults.indexWhere(
          (r) => r.device.address == result.device.address,
        );
        setState(() => i >= 0 ? _discoveredResults[i] = result : _discoveredResults.add(result));
      },
      onDone: () {
        if (mounted) setState(() => _isDiscovering = false);
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isDiscovering = false;
            _errorMessage = 'Discovery error: $err';
          });
        }
      },
    );
  }

  void _stopDiscovery() async {
    await widget.bluetoothService.cancelDiscovery();
    _discoverySubscription?.cancel();
    if (mounted) setState(() => _isDiscovering = false);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _stopDiscovery();
    setState(() {
      _connectingAddress = device.address;
      _errorMessage = null;
    });

    final success = await widget.bluetoothService.connect(device);
    if (!mounted) return;

    setState(() => _connectingAddress = null);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage =
          'Could not connect to ${device.name ?? device.address}. Verify HC-05 is powered and paired.');
    }
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bluetooth, color: AppColors.accent, size: 26),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Select HC-05 Device',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Pair HC-05 in phone settings first (code 1234 or 0000), or scan below.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.redSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _loadPairedDevices,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isDiscovering ? _stopDiscovery : _startDiscovery,
                    icon: _isDiscovering
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.radar, size: 16),
                    label: Text(_isDiscovering ? 'Scanning...' : 'Scan Nearby'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),

              Expanded(
                child: ListView(
                  children: [
                    const Text('PAIRED DEVICES', style: _sectionStyle),
                    const SizedBox(height: 6),
                    if (_isLoadingPaired)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_pairedDevices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No paired devices found. Pair HC-05 in Android Bluetooth settings.',
                          style: _hintStyle,
                        ),
                      )
                    else
                      ..._pairedDevices.map((d) => _buildDeviceTile(d)),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('DISCOVERED DEVICES', style: _sectionStyle),
                        if (_isDiscovering)
                          const Text(
                            'Searching...',
                            style: TextStyle(fontSize: 11, color: AppColors.accent),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_discoveredResults.isEmpty && !_isDiscovering)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Tap "Scan Nearby" to search for unpaired devices.',
                          style: _hintStyle,
                        ),
                      )
                    else
                      ..._discoveredResults.map((r) => _buildDeviceTile(r.device, rssi: r.rssi)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceTile(BluetoothDevice device, {int? rssi}) {
    final name = (device.name ?? '').toUpperCase();
    final isHC05 = name.contains('HC-05') || name.contains('HC05') || name.contains('ROBOT');
    final isConnecting = _connectingAddress == device.address;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isHC05 ? AppColors.accentSoft : AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHC05 ? AppColors.accent : AppColors.border,
          width: isHC05 ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          isHC05 ? Icons.precision_manufacturing : Icons.bluetooth,
          color: isHC05 ? AppColors.accent : AppColors.textMuted,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                device.name ?? 'Unknown Device',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isHC05 ? FontWeight.bold : FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
            if (isHC05)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HC-05',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${device.address}${rssi != null ? ' • RSSI: $rssi dBm' : ''}',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        trailing: isConnecting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isHC05 ? AppColors.accent : AppColors.textMuted,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _connectToDevice(device),
                child: const Text('Connect', style: TextStyle(fontSize: 12)),
              ),
      ),
    );
  }
}
