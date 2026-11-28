import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:my_guide/core/notifications/notification_ids.dart';
import 'package:my_guide/core/notifications/notification_scheduler.dart';
import 'package:my_guide/core/time/app_clock.dart';
import 'package:my_guide/features/adhan/data/adhan_plan.dart';
import 'package:my_guide/features/adhan/data/adhan_settings.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/prayer_times/data/prayer_timing_data.dart';

/// Schedules the adhan as notifications with the adhan sound, at each
/// enabled prayer time for the next [AdhanPlan.days] days. Uses only the
/// [NotificationIds.adhan] ids, so other features' notifications stay.
///
/// The sounds: a Fajr adhan and one for the other four prayers.
/// - Android: `res/raw/adhan.mp3` and `res/raw/adhan_fajr.mp3` (full
///   length), kept in release builds by `res/raw/keep.xml`.
/// - iOS: `ios/Runner/adhan.caf` and `adhan_fajr.caf`, in the Runner
///   target. iOS plays at most 30 seconds, so these are the first 30
///   seconds with a fade-out.
class AdhanService {
  AdhanService._();

  /// Android fixes a channel's sound (and whether it plays as an alarm)
  /// when it's created. Change these ids if a sound file is ever replaced,
  /// so phones pick up the new sound.
  static const _channelId = 'adhan_v1';
  static const _fajrChannelId = 'adhan_fajr_v1';

  /// The same adhans on the alarm volume ([AdhanSettings.asAlarm]): they
  /// sound when the phone is on silent or vibrate.
  static const _alarmChannelId = 'adhan_alarm_v1';
  static const _fajrAlarmChannelId = 'adhan_fajr_alarm_v1';

  /// The opening takbir only (`adhan_short`, `adhan_fajr_short`: the first
  /// 12 seconds), on the notification or the alarm volume.
  static const _shortChannelId = 'adhan_short_v1';
  static const _fajrShortChannelId = 'adhan_fajr_short_v1';
  static const _alarmShortChannelId = 'adhan_alarm_short_v1';
  static const _fajrAlarmShortChannelId = 'adhan_fajr_alarm_short_v1';

  /// Asks for notification permission (and exact alarms on Android).
  /// Waits for the notifications setup, so it works right after launch.
  static Future<bool> requestPermission() =>
      NotificationScheduler.requestPermission();

  static bool _busy = false;
  static (PrayerCity, AdhanSettings)? _pending;

  /// Whether the last schedule used exact alarms; null before the first.
  static bool? _scheduledExact;

  /// Cancels the scheduled adhans and schedules them again from now for
  /// [city] and [settings]. Called on app start and whenever the city or
  /// adhan cubit changes. Calls that arrive while one is running are
  /// folded into one more run with the latest values.
  static Future<void> reschedule(PrayerCity city, AdhanSettings settings) async {
    _pending = (city, settings);
    if (_busy) return;
    _busy = true;
    try {
      while (_pending != null) {
        final (c, s) = _pending!;
        _pending = null;
        await _scheduleAll(c, s);
      }
    } catch (e) {
      debugPrint('Adhan: scheduling failed: $e');
    } finally {
      _busy = false;
    }
  }

  /// Call when the app comes back to the foreground. If exact alarms were
  /// allowed or taken away since the last schedule (the user went to the
  /// Android settings screen), schedules again so the adhan is on time.
  static Future<void> onResume(PrayerCity city, AdhanSettings settings) async {
    if (!settings.appNotifications ||
        (!settings.enabled && !settings.early) ||
        _scheduledExact == null) {
      return;
    }
    final exact = await NotificationScheduler.canScheduleExact();
    if (exact != _scheduledExact) await reschedule(city, settings);
  }

  static Future<void> _scheduleAll(
    PrayerCity city,
    AdhanSettings settings,
  ) async {
    await NotificationScheduler.cancelRanges(const [
      NotificationIds.adhan,
      NotificationIds.legacyAdhan,
      NotificationIds.preAdhan,
    ]);
    if (!settings.appNotifications ||
        (!settings.enabled && !settings.early)) {
      _scheduledExact = null;
      return;
    }

    final now = AppClock.now();
    final alerts = AdhanPlan.plan(city, now, settings);
    final exact = await NotificationScheduler.canScheduleExact();
    _scheduledExact = exact;

    final minutes = settings.earlyMinutes;
    final unit = minutes > 10 ? 'دقيقة' : 'دقايق';
    for (final alert in AdhanPlan.planEarly(city, now, settings)) {
      final p = alert.prayer;
      await NotificationScheduler.schedule(
        id: NotificationIds.preAdhan.id(alert.id),
        title: 'باقي $minutes $unit على أذان ${p.name}',
        body: '${city.name} · ${PrayerTimingData.format(p.time)}',
        at: p.time.subtract(Duration(minutes: minutes)),
        details: _earlyDetails,
        exact: exact,
      );
    }

    for (final alert in alerts) {
      final p = alert.prayer;
      await NotificationScheduler.schedule(
        id: NotificationIds.adhan.id(alert.id),
        title: 'حان الآن موعد أذان ${p.name}',
        body: '${city.name} · ${PrayerTimingData.format(p.time)}',
        at: p.time,
        details: detailsFor(
          fajr: p.key == 'fajr',
          asAlarm: settings.asAlarm,
          short: settings.soundOf(p.key) == AdhanSound.short,
        ),
        exact: exact,
      );
    }
  }

  /// The notification for one adhan: the Fajr or the regular sound, whole
  /// or the opening takbir only, on the notification volume or (Android)
  /// the alarm volume.
  @visibleForTesting
  static NotificationDetails detailsFor({
    required bool fajr,
    required bool asAlarm,
    bool short = false,
  }) {
    if (short) {
      if (asAlarm) return fajr ? _fajrAlarmShortDetails : _alarmShortDetails;
      return fajr ? _fajrShortDetails : _shortDetails;
    }
    if (asAlarm) return fajr ? _fajrAlarmDetails : _alarmDetails;
    return fajr ? _fajrDetails : _details;
  }

  /// The reminder before a prayer: the phone's normal notification sound.
  static const _earlyDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'adhan_early_v1',
      'تنبيه قبل الأذان',
      channelDescription: 'إشعار قبل كل صلاة بـ 5 أو 10 أو 15 دقيقة',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
    ),
  );

  // The short adhans: Android only for now (iOS is on hold), so iOS keeps
  // the regular sound.
  static const _shortDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _shortChannelId,
      'الأذان (أول مقطع)',
      channelDescription: 'أول مقطع من الأذان: الله أكبر، الله أكبر',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan_short'),
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
      sound: 'adhan.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  static const _fajrShortDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _fajrShortChannelId,
      'أذان الفجر (أول مقطع)',
      channelDescription: 'أول مقطع من أذان الفجر',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan_fajr_short'),
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
      sound: 'adhan_fajr.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  static const _alarmShortDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _alarmShortChannelId,
      'الأذان (أول مقطع، صوت المنبّه)',
      channelDescription: 'أول مقطع من الأذان بصوت المنبّه، بيأذّن والموبايل صامت',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan_short'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
      sound: 'adhan.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  static const _fajrAlarmShortDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _fajrAlarmShortChannelId,
      'أذان الفجر (أول مقطع، صوت المنبّه)',
      channelDescription:
          'أول مقطع من أذان الفجر بصوت المنبّه، بيأذّن والموبايل صامت',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan_fajr_short'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
      sound: 'adhan_fajr.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'الأذان',
      channelDescription: 'صوت الأذان للظهر والعصر والمغرب والعشاء',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan'),
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
      sound: 'adhan.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  static const _fajrDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _fajrChannelId,
      'أذان الفجر',
      channelDescription: 'صوت أذان الفجر',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan_fajr'),
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
      sound: 'adhan_fajr.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  static const _alarmDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _alarmChannelId,
      'الأذان (صوت المنبّه)',
      channelDescription: 'الأذان بصوت المنبّه، بيأذّن والموبايل صامت',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
    ),
    // iOS can't play past silent without Apple's critical-alerts
    // entitlement, so it's the normal adhan there.
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
      sound: 'adhan.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  static const _fajrAlarmDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _fajrAlarmChannelId,
      'أذان الفجر (صوت المنبّه)',
      channelDescription: 'أذان الفجر بصوت المنبّه، بيأذّن والموبايل صامت',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan_fajr'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
      sound: 'adhan_fajr.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );
}
