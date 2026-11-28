import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_guide/core/notifications/notification_ids.dart';
import 'package:my_guide/core/notifications/notification_scheduler.dart';
import 'package:my_guide/core/time/app_clock.dart';
import 'package:my_guide/features/adhan/cubit/adhan_cubit.dart';
import 'package:my_guide/features/calendar/data/hijri_calendar.dart';
import 'package:my_guide/features/prayer_times/cubit/city_cubit.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/prayer_times/data/prayer_timing_data.dart';
import 'package:my_guide/features/seasons/data/season_store.dart';
import 'package:my_guide/features/settings/cubit/settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// «بكرة صيام»: a notification half an hour after Isha the night before a
/// recommended fast, for the next [days] days. Two switches
/// ([AppPreferences.fastSpecial]: white days, Arafah, Ashura and Tasu'a;
/// [AppPreferences.fastWeekly]: Mondays and Thursdays), and nothing at all
/// while «إشعارات التطبيق» is off.
class FastingReminders {
  FastingReminders._();

  static const days = 30;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'fasting_v1',
      'تذكير الصيام',
      channelDescription: 'الليلة اللي قبل الصيام المستحب',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// Reschedules from what's saved (the background task and app start).
  static Future<void> rescheduleFrom(SharedPreferences prefs) => reschedule(
    city: CityCubit.readSaved(prefs),
    prefs: SettingsCubit.readSaved(prefs),
    allowed: AdhanCubit.readSaved(prefs).appNotifications,
    offset: SeasonStore.hijriOffset(prefs),
  );

  static Future<void> reschedule({
    required PrayerCity city,
    required AppPreferences prefs,
    required bool allowed,
    required int offset,
  }) async {
    await NotificationScheduler.cancelRanges(const [NotificationIds.fasting]);
    if (!allowed || (!prefs.fastSpecial && !prefs.fastWeekly)) return;

    final now = AppClock.now();
    final exact = await NotificationScheduler.canScheduleExact();
    for (var i = 1; i <= days; i++) {
      final day = HijriCalendarData.dayOf(
        DateTime(now.year, now.month, now.day + i),
        offset: offset,
      );
      final title = _titleFor(day, prefs);
      if (title == null) continue;
      final eve = PrayerTimingData.forDay(
        city,
        DateTime(now.year, now.month, now.day + i - 1),
      );
      final isha = eve.firstWhere((p) => p.key == 'isha');
      final at = isha.time.add(const Duration(minutes: 30));
      if (!at.isAfter(now)) continue;
      await NotificationScheduler.schedule(
        id: NotificationIds.fasting.id(i),
        title: title,
        body: 'بكرة ${day.hijri.label}. نوِّ الصيام ومتنساش السحور.',
        at: at,
        details: _details,
        exact: exact,
      );
    }
  }

  /// «بكرة صيام يوم عرفة», or null when [day] isn't one the user wants.
  static String? _titleFor(CalendarDay day, AppPreferences prefs) {
    final named = day.named;
    if (prefs.fastSpecial && named != null && named.fast) {
      return 'بكرة صيام ${named.name}';
    }
    if (prefs.fastSpecial && day.isWhiteDay) {
      return 'بكرة صيام الأيام البيض';
    }
    if (prefs.fastWeekly && day.isSunnahWeekday) {
      return day.date.weekday == DateTime.monday
          ? 'بكرة صيام الإتنين'
          : 'بكرة صيام الخميس';
    }
    return null;
  }
}
