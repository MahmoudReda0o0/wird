import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: "MainNavigator");

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.theme,
    required this.city,
    required this.adhan,
    required this.appVersion,
  });

  final ThemeCubit theme;
  final CityCubit city;
  final AdhanCubit adhan;
  final AppVersionCubit appVersion;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: theme),
        BlocProvider.value(value: city),
        BlocProvider.value(value: adhan),
        BlocProvider.value(value: appVersion),
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
          routes: AppRouter.routes,
        ),
      ),
    );
  }
}
