import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:my_guide/features/adhan/data/adhan_settings.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/prayer_times/data/prayer_timing_data.dart';

/// One adhan to schedule.
@immutable
class AdhanAlert {
  const AdhanAlert(this.id, this.prayer);

  /// Notification id: day offset × 10 + the prayer's row (0–5).
  final int id;
  final PrayerEntry prayer;
}

/// Which adhans to schedule. Pure, so it can be tested.
class AdhanPlan {
  AdhanPlan._();

  /// How many days ahead are scheduled. Rescheduled on every app start, on
  /// a city or settings change. 10 days × 5 prayers stays under iOS's limit
  /// of 64 pending notifications.
  static const days = 10;

  static List<AdhanAlert> plan(
    PrayerCity city,
    tz.TZDateTime now,
    AdhanSettings settings, {
    int days = AdhanPlan.days,
  }) {
    if (!settings.enabled) return const [];
    final alerts = <AdhanAlert>[];
    for (var d = 0; d < days; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      final prayers = PrayerTimingData.forDay(city, day);
      for (var i = 0; i < prayers.length; i++) {
        final p = prayers[i];
        if (!p.isPrayer || !settings.prayers.contains(p.key)) continue;
        if (!p.time.isAfter(now)) continue;
        alerts.add(AdhanAlert(d * 10 + i, p));
      }
    }
    return alerts;
  }
}
