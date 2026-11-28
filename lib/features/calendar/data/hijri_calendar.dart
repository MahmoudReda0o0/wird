import 'package:flutter/foundation.dart';
import 'package:my_guide/core/time/hijri_date.dart';

/// Something on a Hijri day: an occasion or a recommended fast.
@immutable
class Occasion {
  const Occasion(this.name, {this.note, this.fast = false});

  final String name;
  final String? note;

  /// A recommended (sunnah) fast.
  final bool fast;
}

/// One day of the calendar.
@immutable
class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.hijri,
    required this.occasions,
  });

  /// The Gregorian day (year, month, day; midnight local).
  final DateTime date;
  final HijriDate hijri;
  final List<Occasion> occasions;

  /// 13, 14 and 15 of the month (when fasting is allowed).
  bool get isWhiteDay =>
      occasions.any((o) => identical(o, HijriCalendarData.whiteDays));

  /// Monday or Thursday, when fasting is allowed.
  bool get isSunnahWeekday =>
      occasions.any((o) => identical(o, HijriCalendarData.weekday));

  /// A named occasion (not the weekly or white-days fasts).
  Occasion? get named {
    for (final o in occasions) {
      if (!identical(o, HijriCalendarData.whiteDays) &&
          !identical(o, HijriCalendarData.weekday)) {
        return o;
      }
    }
    return null;
  }

  bool get isFast => occasions.any((o) => o.fast);
}

/// An occasion coming up, for «المناسبات الجاية».
@immutable
class UpcomingOccasion {
  const UpcomingOccasion(this.day, this.occasion, this.daysLeft);

  final CalendarDay day;
  final Occasion occasion;
  final int daysLeft;
}

/// The Hijri calendar with Egypt's occasions, from [HijriDate] (Umm
/// al-Qura moved by the `hijri_offset` from Supabase). Pure logic.
class HijriCalendarData {
  HijriCalendarData._();

  static const whiteDays = Occasion(
    'الأيام البيض',
    note: 'صيام 13 و14 و15 من كل شهر هجري سنّة.',
    fast: true,
  );

  static const weekday = Occasion(
    'صيام الإتنين والخميس',
    note: 'صيامهم سنّة عن النبي ﷺ.',
    fast: true,
  );

  /// Occasions on fixed Hijri dates: (month, day).
  static const fixed = <(int, int), Occasion>{
    (1, 1): Occasion('رأس السنة الهجرية', note: 'بداية سنة هجرية جديدة.'),
    (1, 9): Occasion(
      'تاسوعاء',
      note: 'صيامه مع عاشوراء مستحب.',
      fast: true,
    ),
    (1, 10): Occasion(
      'عاشوراء',
      note: 'صيامه يكفّر السنة اللي فاتت.',
      fast: true,
    ),
    (3, 12): Occasion('المولد النبوي', note: 'ذكرى مولد النبي ﷺ.'),
    (7, 1): Occasion('أول شهر رجب', note: 'رجب من الأشهر الحرم.'),
    (7, 27): Occasion('الإسراء والمعراج'),
    (8, 15): Occasion('النصف من شعبان'),
    (9, 1): Occasion('أول رمضان', note: 'رمضان كريم.'),
    (10, 1): Occasion('عيد الفطر', note: 'عيد مبارك.'),
    (12, 9): Occasion(
      'يوم عرفة',
      note: 'صيامه يكفّر السنة اللي فاتت واللي جاية.',
      fast: true,
    ),
    (12, 10): Occasion('عيد الأضحى', note: 'عيد مبارك.'),
  };

  /// Days nobody fasts: Ramadan is fasted anyway, and the Eids and the days
  /// of Tashreeq are forbidden.
  static bool _noVoluntaryFast(HijriDate h) =>
      h.month == 9 ||
      (h.month == 10 && h.day == 1) ||
      (h.month == 12 && h.day >= 10 && h.day <= 13);

  /// The calendar day of [date] (the time is ignored).
  static CalendarDay dayOf(DateTime date, {int offset = 0}) {
    final d = DateTime(date.year, date.month, date.day);
    final h = HijriDate.of(d, offset: offset);
    final occasions = <Occasion>[
      ?fixed[(h.month, h.day)],
      if (!_noVoluntaryFast(h) && h.day >= 13 && h.day <= 15) whiteDays,
      if (!_noVoluntaryFast(h) &&
          (d.weekday == DateTime.monday || d.weekday == DateTime.thursday))
        weekday,
    ];
    return CalendarDay(date: d, hijri: h, occasions: occasions);
  }

  /// Every day of the Hijri month that [date] falls in.
  static List<CalendarDay> monthOf(DateTime date, {int offset = 0}) {
    final today = dayOf(date, offset: offset);
    if (!today.hijri.isValid) return [today];
    // Built from year/month/day (not a Duration), so DST can't shift it.
    final d = today.date;
    final start = DateTime(d.year, d.month, d.day - (today.hijri.day - 1));
    final days = <CalendarDay>[];
    for (var i = 0; i < 31; i++) {
      final day = dayOf(
        DateTime(start.year, start.month, start.day + i),
        offset: offset,
      );
      if (day.hijri.month != today.hijri.month) {
        if (days.isEmpty) continue;
        break;
      }
      days.add(day);
    }
    return days;
  }

  /// A day in the month before / after the month of [days].
  static DateTime previousMonth(List<CalendarDay> days) {
    final first = days.first.date;
    return DateTime(first.year, first.month, first.day - 1);
  }

  static DateTime nextMonth(List<CalendarDay> days) {
    final last = days.last.date;
    return DateTime(last.year, last.month, last.day + 1);
  }

  /// The next [count] occasions from [today] (included): the named ones,
  /// and the white days once per month. Mondays and Thursdays aren't listed.
  static List<UpcomingOccasion> upcoming(
    DateTime today, {
    int offset = 0,
    int count = 5,
    int horizon = 400,
  }) {
    final from = DateTime(today.year, today.month, today.day);
    final list = <UpcomingOccasion>[];
    for (var i = 0; i < horizon && list.length < count; i++) {
      final day = dayOf(
        DateTime(from.year, from.month, from.day + i),
        offset: offset,
      );
      final named = day.named;
      if (named != null) list.add(UpcomingOccasion(day, named, i));
      if (day.isWhiteDay && (day.hijri.day == 13 || i == 0)) {
        list.add(UpcomingOccasion(day, whiteDays, i));
      }
    }
    return list.take(count).toList();
  }

  /// «النهارده», «بكرة», «بعد يومين», «بعد 5 أيام», «بعد 12 يوم».
  static String daysLeftLabel(int days) {
    if (days <= 0) return 'النهارده';
    if (days == 1) return 'بكرة';
    if (days == 2) return 'بعد يومين';
    if (days <= 10) return 'بعد $days أيام';
    return 'بعد $days يوم';
  }
}
