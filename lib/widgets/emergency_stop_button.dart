import 'package:flutter/material.dart';

class EmergencyStopButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isCompact;

  const EmergencyStopButton({
    super.key,
    required this.onPressed,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isCompact ? 54 : 64,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: const Color(0xFFEF4444).withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
          ),
        ),
        onPressed: onPressed,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 28, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'EMERGENCY STOP',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
