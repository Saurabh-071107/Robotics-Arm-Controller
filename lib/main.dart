import 'package:flutter/material.dart';
import 'core/app_colors.dart';
import 'screens/robot_control_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RoboticArmApp());
}

class RoboticArmApp extends StatelessWidget {
  const RoboticArmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robotic Arm Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent).copyWith(
          primary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.red,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const RobotControlScreen(),
    );
  }
}
