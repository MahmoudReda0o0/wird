import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_guide/app/app.dart';
import 'package:my_guide/app/background_refresh.dart';
import 'package:my_guide/core/theme/theme_cubit.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';
import 'package:my_guide/features/about/cubit/update_checker.dart';
import 'package:my_guide/features/about/data/app_info.dart';
import 'package:my_guide/features/about/data/release_source.dart';
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
  _registerFontLicenses();
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
  final updates = UpdateChecker(
    appVersion,
    const HttpReleaseSource(AppInfo.latestReleaseUrl),
  );

  runApp(
    MyApp(
      prefs: prefs,
      theme: theme,
      city: city,
      adhan: adhan,
      appVersion: appVersion,
      updates: updates,
    ),
  );

  // Schedules the coming days' adhans (setting up notifications first);
  // never blocks the first frame. After this, MyApp's listeners reschedule
  // on every city or adhan change, and when the app comes back.
  // Looks for a newer version on the new_version branch (a known one shows
  // offline too); MyApp checks again when the app comes back, and retries
  // while there's no internet.
  // Android also keeps both going while the app is closed (BackgroundRefresh).
  await Future.wait([
    AdhanService.reschedule(city.state, adhan.state),
    updates.check(),
    BackgroundRefresh.register(),
  ]);
}

/// Shows the bundled fonts' licenses (SIL OFL 1.1) on the licenses page.
void _registerFontLicenses() {
  for (final (font, file) in const [
    ('IBM Plex Sans Arabic', 'assets/fonts/OFL-IBMPlexSansArabic.txt'),
    ('Noto Naskh Arabic', 'assets/fonts/OFL-NotoNaskhArabic.txt'),
  ]) {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([font], await rootBundle.loadString(file));
    });
  }
}
