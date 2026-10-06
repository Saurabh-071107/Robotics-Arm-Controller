import 'package:flutter/material.dart';
import '../controllers/robot_arm_controller.dart';
import '../core/app_colors.dart';
import '../models/joint_model.dart';

class JointCard extends StatelessWidget {
  final JointConfig config;
  final RobotArmController controller;

  const JointCard({super.key, required this.config, required this.controller});

  @override
  Widget build(BuildContext context) {
    final enabled = controller.isConnected;
    final angle = controller.getAngle(config.id);

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${config.id} — ${config.name}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: enabled ? AppColors.text : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _chip('PCA9685 ${config.channel}', AppColors.accent),
                    ],
                  ),
                ),
                _statusChip(enabled, angle),
              ],
            ),
            const SizedBox(height: 16),
            _positionalControls(context, enabled, angle),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Command: ${config.id}:${angle.toInt()}\\n',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: enabled ? AppColors.accent : AppColors.textFaint,
                  ),
                ),
                Text(
                  'Range: ${config.minAngle.toInt()}°–${config.maxAngle.toInt()}°',
                  style: const TextStyle(fontSize: 11, color: AppColors.textFaint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _chip(String text, Color color, {double size = 12}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w800),
        ),
      );

  Widget _statusChip(bool enabled, double angle) {
    if (!enabled) return _chip('LOCKED', AppColors.textMuted, size: 14);
    return _chip('${angle.toInt()}°', AppColors.accent, size: 14);
  }

  Widget _positionalControls(BuildContext context, bool enabled, double angle) {
    final min = config.minAngle, max = config.maxAngle;
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.accentSoft,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withValues(alpha: 0.12),
            disabledActiveTrackColor: AppColors.textFaint,
            disabledInactiveTrackColor: AppColors.border,
            disabledThumbColor: AppColors.textFaint,
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: angle.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            label: '${angle.toInt()}°',
            onChanged: enabled ? (v) => controller.setJointAngle(config, v) : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [min, (min + max) / 2, max]
                .map((v) => Text('${v.toInt()}°',
                    style: const TextStyle(fontSize: 11, color: AppColors.textFaint)))
                .toList(),
          ),
        ),
      ],
    );
  }
}
