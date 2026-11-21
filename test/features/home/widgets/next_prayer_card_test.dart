import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/features/home/widgets/next_prayer_card.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/prayer_times/data/prayer_timing_data.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/test_app.dart';

/// The card's text changes with the time of day (which prayers, which
/// times, «غدًا» after Isha), so a layout that fits at 9 am can overflow
/// at 5 pm. This walks a whole day, in winter and in summer time, for
/// the cities with the earliest and latest times, on a normal phone width,
/// and fails on any overflow.
void main() {
  final cairo = PrayerTimingData.cairo;

  Future<void> pumpCard(
    WidgetTester tester,
    TestCubits cubits,
    PrayerCity city,
    tz.TZDateTime now, {
    required bool adhanOn,
  }) async {
    await tester.pumpWidget(
      testApp(
        cubits,
        home: Scaffold(
          body: ListView(
            // The home screen's gutter: the card is 350 wide on a 390 phone.
            padding: const EdgeInsets.all(AppSpace.s5),
            children: [
              NextPrayerCard(
                window: PrayerTimingData.window(city, now),
                now: now,
                adhanOn: adhanOn,
                onAdhanTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  for (final day in [
    (label: 'winter', y: 2026, m: 11, d: 21),
    (label: 'summer time', y: 2027, m: 6, d: 21),
  ]) {
    testWidgets('fits all day long (${day.label})', (tester) async {
      usePhoneSize(tester);
      final cubits = TestCubits(await mockPrefs());
      // East, west and the default: between them they cover the spread of
      // times (e.g. 11:39 vs 12:05) the labels have to fit.
      for (final id in ['mansoura', 'sharm', 'marsa_matrouh', 'aswan']) {
        final city = PrayerCity.byId(id);
        for (var minute = 0; minute < 24 * 60; minute += 30) {
          final now = tz.TZDateTime(
            cairo,
            day.y,
            day.m,
            day.d,
            minute ~/ 60,
            minute % 60,
          );
          for (final adhanOn in [false, true]) {
            await pumpCard(tester, cubits, city, now, adhanOn: adhanOn);
            expect(
              tester.takeException(),
              isNull,
              reason: '${city.name} at ${now.hour}:${now.minute}',
            );
          }
        }
      }
    });
  }

  testWidgets('shows the previous and the next prayer under the bar', (
    tester,
  ) async {
    usePhoneSize(tester);
    final cubits = TestCubits(await mockPrefs());
    final city = PrayerCity.byId('mansoura');
    // Between Asr and Maghrib: the pair that overflowed before.
    final asr = PrayerTimingData.forDay(
      city,
      tz.TZDateTime(cairo, 2026, 11, 21, 9),
    )[3].time;
    final now = asr.add(const Duration(minutes: 20));
    await pumpCard(tester, cubits, city, now, adhanOn: false);

    final window = PrayerTimingData.window(city, now);
    expect(window.previous.name, 'العصر');
    expect(window.next.entry.name, 'المغرب');
    expect(
      find.text(
        'العصر ${PrayerTimingData.format(window.previous.time)}',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
