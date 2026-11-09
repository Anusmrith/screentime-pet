import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_pet/screens/dashboard_screen.dart';
import 'package:screen_pet/theme/botanical_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String currentLanguage = 'manglish';

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.screenpet.app/overlay'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkOverlayPermission') {
          return true;
        }
        if (methodCall.method == 'isOverlayRunning') {
          return true;
        }
        if (methodCall.method == 'getStats') {
          return {
            'unlockCount': 10,
            'screenTimeFormatted': '1h 15m',
            'lastRoast': 'ScreenPet on duty! 🐾',
          };
        }
        if (methodCall.method == 'getLanguageMode') {
          return currentLanguage;
        }
        if (methodCall.method == 'setLanguageMode') {
          currentLanguage = methodCall.arguments['mode'] as String;
          return true;
        }
        return null;
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

  testWidgets('DashboardScreen renders language switcher and switches between English and Manglish',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: BotanicalTheme.themeData,
        home: DashboardScreen(onNavigateToCalibration: () {}),
      ),
    );

    await tester.pump();

    // Verify language switcher buttons exist
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Manglish + English'), findsOneWidget);

    // Tap English
    await tester.tap(find.text('English'));
    await tester.pump();
    expect(currentLanguage, 'english');
    expect(find.text('Switched to English dialogues only!'), findsOneWidget);

    // Tap Manglish + English
    await tester.tap(find.text('Manglish + English'));
    await tester.pump();
    expect(currentLanguage, 'manglish');
    expect(find.text('Switched to Manglish + English dialogues!'), findsOneWidget);
  });

  testWidgets('DashboardScreen displays Privacy Policy and Terms of Service sheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: BotanicalTheme.themeData,
        home: DashboardScreen(onNavigateToCalibration: () {}),
      ),
    );

    await tester.pump();

    final legalButton = find.text('Privacy Policy & Terms of Service');
    expect(legalButton, findsOneWidget);

    await tester.tap(legalButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // bottom sheet animation

    expect(find.text('100% Offline Architecture'), findsOneWidget);
    expect(find.text('Zero Data Collection'), findsOneWidget);

    // Switch to Terms of Service tab
    await tester.tap(find.text('Terms of Service'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Digital Wellbeing Companion'), findsOneWidget);
    expect(find.text('Non-Medical Disclaimer'), findsOneWidget);
  });
}

