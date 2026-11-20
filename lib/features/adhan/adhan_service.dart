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

  /// Android fixes a channel's sound when it's created. Change these ids
  /// if a sound file is ever replaced, so phones pick up the new sound.
  static const _channelId = 'adhan_v1';
  static const _fajrChannelId = 'adhan_fajr_v1';

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
    if (!settings.enabled || _scheduledExact == null) return;
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
    ]);
    if (!settings.enabled) {
      _scheduledExact = null;
      return;
    }

    final alerts = AdhanPlan.plan(city, AppClock.now(), settings);
    final exact = await NotificationScheduler.canScheduleExact();
    _scheduledExact = exact;

    for (final alert in alerts) {
      final p = alert.prayer;
      await NotificationScheduler.schedule(
        id: NotificationIds.adhan.id(alert.id),
        title: 'حان الآن موعد أذان ${p.name}',
        body: '${city.name} · ${PrayerTimingData.format(p.time)}',
        at: p.time,
        details: p.key == 'fajr' ? _fajrDetails : _details,
        exact: exact,
      );
    }
  }

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
}
