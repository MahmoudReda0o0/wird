import 'package:flutter/material.dart';
import 'package:my_guide/app/router/app_routes.dart';
import 'package:my_guide/features/about/view/about_screen.dart';
import 'package:my_guide/features/azkar/view/all_azkar_screen.dart';
import 'package:my_guide/features/azkar/view/azkar_page_screen.dart';
import 'package:my_guide/features/home/view/home_screen.dart';
import 'package:my_guide/features/prayer_times/view/prayer_times_screen.dart';
import 'package:my_guide/features/qibla/view/qibla_compare_screen.dart';
import 'package:my_guide/features/qibla/view/qibla_screen.dart';

/// Every screen the app can open by name. A new feature's screen is added
/// here and its name in [AppRoutes].
class AppRouter {
  AppRouter._();

  static final Map<String, WidgetBuilder> routes = {
    AppRoutes.home: (context) => const HomeScreen(),
    AppRoutes.allAzkar: (context) => const AllAzkarScreen(),
    AppRoutes.azkarPage: (context) => const AzkarPageScreen(),
    AppRoutes.prayerTiming: (context) => const PrayerTimingScreen(),
    AppRoutes.appVersion: (context) => const AppVersion(),
    AppRoutes.qibla: (context) => const QiblaScreen(),
    AppRoutes.qiblaCompare: (context) => const QiblaCompareScreen(),
  };
}
