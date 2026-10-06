import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import '../core/app_colors.dart';
import '../services/bluetooth_service.dart';

class StatusBadge extends StatelessWidget {
  final BluetoothConnectionStatus status;
  final BluetoothDevice? connectedDevice;
  final VoidCallback onConnectPressed;
  final VoidCallback onDisconnectPressed;

  const StatusBadge({
    super.key,
    required this.status,
    this.connectedDevice,
    required this.onConnectPressed,
    required this.onDisconnectPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = status == BluetoothConnectionStatus.connected;
    final isConnecting = status == BluetoothConnectionStatus.connecting;

    final (color, soft, title, subtitle) = switch (status) {
      BluetoothConnectionStatus.connected => (
          AppColors.green,
          AppColors.greenSoft,
          'CONNECTED',
          connectedDevice?.name ?? connectedDevice?.address ?? 'HC-05',
        ),
      BluetoothConnectionStatus.connecting => (
          AppColors.amber,
          AppColors.amberSoft,
          'CONNECTING...',
          'Establishing SPP link...',
        ),
      _ => (
          AppColors.red,
          AppColors.redSoft,
          'DISCONNECTED',
          'Bluetooth Disconnected',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected ? AppColors.red : AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(
              isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_searching,
              size: 18,
            ),
            label: Text(
              isConnected ? 'Disconnect' : (isConnecting ? 'Cancel' : 'Connect'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: isConnected || isConnecting ? onDisconnectPressed : onConnectPressed,
          ),
        ],
      ),
    );
  }
}
