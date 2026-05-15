import 'package:flutter_test/flutter_test.dart';
import 'package:sophia_app/main.dart';

void main() {
  testWidgets('Sophia app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SophiaApp());
    expect(find.text('骚飞'), findsWidgets);
  });
}
