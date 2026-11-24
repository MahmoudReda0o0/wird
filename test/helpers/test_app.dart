import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/app/router/app_router.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/theme/theme_cubit.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';
import 'package:my_guide/features/adhan/cubit/adhan_cubit.dart';
import 'package:my_guide/features/prayer_times/cubit/city_cubit.dart';
import 'package:my_guide/features/seasons/cubit/season_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fresh in-memory preferences for one test.
Future<SharedPreferences> mockPrefs([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

/// The app's Cubits for a widget test, built on [prefs]. Permission
/// requests answer [permissionGranted] instead of asking the platform.
class TestCubits {
  TestCubits(
    this.prefs, {
    bool permissionGranted = true,
    String version = '1.0.0',
    String buildNumber = '1',
  }) : theme = ThemeCubit(prefs),
       city = CityCubit(prefs),
       adhan = AdhanCubit(
         prefs,
         requestPermission: () async => permissionGranted,
       ),
       appVersion = AppVersionCubit(
         prefs,
         version: version,
         buildNumber: buildNumber,
       ),
       season = SeasonCubit(prefs);

  final SharedPreferences prefs;
  final ThemeCubit theme;
  final CityCubit city;
  final AdhanCubit adhan;
  final AppVersionCubit appVersion;
  final SeasonCubit season;
}

/// Wraps [home] (or the app's own routes from [initialRoute]) like the
/// real app: Arabic, right-to-left, the Wird light theme, the app-wide
/// Cubits and [SharedPreferences] provided.
///
/// The app's fonts aren't loaded in tests (only bundled assets the test
/// loads itself would be), so text uses the test font. That's fine for
/// finding and tapping, and its wider glyphs make overflows show early.
Widget testApp(
  TestCubits cubits, {
  Widget? home,
  String? initialRoute,
  RouteFactory? onGenerateRoute,
}) {
  return RepositoryProvider.value(
    value: cubits.prefs,
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubits.theme),
        BlocProvider.value(value: cubits.city),
        BlocProvider.value(value: cubits.adhan),
        BlocProvider.value(value: cubits.appVersion),
        BlocProvider.value(value: cubits.season),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        theme: AppTheme.light,
        home: home,
        initialRoute: home == null && onGenerateRoute == null
            ? initialRoute
            : null,
        routes: home == null && onGenerateRoute == null
            ? AppRouter.routes
            : const {},
        onGenerateRoute: onGenerateRoute,
      ),
    ),
  );
}

/// A tall phone screen, so long lists and screens fit without overflow.
void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
