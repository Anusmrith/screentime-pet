import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_pet/screens/wardrobe_screen.dart';
import 'package:screen_pet/theme/botanical_theme.dart';

void main() {
  testWidgets('WardrobeScreen highlights Bubbloo and leaves other skins locked',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: BotanicalTheme.themeData,
        home: const WardrobeScreen(),
      ),
    );

    await tester.pump();

    // Verify Bubbloo is present and highlighted
    expect(find.text('Bubbloo'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('Current Pet'), findsOneWidget);

    // Verify other skins show Coming Soon
    expect(find.text('Midnight Shadow'), findsOneWidget);
    expect(find.text('Cyber Neo-Cat'), findsOneWidget);
    expect(find.text('Coming Soon'), findsNWidgets(5)); // 5 locked skins

    // Tap on Bubbloo: should show active toast, NOT "coming soon"
    await tester.tap(find.text('Bubbloo'));
    await tester.pump();
    expect(
      find.text('Bubbloo is currently active on your screen!'),
      findsOneWidget,
    );

    // Tap on a locked skin: should show coming soon toast
    await tester.tap(find.text('Midnight Shadow'));
    await tester.pump();
    expect(
      find.text('Midnight Shadow is coming soon! Stay tuned!'),
      findsOneWidget,
    );
  });
}
