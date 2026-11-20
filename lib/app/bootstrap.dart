import 'package:flutter/material.dart';
import 'package:my_guide/app/app.dart';
import 'package:my_guide/core/theme/theme_cubit.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';
import 'package:my_guide/features/adhan/adhan_service.dart';
import 'package:my_guide/features/adhan/cubit/adhan_cubit.dart';
import 'package:my_guide/features/prayer_times/cubit/city_cubit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Starts the app: reads what's saved, creates the app-wide Cubits, runs
/// [MyApp], then schedules the adhans.
///
/// A new app-wide feature creates its Cubit here and passes it to [MyApp].
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final package = await PackageInfo.fromPlatform();

  // App-wide state, read from preferences once. Screens get these through
  // the MultiBlocProvider in MyApp.
  final theme = ThemeCubit(prefs);
  final city = CityCubit(prefs);
  final adhan = AdhanCubit(
    prefs,
    requestPermission: AdhanService.requestPermission,
  );
  final appVersion = AppVersionCubit(
    prefs,
    version: package.version,
    buildNumber: package.buildNumber,
  );

  runApp(
    MyApp(
      prefs: prefs,
      theme: theme,
      city: city,
      adhan: adhan,
      appVersion: appVersion,
    ),
  );

  // Schedules the coming days' adhans (setting up notifications first);
  // never blocks the first frame. After this, MyApp's listeners reschedule
  // on every city or adhan change, and when the app comes back.
  await AdhanService.reschedule(city.state, adhan.state);
}
