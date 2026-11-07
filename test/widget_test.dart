import 'package:flutter_test/flutter_test.dart';
import 'package:screen_pet/main.dart';

void main() {
  testWidgets('ScreenPetApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScreenPetApp());
    expect(find.text('ScreenPet'), findsOneWidget);
  });
}
