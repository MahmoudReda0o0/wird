import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/qibla/data/heading_source.dart';
import 'package:my_guide/features/qibla/view/qibla_screen.dart';

import '../../helpers/fake_heading_source.dart';
import '../../helpers/test_app.dart';

final _afternoon = DateTime.utc(2026, 11, 21, 12);

void main() {
  late FakeHeadingSource source;

  Future<void> pumpQibla(
    WidgetTester tester, {
    bool available = true,
    DateTime? now,
  }) async {
    usePhoneSize(tester);
    source = FakeHeadingSource(isAvailable: available);
    await tester.pumpWidget(
      testApp(
        TestCubits(await mockPrefs()),
        home: QiblaScreen(source: source, nowUtc: () => now ?? _afternoon),
      ),
    );
    await tester.pump();
  }

  Future<void> heading(
    WidgetTester tester,
    double deg, {
    bool needsCalibration = false,
  }) async {
    source.heading(deg, needsCalibration: needsCalibration);
    await tester.pump();
  }

  /// Unmounts the screen so its cubit and timers go away inside the test.
  Future<void> done(WidgetTester tester) async {
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('facing the qibla says so', (tester) async {
    await pumpQibla(tester);
    await heading(tester, 139.9);
    expect(find.text('إنت في اتجاه القبلة'), findsOneWidget);
    expect(find.text('دقة عالية'), findsOneWidget);
    await done(tester);
  });

  testWidgets('says which way to turn', (tester) async {
    await pumpQibla(tester);
    await heading(tester, 100);
    expect(find.text('لفّ يمين 40°'), findsOneWidget);
    await heading(tester, 180);
    expect(find.text('لفّ شمال 40°'), findsOneWidget);
    await done(tester);
  });

  testWidgets('asks to calibrate, and never says aligned', (tester) async {
    await pumpQibla(tester);
    await heading(tester, 139.9, needsCalibration: true);
    expect(find.text('البوصلة محتاجة معايرة'), findsOneWidget);
    expect(find.text('إنت في اتجاه القبلة'), findsNothing);
    expect(find.text('دقة ضعيفة'), findsNothing,
        reason: 'accuracy itself was high');
    await done(tester);
  });

  testWidgets('warns about iron nearby', (tester) async {
    await pumpQibla(tester);
    await heading(tester, 139.9);
    source.fieldCtrl.add(60);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('فيه حديد أو مغناطيس قريب'), findsOneWidget);
    expect(find.text('إنت في اتجاه القبلة'), findsNothing);
    await done(tester);
  });

  testWidgets('without a compass: the angle and the direction', (tester) async {
    await pumpQibla(tester, available: false);
    expect(find.text('الموبايل ده مفيهوش بوصلة'), findsOneWidget);
    expect(find.text('140°'), findsOneWidget);
    expect(find.text('جنوب شرق'), findsOneWidget);
    await done(tester);
  });

  testWidgets('the sun card opens the explanation, «تمام» closes it', (
    tester,
  ) async {
    await pumpQibla(tester);
    await heading(tester, 139.9);
    expect(find.text('اقف ووشّك للشمس، ولفّ شمال 78°'), findsOneWidget);

    await tester.ensureVisible(find.text('القبلة بالشمس'));
    await tester.tap(find.text('القبلة بالشمس'));
    await tester.pumpAndSettle();
    expect(find.text('إزاي تعرف القبلة بالشمس؟'), findsOneWidget);

    await tester.ensureVisible(find.text('تمام'));
    await tester.tap(find.text('تمام'));
    await tester.pumpAndSettle();
    expect(find.text('إزاي تعرف القبلة بالشمس؟'), findsNothing);
    await done(tester);
  });

  testWidgets('at night the sun card says the sun has set', (tester) async {
    await pumpQibla(tester, now: DateTime.utc(2026, 11, 21, 22));
    await heading(tester, 139.9);
    expect(find.text('الشمس غابت، استخدم البوصلة'), findsOneWidget);

    // Still opens the explanation, with a note that it's for the daytime.
    await tester.ensureVisible(find.text('القبلة بالشمس'));
    await tester.tap(find.text('القبلة بالشمس'));
    await tester.pumpAndSettle();
    expect(find.text('إزاي تعرف القبلة بالشمس؟'), findsOneWidget);
    expect(
      find.text('ملحوظة: الشمس غابت دلوقتي، الطريقة دي بتشتغل وقت النهار.'),
      findsOneWidget,
    );
    await done(tester);
  });

  testWidgets('no compass at night: no «use the compass» advice', (
    tester,
  ) async {
    await pumpQibla(
      tester,
      available: false,
      now: DateTime.utc(2026, 11, 21, 22),
    );
    expect(find.text('الشمس غابت، استخدم البوصلة'), findsNothing);
    expect(find.text('الشمس غابت، استخدم الزاوية فوق'), findsOneWidget);
    await done(tester);
  });

  testWidgets('frozen readings ask to hold the phone flat', (tester) async {
    await pumpQibla(tester);
    await heading(tester, 139.9);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('إنت في اتجاه القبلة'), findsNothing);
    expect(find.text('خلّي الموبايل مفرود'), findsOneWidget);
    await done(tester);
  });

  for (final variant in ['live', 'calibrate', 'noSensor']) {
    testWidgets('narrow phone, large text: $variant fits', (tester) async {
      tester.view.physicalSize = const Size(960, 1920);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      source = FakeHeadingSource(isAvailable: variant != 'noSensor');
      await tester.pumpWidget(
        testApp(
          TestCubits(await mockPrefs()),
          home: QiblaScreen(source: source, nowUtc: () => _afternoon),
        ),
      );
      await tester.pump();
      if (variant != 'noSensor') {
        source.heading(
          100,
          accuracy: CompassAccuracyLevel.low,
          needsCalibration: variant == 'calibrate',
        );
        await tester.pump();
      }
      await done(tester);
    });
  }
}
