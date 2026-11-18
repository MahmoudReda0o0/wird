import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:my_guide/feature/adhan/adhan_plan.dart';
import 'package:my_guide/feature/adhan/adhan_settings.dart';
import 'package:my_guide/feature/screen/prayer_timing/prayer_city.dart';
import 'package:my_guide/feature/screen/prayer_timing/prayer_timing_data.dart';

/// Schedules the adhan as notifications with the adhan sound, at each
/// enabled prayer time for the next [AdhanPlan.days] days.
///
/// The sounds: a Fajr adhan and one for the other four prayers.
/// - Android: `res/raw/adhan.mp3` and `res/raw/adhan_fajr.mp3` (full
///   length), kept in release builds by `res/raw/keep.xml`.
/// - iOS: `ios/Runner/adhan.caf` and `adhan_fajr.caf`, in the Runner
///   target. iOS plays at most 30 seconds, so these are the first 30
///   seconds with a fade-out.
class AdhanService {
  AdhanService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Android fixes a channel's sound when it's created. Change these ids
  /// if a sound file is ever replaced, so phones pick up the new sound.
  static const _channelId = 'adhan_v1';
  static const _fajrChannelId = 'adhan_fajr_v1';

  /// Call once in main() after the settings and city are loaded.
  static Future<void> init() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Permission is asked when the user turns the adhan on.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Adhan: notifications unavailable: $e');
      return;
    }
    AdhanSettingsController.settings.addListener(reschedule);
    PrayerCityController.city.addListener(reschedule);
    await reschedule();
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  /// Asks to show notifications (and, on Android, for exact alarms so the
  /// adhan is on time). Returns false if notifications were refused.
  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    final android = _android;
    if (android != null) {
      final allowed = await android.requestNotificationsPermission() ?? false;
      if (!allowed) return false;
      final exact = await android.canScheduleExactNotifications() ?? false;
      if (!exact) await android.requestExactAlarmsPermission();
      return true;
    }
    final ios = _ios;
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  static bool _busy = false;
  static bool _again = false;

  /// Cancels every scheduled adhan and schedules them again from now.
  static Future<void> reschedule() async {
    if (!_ready) return;
    if (_busy) {
      _again = true;
      return;
    }
    _busy = true;
    try {
      do {
        _again = false;
        await _scheduleAll();
      } while (_again);
    } catch (e) {
      debugPrint('Adhan: scheduling failed: $e');
    } finally {
      _busy = false;
    }
  }

  static Future<void> _scheduleAll() async {
    await _plugin.cancelAll();
    final settings = AdhanSettingsController.settings.value;
    if (!settings.enabled) return;

    final city = PrayerCityController.city.value;
    final alerts = AdhanPlan.plan(city, PrayerTimingData.now(), settings);
    if (alerts.isEmpty) return;

    final exact = await _android?.canScheduleExactNotifications() ?? true;
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (final alert in alerts) {
      final details = alert.prayer.key == 'fajr' ? _fajrDetails : _details;
      await _schedule(alert, city, details, mode);
    }
  }

  static Future<void> _schedule(
    AdhanAlert alert,
    PrayerCity city,
    NotificationDetails details,
    AndroidScheduleMode mode,
  ) {
    final p = alert.prayer;
    return _plugin.zonedSchedule(
      id: alert.id,
      title: 'حان الآن موعد أذان ${p.name}',
      body: '${city.name} · ${PrayerTimingData.format(p.time)}',
      scheduledDate: p.time,
      notificationDetails: details,
      androidScheduleMode: mode,
    );
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
