import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:my_guide/feature/screen/prayer_timing/prayer_city.dart';

/// One row in the prayer-times list.
@immutable
class PrayerEntry {
  const PrayerEntry(this.name, this.time, {this.isPrayer = true});
  final String name;
  final tz.TZDateTime time;

  /// Shurooq is listed but is not a prayer, so it's never "next".
  final bool isPrayer;
}

/// The upcoming prayer. After Isha it's tomorrow's Fajr.
@immutable
class NextPrayer {
  const NextPrayer(this.entry, {required this.isTomorrow});
  final PrayerEntry entry;
  final bool isTomorrow;
}

/// The stretch of time the user is in: from the last prayer to the next.
/// Before Fajr the last prayer is yesterday's Isha; after Isha the next
/// one is tomorrow's Fajr.
@immutable
class PrayerWindow {
  const PrayerWindow({required this.previous, required this.next});
  final PrayerEntry previous;
  final NextPrayer next;

  /// How much of the wait has passed at [now], from 0 to 1.
  double progressAt(DateTime now) {
    final total = next.entry.time.difference(previous.time).inSeconds;
    if (total <= 0) return 0;
    final passed = now.difference(previous.time).inSeconds;
    return (passed / total).clamp(0.0, 1.0).toDouble();
  }
}

/// Prayer-time calculations. Pure functions so they can be tested.
///
/// Uses the Egyptian General Authority of Survey method with the Shafi
/// madhab for Asr — the times used in Egypt.
class PrayerTimingData {
  PrayerTimingData._();

  static tz.Location? _cairo;

  /// Africa/Cairo. Loads the time-zone database on first use.
  static tz.Location get cairo {
    if (_cairo == null) {
      tz_data.initializeTimeZones();
      _cairo = tz.getLocation('Africa/Cairo');
    }
    return _cairo!;
  }

  static CalculationParameters get parameters =>
      CalculationMethodParameters.egyptian()..madhab = Madhab.shafi;

  /// The current time in Cairo, whatever the device's time zone is.
  static tz.TZDateTime now() => tz.TZDateTime.now(cairo);

  /// The six times for [day] (its year, month and day are used) in [city].
  static List<PrayerEntry> forDay(PrayerCity city, DateTime day) {
    final times = PrayerTimes(
      coordinates: Coordinates(city.latitude, city.longitude),
      // Midday keeps the same calendar day whether the library reads the
      // date as local time or as UTC.
      date: DateTime(day.year, day.month, day.day, 12),
      calculationParameters: parameters,
      precision: true,
    );

    tz.TZDateTime local(DateTime t) => tz.TZDateTime.from(t, cairo);

    return [
      PrayerEntry('الفجر', local(times.fajr)),
      PrayerEntry('الشروق', local(times.sunrise), isPrayer: false),
      PrayerEntry('الظهر', local(times.dhuhr)),
      PrayerEntry('العصر', local(times.asr)),
      PrayerEntry('المغرب', local(times.maghrib)),
      PrayerEntry('العشاء', local(times.isha)),
    ];
  }

  /// The first prayer after [now]; tomorrow's Fajr once Isha has passed.
  static NextPrayer next(PrayerCity city, tz.TZDateTime now) {
    for (final p in forDay(city, now)) {
      if (p.isPrayer && p.time.isAfter(now)) {
        return NextPrayer(p, isTomorrow: false);
      }
    }
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return NextPrayer(forDay(city, tomorrow).first, isTomorrow: true);
  }

  /// The last prayer at or before [now] and the next one after it.
  static PrayerWindow window(PrayerCity city, tz.TZDateTime now) {
    final upcoming = PrayerTimingData.next(city, now);
    PrayerEntry? previous;
    for (final p in forDay(city, now)) {
      if (p.isPrayer && !p.time.isAfter(now)) previous = p;
    }
    previous ??= forDay(
      city,
      DateTime(now.year, now.month, now.day - 1),
    ).lastWhere((p) => p.isPrayer);
    return PrayerWindow(previous: previous, next: upcoming);
  }

  /// "3:21 م" — 12-hour clock with an Arabic AM/PM mark.
  static String format(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }

  /// "01:24:37" — the live countdown on the home screen.
  static String countdown(Duration d) {
    final seconds = d.isNegative ? 0 : d.inSeconds;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(seconds ~/ 3600)}:${two(seconds % 3600 ~/ 60)}:${two(seconds % 60)}';
  }

  /// "الأربعاء 18 نوفمبر".
  static String dateLabel(DateTime d) {
    const days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  /// "2:05 ساعة" or "45 دقيقة". Never shows less than one minute.
  static String remaining(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')} ساعة';
    }
    return '${d.inMinutes < 1 ? 1 : d.inMinutes} دقيقة';
  }
}
