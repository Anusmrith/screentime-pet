import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_pet/screens/calibration_screen.dart';
import 'package:screen_pet/theme/botanical_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.screenpet.app/overlay'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getCalibration') {
          return {'xPercent': 55.0, 'yDp': 4, 'sizeDp': 32};
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

  testWidgets('CalibrationScreen renders without any overflow on narrow screen (320px)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: BotanicalTheme.themeData,
        home: const CalibrationScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Punch-Hole Calibration'), findsOneWidget);
    expect(find.text('Reset Defaults'), findsOneWidget);
    expect(find.text('Snap to Cutout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CalibrationScreen renders without any overflow on standard screen (360px) with 1.3x font scale',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: BotanicalTheme.themeData,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: CalibrationScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Punch-Hole Calibration'), findsOneWidget);
    expect(find.text('Reset Defaults'), findsOneWidget);
    expect(find.text('Snap to Cutout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CalibrationScreen renders without any overflow on ultra-compact screen (300px) with 1.5x font scale',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(300, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: BotanicalTheme.themeData,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: CalibrationScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Punch-Hole Calibration'), findsOneWidget);
    expect(find.text('Reset Defaults'), findsOneWidget);
    expect(find.text('Snap to Cutout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
