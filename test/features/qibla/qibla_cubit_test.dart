import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/qibla/cubit/qibla_cubit.dart';
import 'package:my_guide/features/qibla/cubit/qibla_state.dart';
import 'package:my_guide/features/qibla/data/heading_source.dart';
import 'package:my_guide/features/qibla/data/sun_position.dart';

import '../../helpers/fake_heading_source.dart';

final _mansoura = PrayerCity.byId('mansoura');
final _aswan = PrayerCity.byId('aswan');
final _afternoon = DateTime.utc(2026, 11, 21, 12);

void main() {
  late FakeHeadingSource source;
  late QiblaCubit cubit;

  Future<void> startWith(
    WidgetTester tester, {
    bool available = true,
    DateTime? now,
    PrayerCity? city,
  }) async {
    source = FakeHeadingSource(isAvailable: available);
    cubit = QiblaCubit(source, city ?? _mansoura, nowUtc: () => now ?? _afternoon);
    await cubit.start();
    await tester.pump();
  }

  Future<void> heading(
    WidgetTester tester,
    double deg, {
    CompassAccuracyLevel accuracy = CompassAccuracyLevel.high,
    bool needsCalibration = false,
  }) async {
    source.heading(deg, accuracy: accuracy, needsCalibration: needsCalibration);
    await tester.pump();
  }

  // Closes inside the test's fake-async zone: a tearDown would await the
  // cubit's stream controllers outside it and never finish.
  void qiblaTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        await body(tester);
        await cubit.close();
      });

  qiblaTest('no compass → noSensor', (tester) async {
    await startWith(tester, available: false);
    expect(cubit.state.status, QiblaStatus.noSensor);
    expect(cubit.state.qibla, closeTo(139.9, 0.2));
  });

  qiblaTest('facing the qibla is aligned, and counted once', (tester) async {
    await startWith(tester);
    expect(cubit.state.status, QiblaStatus.loading);
    expect(source.lastTarget?.lat, _mansoura.latitude);

    debugPrint('QT facing: before 139');
    await heading(tester, 139);
    debugPrint('QT facing: after 139');
    expect(cubit.state.status, QiblaStatus.live);
    expect(cubit.state.delta, closeTo(0.9, 0.2));
    expect(cubit.state.aligned, isTrue);
    expect(cubit.state.alignedCount, 1);

    await heading(tester, 140);
    expect(cubit.state.alignedCount, 1, reason: 'still aligned');

    await heading(tester, 100);
    expect(cubit.state.delta, closeTo(39.9, 0.2));
    expect(cubit.state.aligned, isFalse);

    await heading(tester, 139);
    expect(cubit.state.alignedCount, 2);
  });

  qiblaTest('across north it turns the short way', (tester) async {
    await startWith(tester);
    await heading(tester, 359);
    expect(cubit.state.delta, closeTo(139.9 + 1, 0.2));
    await heading(tester, 300);
    expect(cubit.state.delta, closeTo(-160.1, 0.2));
  });

  qiblaTest('calibration needed: unreliable, never aligned', (tester) async {
    await startWith(tester);
    await heading(tester, 139.9, needsCalibration: true);
    expect(cubit.state.unreliable, isTrue);
    expect(cubit.state.aligned, isFalse);
    expect(cubit.state.alignedCount, 0);
  });

  qiblaTest('unreliable accuracy is unreliable', (tester) async {
    await startWith(tester);
    await heading(tester, 139.9, accuracy: CompassAccuracyLevel.unreliable);
    expect(cubit.state.unreliable, isTrue);
    expect(cubit.state.aligned, isFalse);
  });

  qiblaTest('iron nearby for a second → interference, and it clears', (
    tester,
  ) async {
    await startWith(tester);
    await heading(tester, 139.9);

    source.fieldCtrl.add(60);
    await tester.pump(const Duration(milliseconds: 500));
    expect(cubit.state.interference, isFalse, reason: 'too short');
    source.fieldCtrl.add(3);
    await tester.pump(const Duration(seconds: 2));
    expect(cubit.state.interference, isFalse);

    source.fieldCtrl.add(60);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(cubit.state.interference, isTrue);
    expect(cubit.state.unreliable, isTrue);
    expect(cubit.state.aligned, isFalse);

    source.fieldCtrl.add(4);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(cubit.state.interference, isFalse);
    expect(cubit.state.aligned, isTrue);
  });

  qiblaTest('a broken sensor stream → noSensor', (tester) async {
    await startWith(tester);
    await heading(tester, 100);
    source.readingsCtrl.addError(StateError('sensor gone'));
    await tester.pump();
    expect(cubit.state.status, QiblaStatus.noSensor);
  });

  qiblaTest('no reading within 2 s → noSensor', (tester) async {
    await startWith(tester);
    await tester.pump(const Duration(milliseconds: 1900));
    expect(cubit.state.status, QiblaStatus.loading);
    await tester.pump(const Duration(milliseconds: 200));
    expect(cubit.state.status, QiblaStatus.noSensor);
  });

  qiblaTest('changing the city re-targets at once', (tester) async {
    await startWith(tester);
    await heading(tester, 139);
    cubit.setCity(_aswan);
    await tester.pump();
    expect(cubit.state.city.id, 'aswan');
    expect(cubit.state.qibla, closeTo(111.3, 0.2));
    expect(source.lastTarget?.lat, _aswan.latitude);
    expect(cubit.state.aligned, isFalse);
  });

  qiblaTest('the sun: where it is, and how far the qibla is from it', (
    tester,
  ) async {
    await startWith(tester);
    expect(cubit.state.sun.isUp, isTrue);
    expect(cubit.state.sun.azimuth, closeTo(218, 1.5));
    expect(cubit.state.sunDelta, closeTo(-78, 2));
  });

  qiblaTest('at night the sun is down', (tester) async {
    await startWith(tester, now: DateTime.utc(2026, 11, 21, 22));
    expect(cubit.state.sun.isUp, isFalse);
  });

  qiblaTest('the Kaaba sun day is known only on that day', (tester) async {
    final transit = SunPosition.kaabaTransits(2027).first;
    await startWith(tester, now: transit.subtract(const Duration(hours: 3)));
    expect(cubit.state.kaabaSunToday, transit);
    await cubit.close();

    await startWith(tester, now: transit.subtract(const Duration(days: 1)));
    expect(cubit.state.kaabaSunToday, isNull);
  });

  qiblaTest('closing disposes the source', (tester) async {
    await startWith(tester);
    await cubit.close();
    expect(source.disposed, isTrue);
  });
}
