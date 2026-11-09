import 'package:flutter_test/flutter_test.dart';
import 'package:screen_pet/main.dart';

void main() {
  testWidgets('BubblooApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BubblooApp());
    expect(find.text('Bubbloo'), findsOneWidget);
  });
}
