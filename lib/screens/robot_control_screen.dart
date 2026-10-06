import 'package:flutter/material.dart';
import '../controllers/robot_arm_controller.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../models/joint_model.dart';
import '../services/bluetooth_service.dart';
import '../widgets/bluetooth_dialog.dart';
import '../widgets/emergency_stop_button.dart';
import '../widgets/joint_card.dart';
import '../widgets/status_badge.dart';

class RobotControlScreen extends StatefulWidget {
  const RobotControlScreen({super.key});

  @override
  State<RobotControlScreen> createState() => _RobotControlScreenState();
}

class _RobotControlScreenState extends State<RobotControlScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final RobotArmController _controller = RobotArmController();

  @override
  void initState() {
    super.initState();
    _bluetoothService.errorMessageNotifier.addListener(_onErrorMessage);
  }

  void _onErrorMessage() {
    final msg = _bluetoothService.errorMessageNotifier.value;
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bluetoothService.errorMessageNotifier.removeListener(_onErrorMessage);
    _controller.dispose();
    super.dispose();
  }

  void _openDevicePicker() {
    showDialog(
      context: context,
      builder: (context) => BluetoothDeviceDialog(bluetoothService: _bluetoothService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller,
        _bluetoothService.statusNotifier,
        _bluetoothService.connectedDeviceNotifier,
      ]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: const Row(
            children: [
              Icon(Icons.precision_manufacturing, color: AppColors.accent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ROBOTIC ARM CONTROLLER',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (!Responsive.isMobile(context))
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'HC-05 SPP • PCA9685',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                StatusBadge(
                  status: _bluetoothService.statusNotifier.value,
                  connectedDevice: _bluetoothService.connectedDeviceNotifier.value,
                  onConnectPressed: _openDevicePicker,
                  onDisconnectPressed: _bluetoothService.disconnect,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Responsive(
                    mobile: _jointList(),
                    tablet: _jointGrid(2, 1.6),
                    desktop: _jointGrid(3, 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(int i) =>
      JointCard(config: JointConfig.defaultJoints[i], controller: _controller);

  Widget _jointList() => ListView.separated(
        itemCount: JointConfig.defaultJoints.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _card(i),
      );

  Widget _jointGrid(int columns, double ratio) => GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: ratio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: JointConfig.defaultJoints.length,
        itemBuilder: (context, i) => _card(i),
      );

  Widget _buildBottomBar() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Last SPP Command: ${_controller.lastCommandSent}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const Text(
                  'Newline \\n terminated',
                  style: TextStyle(fontSize: 11, color: AppColors.textFaint),
                ),
              ],
            ),
          ),
          EmergencyStopButton(onPressed: _controller.emergencyStop),
        ],
      );
}
