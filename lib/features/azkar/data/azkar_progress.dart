import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_guide/core/time/app_clock.dart';

/// Saves how many repetitions are left for each zikr in a section.
///
/// Progress belongs to one day: on a new day every section starts again
/// from its full counts. Days follow Egypt's time ([AppClock]), like the
/// prayer times.
///
/// Stored as a string list: `[day, remaining0, remaining1, …]`.
class AzkarProgress {
  AzkarProgress._();

  static String _key(String sectionId) => 'azkar_progress_$sectionId';

  /// "2026-11-18".
  static String dayKey(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  /// Decodes [saved]. Falls back to [defaults] when nothing is saved, the
  /// save is from another day, or it doesn't match the section any more.
  static List<int> restore(
    List<String>? saved,
    List<int> defaults,
    String today,
  ) {
    if (saved == null ||
        saved.length != defaults.length + 1 ||
        saved.first != today) {
      return List.of(defaults);
    }
    final counts = <int>[];
    for (var i = 0; i < defaults.length; i++) {
      final value = int.tryParse(saved[i + 1]);
      if (value == null || value < 0 || value > defaults[i]) {
        return List.of(defaults);
      }
      counts.add(value);
    }
    return counts;
  }

  static List<String> encode(List<int> counts, String today) => [
    today,
    for (final c in counts) '$c',
  ];

  static List<int> load(
    SharedPreferences prefs,
    String sectionId,
    List<int> defaults, {
    DateTime? now,
  }) {
    return restore(
      prefs.getStringList(_key(sectionId)),
      defaults,
      dayKey(now ?? AppClock.now()),
    );
  }

  static Future<void> save(
    SharedPreferences prefs,
    String sectionId,
    List<int> counts, {
    DateTime? now,
  }) {
    return prefs.setStringList(
      _key(sectionId),
      encode(counts, dayKey(now ?? AppClock.now())),
    );
  }
}
