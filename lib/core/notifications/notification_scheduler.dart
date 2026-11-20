import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:my_guide/core/notifications/notification_ids.dart';

/// The only place that talks to `flutter_local_notifications`. Features
/// schedule through it and cancel only their own [NotificationIdRange].
class NotificationScheduler {
  NotificationScheduler._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static Future<bool>? _initializing;

  /// Sets up the plugin. Safe to call any number of times and from
  /// anywhere: every call waits for the same setup, and a failed setup is
  /// tried again on the next call. True when notifications are available.
  static Future<bool> init() => _initializing ??= _initialize();

  static Future<bool> _initialize() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Permission is asked by the feature that needs it.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
      _initializing = null;
      return false;
    }
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  /// Asks to show notifications and, on Android, for exact alarms so they
  /// are on time. Returns false if notifications were refused.
  ///
  /// The exact-alarm screen on Android returns before the user decides, so
  /// whoever schedules should check [canScheduleExact] again when the app
  /// comes back to the foreground.
  static Future<bool> requestPermission() async {
    if (!await init()) return false;
    final android = _android;
    if (android != null) {
      final allowed = await android.requestNotificationsPermission() ?? false;
      if (!allowed) return false;
      if (!await canScheduleExact()) await android.requestExactAlarmsPermission();
      return true;
    }
    final ios = _ios;
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  /// Whether exact alarms are allowed. Always true off Android.
  static Future<bool> canScheduleExact() async =>
      await _android?.canScheduleExactNotifications() ?? true;

  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime at,
    required NotificationDetails details,
    required bool exact,
  }) async {
    if (!await init()) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: at,
      notificationDetails: details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancels the pending notifications whose ids are in any of [ranges],
  /// leaving every other feature's notifications alone.
  static Future<void> cancelRanges(List<NotificationIdRange> ranges) async {
    if (!await init()) return;
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (ranges.any((r) => r.contains(request.id))) {
        await _plugin.cancel(id: request.id);
      }
    }
  }
}
