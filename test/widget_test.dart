import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm/main.dart';

void main() {
  testWidgets('RoboticArmApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RoboticArmApp());
    expect(find.text('ROBOTIC ARM CONTROLLER'), findsOneWidget);
  });
}
