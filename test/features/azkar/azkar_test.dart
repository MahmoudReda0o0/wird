import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/azkar/data/sources/awake_azkar.dart';
import 'package:my_guide/features/azkar/data/sources/evening_azkar.dart';
import 'package:my_guide/features/azkar/data/sources/morning_azkar.dart';
import 'package:my_guide/features/azkar/data/sources/sleep_azkar.dart';
import 'package:my_guide/features/azkar/data/sources/tasabih_azkar.dart';
import 'package:my_guide/features/azkar/data/azkar_progress.dart';
import 'package:my_guide/features/azkar/widgets/azkar_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('azkarCounterLabel', () {
    test('uses Arabic counting forms', () {
      expect(azkarCounterLabel(1), 'مرة واحدة');
      expect(azkarCounterLabel(2), 'مرتان');
      expect(azkarCounterLabel(3), '3 مرات');
      expect(azkarCounterLabel(10), '10 مرات');
      expect(azkarCounterLabel(11), '11 مرة');
      expect(azkarCounterLabel(100), '100 مرة');
    });
  });

  group('azkar data', () {
    final sections = {
      'morning': MorningAzkar.morningAzkar,
      'evening': EveningAzkar.eveningAzkar,
      'tasabih': TasabihAzkar.tasabihAzkar,
      'sleep': SleepAzkar.sleepAzkar,
      'wake_up': WakeUpAzkar.wakeUpAzkar,
    };

    test('every section has azkar', () {
      sections.forEach((name, list) {
        expect(list, isNotEmpty, reason: name);
      });
    });

    test('every zikr has text and at least one repetition', () {
      sections.forEach((name, list) {
        for (final z in list) {
          expect(z.content.trim(), isNotEmpty, reason: name);
          expect(z.repetition, greaterThan(0), reason: '$name: ${z.content}');
        }
      });
    });
  });

  group('AzkarProgress.restore', () {
    const today = '2026-11-18';
    const defaults = [3, 1, 100];

    test('nothing saved gives the full counts', () {
      expect(AzkarProgress.restore(null, defaults, today), defaults);
    });

    test('same day restores the saved counts', () {
      expect(
        AzkarProgress.restore([today, '2', '0', '57'], defaults, today),
        [2, 0, 57],
      );
    });

    test('a new day starts again', () {
      expect(
        AzkarProgress.restore(['2026-11-17', '0', '0', '0'], defaults, today),
        defaults,
      );
    });

    test('a save that no longer fits the section is ignored', () {
      // The section gained or lost a zikr since it was saved.
      expect(
        AzkarProgress.restore([today, '0', '0'], defaults, today),
        defaults,
      );
      // A count above the zikr's repetitions.
      expect(
        AzkarProgress.restore([today, '9', '0', '0'], defaults, today),
        defaults,
      );
      // Not a number.
      expect(
        AzkarProgress.restore([today, 'x', '0', '0'], defaults, today),
        defaults,
      );
    });

    test('the result can be changed without touching the defaults', () {
      final counts = AzkarProgress.restore(null, defaults, today);
      counts[0]--;
      expect(defaults, [3, 1, 100]);
    });

    test('encode and restore round-trip', () {
      final saved = AzkarProgress.encode([1, 0, 40], today);
      expect(AzkarProgress.restore(saved, defaults, today), [1, 0, 40]);
    });
  });

  group('AzkarProgress load and save', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('saves per section and per day', () async {
      final prefs = await SharedPreferences.getInstance();
      final day = DateTime(2026, 11, 18, 8);
      await AzkarProgress.save(prefs, 'morning', [0, 1], now: day);

      expect(AzkarProgress.load(prefs, 'morning', [3, 1], now: day), [0, 1]);
      // Another section is untouched.
      expect(AzkarProgress.load(prefs, 'evening', [3, 1], now: day), [3, 1]);
      // The next day starts again.
      final tomorrow = DateTime(2026, 11, 19, 8);
      expect(
        AzkarProgress.load(prefs, 'morning', [3, 1], now: tomorrow),
        [3, 1],
      );
    });
  });

  test('dayKey pads month and day', () {
    expect(AzkarProgress.dayKey(DateTime(2026, 3, 7)), '2026-03-07');
  });
}
