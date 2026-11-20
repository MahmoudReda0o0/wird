import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_guide/app/router/app_router.dart';
import 'package:my_guide/app/router/app_routes.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/theme/theme_cubit.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';
import 'package:my_guide/features/adhan/adhan_service.dart';
import 'package:my_guide/features/adhan/cubit/adhan_cubit.dart';
import 'package:my_guide/features/adhan/data/adhan_settings.dart';
import 'package:my_guide/features/prayer_times/cubit/city_cubit.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
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
  });

  final SharedPreferences prefs;
  final ThemeCubit theme;
  final CityCubit city;
  final AdhanCubit adhan;
  final AppVersionCubit appVersion;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the Android exact-alarm settings (or anywhere): reschedule
    // if that permission changed, so the adhan is on time.
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          AdhanService.onResume(widget.city.state, widget.adhan.state),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
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
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) => MaterialApp(
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

        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,

        initialRoute: AppRoutes.home,
        routes: AppRouter.routes,
      ),
    );
  }
}
