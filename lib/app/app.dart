import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_guide/app/router/app_router.dart';
import 'package:my_guide/app/router/app_routes.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/theme/theme_cubit.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';
import 'package:my_guide/features/about/cubit/update_checker.dart';
import 'package:my_guide/features/adhan/adhan_service.dart';
import 'package:my_guide/features/adhan/cubit/adhan_cubit.dart';
import 'package:my_guide/features/adhan/data/adhan_settings.dart';
import 'package:my_guide/features/prayer_times/cubit/city_cubit.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/seasons/cubit/season_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app root. Provides the app-wide Cubits, and [SharedPreferences] for
/// screens that create their own Cubits (`context.read<SharedPreferences>()`).
class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.prefs,
    required this.theme,
    required this.city,
    required this.adhan,
    required this.appVersion,
    required this.updates,
    required this.season,
  });

  final SharedPreferences prefs;
  final ThemeCubit theme;
  final CityCubit city;
  final AdhanCubit adhan;
  final AppVersionCubit appVersion;

  /// Checks for a new version again when the app comes back.
  final UpdateChecker updates;

  /// Today's seasonal theme (Ramadan, Eid...), refreshed when the app
  /// comes back.
  final SeasonCubit season;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the Android exact-alarm settings (or anywhere): reschedule
    // if that permission changed, so the adhan is on time, and look for a
    // new version (the phone may have internet now).
    _lifecycle = AppLifecycleListener(
      onResume: () {
        unawaited(
          AdhanService.onResume(widget.city.state, widget.adhan.state),
        );
        widget.updates.onResume();
        unawaited(widget.season.refresh());
      },
      onPause: widget.updates.onPause,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    widget.updates.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: widget.prefs,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: widget.theme),
          BlocProvider.value(value: widget.city),
          BlocProvider.value(value: widget.adhan),
          BlocProvider.value(value: widget.appVersion),
          BlocProvider.value(value: widget.season),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<CityCubit, PrayerCity>(
              listener: (_, city) =>
                  AdhanService.reschedule(city, widget.adhan.state),
            ),
            BlocListener<AdhanCubit, AdhanSettings>(
              listener: (_, settings) =>
                  AdhanService.reschedule(widget.city.state, settings),
            ),
          ],
          child: _buildApp(),
        ),
      ),
    );
  }

  Widget _buildApp() {
    return BlocBuilder<SeasonCubit, SeasonState>(
      buildWhen: (a, b) => a.active != b.active,
      builder: (context, season) => BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => _materialApp(themeMode, season),
      ),
    );
  }

  Widget _materialApp(ThemeMode themeMode, SeasonState season) {
    final active = season.active;
    return MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },

        debugShowCheckedModeBanner: false,
        title: 'Wird',

        // A seasonal theme replaces some colors (and the Android
        // navigation bar color) while it's on.
        theme: active == null
            ? AppTheme.light
            : AppTheme.themed(
                Brightness.light,
                colors: active.colorsLight,
                navBar: active.navBarLight,
              ),
        darkTheme: active == null
            ? AppTheme.dark
            : AppTheme.themed(
                Brightness.dark,
                colors: active.colorsDark,
                navBar: active.navBarDark,
              ),
        themeMode: themeMode,

        initialRoute: AppRoutes.home,
        routes: AppRouter.routes,
      );
  }
}
