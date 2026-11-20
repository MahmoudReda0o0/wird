import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_guide/core/app/app_route.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/core/app/cubit/theme_cubit.dart';
import 'package:my_guide/feature/adhan/adhan_service.dart';
import 'package:my_guide/feature/adhan/cubit/adhan_cubit.dart';
import 'package:my_guide/feature/screen/app_version.dart';
import 'package:my_guide/feature/screen/azkar/all_azkar.dart';
import 'package:my_guide/feature/screen/azkar/azkar_page.dart';
import 'package:my_guide/feature/screen/home/home_screen.dart';
import 'package:my_guide/feature/screen/prayer_timing/cubit/city_cubit.dart';
import 'package:my_guide/feature/screen/prayer_timing/prayer_city.dart';
import 'package:my_guide/feature/screen/prayer_timing/prayer_timing_screen.dart';
import 'package:my_guide/feature/adhan/adhan_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: "MainNavigator");
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // App-wide state, read from preferences once. Screens get these through
  // the MultiBlocProvider in MyApp.
  final theme = ThemeCubit(prefs);
  final city = CityCubit(prefs);
  final adhan = AdhanCubit(
    prefs,
    requestPermission: AdhanService.requestPermission,
  );

  runApp(MyApp(theme: theme, city: city, adhan: adhan));

  // Schedules the coming days' adhans; never blocks the first frame. After
  // this, MyApp's listeners reschedule on every city or adhan change.
  await AdhanService.init();
  await AdhanService.reschedule(city.state, adhan.state);
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.theme,
    required this.city,
    required this.adhan,
  });

  final ThemeCubit theme;
  final CityCubit city;
  final AdhanCubit adhan;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: theme),
        BlocProvider.value(value: city),
        BlocProvider.value(value: adhan),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<CityCubit, PrayerCity>(
            listener: (_, city) => AdhanService.reschedule(city, adhan.state),
          ),
          BlocListener<AdhanCubit, AdhanSettings>(
            listener: (_, settings) =>
                AdhanService.reschedule(this.city.state, settings),
          ),
        ],
        child: _buildApp(),
      ),
    );
  }

  Widget _buildApp() {
    return ScreenUtilInit(
      splitScreenMode: true,
      designSize: const Size(375, 812),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
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

        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Wird',

        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,

        initialRoute: AppRoutes.home,

        routes: {
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.allAzkar: (context) => const AllAzkarScreen(),
          AppRoutes.azkarPage: (context) => const AzkarPageScreen(),
          AppRoutes.prayerTiming: (context) => const PrayerTimingScreen(),
          AppRoutes.appVersion: (context) => const AppVersion(),
        },
        ),
      ),
    );
  }
}
