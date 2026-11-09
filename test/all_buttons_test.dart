import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_pet/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  bool overlayRunning = false;
  String currentLanguage = 'manglish';
  double calX = 55.0;
  int calY = 4;
  int calSize = 32;

  setUp(() {
    overlayRunning = false;
    currentLanguage = 'manglish';
    calX = 55.0;
    calY = 4;
    calSize = 32;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.screenpet.app/overlay'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'checkOverlayPermission':
            return true;
          case 'isOverlayRunning':
            return overlayRunning;
          case 'startOverlay':
            overlayRunning = true;
            return true;
          case 'stopOverlay':
            overlayRunning = false;
            return true;
          case 'getStats':
            return {
              'unlockCount': 7,
              'screenTimeMs': 3600000,
              'screenTimeFormatted': '1h 00m 00s',
              'lastRoast': 'Bubbloo on duty! 🐾',
            };
          case 'pokePet':
            return 'Meow! Purring happily!';
          case 'getLanguageMode':
            return currentLanguage;
          case 'setLanguageMode':
            currentLanguage = methodCall.arguments['mode'] as String;
            return true;
          case 'getCalibration':
            return {
              'xPercent': calX,
              'yDp': calY,
              'sizeDp': calSize,
            };
          case 'updateCalibration':
            calX = (methodCall.arguments['xPercent'] as num).toDouble();
            calY = (methodCall.arguments['yDp'] as num).toInt();
            calSize = (methodCall.arguments['sizeDp'] as num).toInt();
            return true;
          case 'detectCutout':
            return {
              'detected': true,
              'xPercent': 50.0,
              'yDp': 6,
            };
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.screenpet.app/overlay'),
      null,
    );
  });

  testWidgets('Test every button on Dashboard, Calibration, and Wardrobe screens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BubblooApp());
    await tester.pumpAndSettle();

    // 1. Dashboard: Spawn Bubbloo button
    final spawnButton = find.text('Spawn Bubbloo');
    expect(spawnButton, findsOneWidget);
    await tester.tap(spawnButton);
    await tester.pumpAndSettle();
    expect(overlayRunning, isTrue);

    // 2. Dashboard: Dismiss Bubbloo button
    final dismissButton = find.text('Dismiss Bubbloo');
    expect(dismissButton, findsOneWidget);
    await tester.tap(dismissButton);
    await tester.pumpAndSettle();
    expect(overlayRunning, isFalse);

    // 3. Dashboard: Animation Pills
    final walkPill = find.text('🚶 Walk');
    expect(walkPill, findsOneWidget);
    await tester.tap(walkPill);
    await tester.pump();

    final happyPill = find.text('😸 Happy');
    expect(happyPill, findsOneWidget);
    await tester.tap(happyPill);
    await tester.pump();

    final wavePill = find.text('👋 Wave');
    expect(wavePill, findsOneWidget);
    await tester.tap(wavePill);
    await tester.pump();

    // 4. Dashboard: Language Switcher Buttons
    final englishBtn = find.text('English');
    expect(englishBtn, findsOneWidget);
    await tester.tap(englishBtn);
    await tester.pumpAndSettle();
    expect(currentLanguage, equals('english'));

    final manglishBtn = find.text('Manglish + English');
    expect(manglishBtn, findsOneWidget);
    await tester.tap(manglishBtn);
    await tester.pumpAndSettle();
    expect(currentLanguage, equals('manglish'));

    // 5. Dashboard: Poke Pet via Dialogue Card tap
    final dialogueCard = find.text('"Bubbloo on duty! 🐾"');
    if (dialogueCard.evaluate().isNotEmpty) {
      await tester.tap(dialogueCard);
      await tester.pumpAndSettle();
    }

    // 6. Dashboard: Legal sheet button
    final legalBtn = find.text('Privacy Policy & Terms of Service');
    expect(legalBtn, findsOneWidget);
    await tester.tap(legalBtn);
    await tester.pumpAndSettle();

    // Switch tabs inside legal sheet
    final termsTab = find.text('Terms of Service');
    expect(termsTab, findsWidgets);
    await tester.tap(termsTab.last);
    await tester.pumpAndSettle();

    // Close legal sheet by popping navigator
    Navigator.of(tester.element(termsTab.last)).pop();
    await tester.pumpAndSettle();

    // 7. Navigation: Switch to Calibration Tab via Bottom Bar
    final calTab = find.text('Calibration');
    expect(calTab, findsOneWidget);
    await tester.tap(calTab);
    await tester.pumpAndSettle();

    // Calibration: Snap to Cutout button
    final snapToCutoutBtn = find.text('Snap to Cutout');
    expect(snapToCutoutBtn, findsOneWidget);
    await tester.tap(snapToCutoutBtn);
    await tester.pumpAndSettle();
    expect(calX, equals(50.0));
    expect(calY, equals(6));

    // Calibration: Reset Defaults button
    final resetDefaultsBtn = find.text('Reset Defaults');
    expect(resetDefaultsBtn, findsOneWidget);
    await tester.tap(resetDefaultsBtn);
    await tester.pumpAndSettle();
    expect(calX, equals(55.0));
    expect(calY, equals(4));

    // Calibration: Reset Defaults IconButton in AppBar
    final resetIconBtn = find.byTooltip('Reset Defaults');
    expect(resetIconBtn, findsOneWidget);
    await tester.tap(resetIconBtn);
    await tester.pumpAndSettle();

    // 8. Navigation: Switch to Wardrobe Tab via Bottom Bar
    final wardrobeTab = find.text('Wardrobe');
    expect(wardrobeTab, findsOneWidget);
    await tester.tap(wardrobeTab);
    await tester.pumpAndSettle();

    // Wardrobe: Bubbloo active card
    expect(find.text('Bubbloo'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);

    // Tap active Bubbloo skin
    await tester.tap(find.text('Bubbloo'));
    await tester.pumpAndSettle();
    expect(find.text('Bubbloo is currently active on your screen!'), findsOneWidget);

    // Wardrobe: Tap locked skin
    final midnightShadow = find.text('Midnight Shadow');
    expect(midnightShadow, findsOneWidget);
    await tester.tap(midnightShadow);
    await tester.pumpAndSettle();
    expect(find.text('Midnight Shadow is coming soon! Stay tuned!'), findsOneWidget);

    // 9. Navigation: Switch back to Dashboard Tab
    final dashTab = find.text('Dashboard');
    expect(dashTab, findsOneWidget);
    await tester.tap(dashTab);
    await tester.pumpAndSettle();

    expect(find.text('Bubbloo the Notch Companion'), findsOneWidget);
  });
}
