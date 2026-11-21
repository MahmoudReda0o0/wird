import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_guide/core/notifications/notification_ids.dart';
import 'package:my_guide/core/notifications/notification_scheduler.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';
import 'package:my_guide/features/about/data/app_info.dart';
import 'package:my_guide/features/about/data/release_info.dart';
import 'package:my_guide/features/about/data/release_source.dart';
import 'package:my_guide/features/adhan/adhan_service.dart';
import 'package:my_guide/features/adhan/cubit/adhan_cubit.dart';
import 'package:my_guide/features/prayer_times/cubit/city_cubit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// Work Android runs while the app is closed (Android only):
///
/// * [adhanTask], once a day: schedules the coming days' adhans again, so
///   they keep going even if the app isn't opened for more than 10 days.
/// * [updateTask], every few hours once there's internet: reads the
///   latest version and, if it's newer, posts «نسخة جديدة من وِرْد».
class BackgroundRefresh {
  BackgroundRefresh._();

  static const adhanTask = 'wird_adhan_refresh';
  static const updateTask = 'wird_update_check';

  /// Registers both tasks. Already-registered tasks keep their schedule.
  static Future<void> register() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final workmanager = Workmanager();
      await workmanager.initialize(backgroundDispatcher);
      await workmanager.registerPeriodicTask(
        adhanTask,
        adhanTask,
        frequency: const Duration(hours: 24),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
      await workmanager.registerPeriodicTask(
        updateTask,
        updateTask,
        frequency: const Duration(hours: 6),
        // Waits for internet, then runs: that's when the phone hears about
        // a new version.
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      debugPrint('Background refresh unavailable: $e');
    }
  }

  /// Runs one task in the background isolate. True when it's done.
  static Future<bool> run(String task) async {
    final prefs = await SharedPreferences.getInstance();
    // The app may have changed settings since this isolate last read them.
    await prefs.reload();
    switch (task) {
      case adhanTask:
        await AdhanService.reschedule(
          CityCubit.readSaved(prefs),
          AdhanCubit.readSaved(prefs),
        );
        return true;
      case updateTask:
        final package = await PackageInfo.fromPlatform();
        return checkForUpdate(
          prefs,
          version: package.version,
          buildNumber: package.buildNumber,
          source: const HttpReleaseSource(AppInfo.latestReleaseUrl),
          notify: showUpdateNotice,
        );
      default:
        return true;
    }
  }

  /// Reads the latest version and calls [notify] once per newer version.
  /// False when it couldn't be read, so Android tries again later.
  @visibleForTesting
  static Future<bool> checkForUpdate(
    SharedPreferences prefs, {
    required String version,
    required String buildNumber,
    required ReleaseSource source,
    required Future<void> Function(ReleaseInfo update) notify,
  }) async {
    final cubit = AppVersionCubit(
      prefs,
      version: version,
      buildNumber: buildNumber,
    );
    try {
      if (!await cubit.checkForUpdate(source)) return false;
      final update = await cubit.takeBackgroundNotice();
      if (update != null) await notify(update);
      return true;
    } finally {
      await cubit.close();
    }
  }

  /// «نسخة جديدة من وِرْد». Tapping it opens the app, where the badge and
  /// «عن التطبيق» have the download button.
  static Future<void> showUpdateNotice(ReleaseInfo update) =>
      NotificationScheduler.show(
        id: NotificationIds.update.id(0),
        title: 'نسخة جديدة من وِرْد',
        body: 'الإصدار ${update.version} نزل. افتح التطبيق عشان تنزّله.',
        details: const NotificationDetails(
          android: AndroidNotificationDetails(
            'updates_v1',
            'تحديثات وِرْد',
            channelDescription: 'بيقولك لما نسخة جديدة من التطبيق تنزل',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
}

/// The background isolate's entry point.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, _) async {
    DartPluginRegistrant.ensureInitialized();
    try {
      return await BackgroundRefresh.run(task);
    } catch (e) {
      debugPrint('Background task $task failed: $e');
      return false;
    }
  });
}
