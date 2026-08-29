import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_guide/core/app/app_route.dart';
import 'package:my_guide/feature/screen/azkar/all_azkar.dart';
import 'package:my_guide/feature/screen/azkar/azkar_page.dart';
import 'package:my_guide/feature/screen/home/home_screen.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: "MainNavigator");
String siteURL =
    'https://www.islambook.com/?action=Azkar&cat=2&azkar_fontweight=1';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      splitScreenMode: true,
      designSize: const Size(375, 812),
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
        ],
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
        title: 'Flutter Demo',

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
          ),
        ),

        initialRoute: AppRoutes.home,

        routes: {
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.allAzkar: (context) => const AllAzkar(),
          AppRoutes.azkarPage: (context) => const AzkarPage(),
        },
      ),
    );
  }
}
