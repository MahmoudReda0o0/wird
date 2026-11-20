import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/prayer_times/data/prayer_timing_data.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  final cairo = PrayerTimingData.cairo;
  final mansoura = PrayerCity.byId('mansoura');
  tz.TZDateTime at(int y, int m, int d, int h, int min) =>
      tz.TZDateTime(cairo, y, m, d, h, min);

  group('forDay', () {
    final day = at(2026, 11, 18, 9, 0);
    final prayers = PrayerTimingData.forDay(mansoura, day);

    test('lists the six times in order', () {
      expect(prayers.map((p) => p.name), [
        'الفجر',
        'الشروق',
        'الظهر',
        'العصر',
        'المغرب',
        'العشاء',
      ]);
      for (var i = 1; i < prayers.length; i++) {
        expect(prayers[i].time.isAfter(prayers[i - 1].time), isTrue);
      }
    });

    test('all times fall on the requested day in Cairo', () {
      for (final p in prayers) {
        expect((p.time.year, p.time.month, p.time.day), (2026, 11, 18));
      }
    });

    test('also right just after midnight', () {
      final early = PrayerTimingData.forDay(mansoura, at(2026, 11, 18, 0, 30));
      for (final p in early) {
        expect((p.time.year, p.time.month, p.time.day), (2026, 11, 18));
      }
    });

    test('Dhuhr is around solar noon for Mansoura in November', () {
      final dhuhr = prayers[2].time;
      final minutes = dhuhr.hour * 60 + dhuhr.minute;
      expect(minutes, inInclusiveRange(11 * 60 + 25, 11 * 60 + 55));
    });

    test('Shurooq is not a prayer', () {
      expect(prayers[1].isPrayer, isFalse);
      expect(prayers.where((p) => !p.isPrayer).length, 1);
    });

    test('Asr uses the Shafi madhab (earlier than Hanafi)', () {
      final hanafi = PrayerTimes(
        coordinates: Coordinates(mansoura.latitude, mansoura.longitude),
        date: DateTime(2026, 11, 18, 12),
        calculationParameters: CalculationMethodParameters.egyptian()
          ..madhab = Madhab.hanafi,
        precision: true,
      );
      final shafiAsr = prayers[3].time;
      expect(shafiAsr.isBefore(hanafi.asr), isTrue);
      // The two differ by roughly 40–70 minutes in Egypt.
      expect(
        hanafi.asr.difference(shafiAsr).inMinutes,
        inInclusiveRange(30, 90),
      );
    });
  });

  group('next', () {
    final today = PrayerTimingData.forDay(mansoura, at(2026, 11, 18, 9, 0));

    test('after midnight it is today\'s Fajr', () {
      final next = PrayerTimingData.next(mansoura, at(2026, 11, 18, 0, 30));
      expect(next.entry.name, 'الفجر');
      expect(next.isTomorrow, isFalse);
      expect(next.entry.time.day, 18);
    });

    test('after Shurooq it skips to Dhuhr', () {
      final afterSunrise = today[1].time.add(const Duration(minutes: 1));
      final next = PrayerTimingData.next(mansoura, afterSunrise);
      expect(next.entry.name, 'الظهر');
    });

    test('between Dhuhr and Asr it is Asr', () {
      final afterDhuhr = today[2].time.add(const Duration(minutes: 1));
      expect(PrayerTimingData.next(mansoura, afterDhuhr).entry.name, 'العصر');
    });

    test('after Isha it is tomorrow\'s Fajr', () {
      final afterIsha = today[5].time.add(const Duration(minutes: 1));
      final next = PrayerTimingData.next(mansoura, afterIsha);
      expect(next.entry.name, 'الفجر');
      expect(next.isTomorrow, isTrue);
      expect(next.entry.time.day, 19);
      expect(next.entry.time.isAfter(afterIsha), isTrue);
    });

    test('after Isha on the last day of the month rolls into next month', () {
      final dayEnd = PrayerTimingData.forDay(mansoura, at(2026, 11, 30, 9, 0));
      final afterIsha = dayEnd[5].time.add(const Duration(minutes: 1));
      final next = PrayerTimingData.next(mansoura, afterIsha);
      expect((next.entry.time.month, next.entry.time.day), (12, 1));
    });
  });

  group('window', () {
    final today = PrayerTimingData.forDay(mansoura, at(2026, 11, 18, 9, 0));

    test('between Dhuhr and Asr: from Dhuhr to Asr', () {
      final now = today[2].time.add(const Duration(minutes: 10));
      final w = PrayerTimingData.window(mansoura, now);
      expect(w.previous.name, 'الظهر');
      expect(w.next.entry.name, 'العصر');
      expect(w.progressAt(now), inExclusiveRange(0.0, 1.0));
    });

    test('after Shurooq the previous prayer is still Fajr', () {
      final now = today[1].time.add(const Duration(minutes: 5));
      final w = PrayerTimingData.window(mansoura, now);
      expect(w.previous.name, 'الفجر');
      expect(w.next.entry.name, 'الظهر');
    });

    test('before Fajr: from yesterday\'s Isha', () {
      final now = at(2026, 11, 18, 2, 0);
      final w = PrayerTimingData.window(mansoura, now);
      expect(w.previous.name, 'العشاء');
      expect(w.previous.time.day, 17);
      expect(w.next.entry.name, 'الفجر');
      expect(w.next.isTomorrow, isFalse);
    });

    test('after Isha: from Isha to tomorrow\'s Fajr', () {
      final now = today[5].time.add(const Duration(minutes: 30));
      final w = PrayerTimingData.window(mansoura, now);
      expect(w.previous.name, 'العشاء');
      expect(w.previous.time.day, 18);
      expect(w.next.isTomorrow, isTrue);
    });

    test('progress runs from 0 at the previous prayer to 1 at the next', () {
      final now = today[2].time.add(const Duration(minutes: 1));
      final w = PrayerTimingData.window(mansoura, now);
      expect(w.progressAt(w.previous.time), 0);
      expect(w.progressAt(w.next.entry.time), 1);
      expect(w.progressAt(w.next.entry.time.add(const Duration(hours: 1))), 1);
    });
  });

  group('countdown', () {
    test('HH:MM:SS with leading zeros', () {
      expect(
        PrayerTimingData.countdown(
          const Duration(hours: 1, minutes: 24, seconds: 37),
        ),
        '01:24:37',
      );
      expect(PrayerTimingData.countdown(const Duration(seconds: 5)), '00:00:05');
      expect(PrayerTimingData.countdown(const Duration(hours: 12)), '12:00:00');
    });

    test('never negative', () {
      expect(
        PrayerTimingData.countdown(const Duration(seconds: -3)),
        '00:00:00',
      );
    });
  });

  group('dateLabel', () {
    test('Arabic weekday, day and month', () {
      // 18 Nov 2026 is a Wednesday.
      expect(PrayerTimingData.dateLabel(DateTime(2026, 11, 18)), 'الأربعاء 18 نوفمبر');
      // 1 Jan 2027 is a Friday.
      expect(PrayerTimingData.dateLabel(DateTime(2027, 1, 1)), 'الجمعة 1 يناير');
    });
  });

  group('format', () {
    test('12-hour clock with Arabic AM/PM', () {
      expect(PrayerTimingData.format(DateTime(2026, 1, 1, 0, 5)), '12:05 ص');
      expect(PrayerTimingData.format(DateTime(2026, 1, 1, 4, 48)), '4:48 ص');
      expect(PrayerTimingData.format(DateTime(2026, 1, 1, 12, 0)), '12:00 م');
      expect(PrayerTimingData.format(DateTime(2026, 1, 1, 15, 21)), '3:21 م');
    });
  });

  group('remaining', () {
    test('hours and minutes', () {
      expect(
        PrayerTimingData.remaining(const Duration(hours: 2, minutes: 5)),
        '2:05 ساعة',
      );
    });
    test('minutes only', () {
      expect(
        PrayerTimingData.remaining(const Duration(minutes: 45)),
        '45 دقيقة',
      );
    });
    test('never less than one minute', () {
      expect(
        PrayerTimingData.remaining(const Duration(seconds: 20)),
        '1 دقيقة',
      );
    });
  });

  group('PrayerCity', () {
    test('ids are unique', () {
      final ids = PrayerCity.all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('unknown or missing id falls back to Mansoura', () {
      expect(PrayerCity.byId(null).id, 'mansoura');
      expect(PrayerCity.byId('nowhere').id, 'mansoura');
    });

    test('every city is inside Egypt', () {
      for (final c in PrayerCity.all) {
        expect(c.latitude, inInclusiveRange(22.0, 31.7), reason: c.name);
        expect(c.longitude, inInclusiveRange(24.7, 36.9), reason: c.name);
      }
    });
  });
}
