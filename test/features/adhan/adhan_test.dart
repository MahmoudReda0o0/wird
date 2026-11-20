import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/adhan/data/adhan_plan.dart';
import 'package:my_guide/features/adhan/data/adhan_settings.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/prayer_times/data/prayer_timing_data.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  final cairo = PrayerTimingData.cairo;
  final mansoura = PrayerCity.byId('mansoura');
  const allOn = AdhanSettings(
    enabled: true,
    prayers: AdhanSettings.allPrayers,
  );

  group('AdhanPlan', () {
    test('nothing when the adhan is off', () {
      final now = tz.TZDateTime(cairo, 2026, 11, 18, 0, 30);
      expect(AdhanPlan.plan(mansoura, now, AdhanSettings.initial), isEmpty);
    });

    test('five a day, never Shurooq, all in the future', () {
      final now = tz.TZDateTime(cairo, 2026, 11, 18, 0, 30);
      final alerts = AdhanPlan.plan(mansoura, now, allOn, days: 2);
      expect(alerts.length, 10);
      expect(alerts.any((a) => a.prayer.key == 'sunrise'), isFalse);
      expect(alerts.every((a) => a.prayer.time.isAfter(now)), isTrue);
    });

    test('skips prayers that already passed today', () {
      final today = PrayerTimingData.forDay(
        mansoura,
        tz.TZDateTime(cairo, 2026, 11, 18, 9),
      );
      final afterAsr = today[3].time.add(const Duration(minutes: 1));
      final alerts = AdhanPlan.plan(mansoura, afterAsr, allOn, days: 1);
      expect(alerts.map((a) => a.prayer.key), ['maghrib', 'isha']);
    });

    test('only the prayers that are switched on', () {
      final now = tz.TZDateTime(cairo, 2026, 11, 18, 0, 30);
      const fajrOnly = AdhanSettings(enabled: true, prayers: ['fajr']);
      final alerts = AdhanPlan.plan(mansoura, now, fajrOnly, days: 3);
      expect(alerts.length, 3);
      expect(alerts.every((a) => a.prayer.key == 'fajr'), isTrue);
    });

    test('ids are unique and the default stays under iOS\'s 64 limit', () {
      final now = tz.TZDateTime(cairo, 2026, 11, 18, 0, 30);
      final alerts = AdhanPlan.plan(mansoura, now, allOn);
      final ids = alerts.map((a) => a.id).toSet();
      expect(ids.length, alerts.length);
      expect(alerts.length, lessThanOrEqualTo(64));
    });
  });

  group('AdhanSettings', () {
    test('toggle keeps prayer order', () {
      final off = allOn.toggle('asr');
      expect(off.prayers, ['fajr', 'dhuhr', 'maghrib', 'isha']);
      expect(off.toggle('asr').prayers, AdhanSettings.allPrayers);
    });

    test('isOn needs the main switch too', () {
      expect(allOn.isOn('fajr'), isTrue);
      expect(allOn.copyWith(enabled: false).isOn('fajr'), isFalse);
    });
  });
}
