import 'package:hijri/hijri_calendar.dart';

/// A Hijri date, from the Umm al-Qura calendar (`hijri` package), moved by
/// [offset] days to follow Egypt's moon-sighting announcements. The offset
/// comes from `app_config.hijri_offset` on Supabase (usually 0).
class HijriDate {
  const HijriDate(this.day, this.month, this.year);

  /// The Hijri date of the calendar day of [date] (its year, month, day;
  /// the time is ignored), moved by [offset] days.
  factory HijriDate.of(DateTime date, {int offset = 0}) {
    final day = DateTime(date.year, date.month, date.day + offset, 12);
    try {
      final h = HijriCalendar.fromDate(day);
      return HijriDate(h.hDay, h.hMonth, h.hYear);
    } catch (_) {
      // Outside the Umm al-Qura table (years 1356–1500): no date.
      return const HijriDate(0, 0, 0);
    }
  }

  final int day;
  final int month;
  final int year;

  bool get isValid => month >= 1 && month <= 12 && day >= 1;

  /// The month names as said in Egypt.
  static const months = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  String get monthName => isValid ? months[month - 1] : '';

  /// «15 جمادى الآخرة 1448 هـ», or '' when there's no date.
  String get label => isValid ? '$day $monthName $year هـ' : '';
}
