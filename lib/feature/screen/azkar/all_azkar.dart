import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_guide/core/app/app_route.dart';
import 'package:my_guide/core/custom_widgets/custom_appbar/custom_appbar.dart';
import 'package:my_guide/core/custom_widgets/custom_button/custom_button.dart';
import 'package:my_guide/core/custom_widgets/custom_screen/custom_screen.dart';
import 'package:my_guide/feature/model/azkar_model/awake_azkar.dart';
import 'package:my_guide/feature/model/azkar_model/evening_azkar.dart';
import 'package:my_guide/feature/model/azkar_model/morning_azkar.dart';
import 'package:my_guide/feature/model/azkar_model/sleep_azkar.dart';
import 'package:my_guide/feature/model/azkar_model/tasabih_azkar.dart';
import 'package:my_guide/feature/screen/azkar/azkar_page.dart';

class AllAzkarScreen extends StatelessWidget {
  const AllAzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScreen(
      appBar: CustomAppBar(title: 'الأذكار', centerTitle: true),
      body: Column(
        children: [
          CustomButton(
            text: 'أذكار الصباح',
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.azkarPage,
                arguments: AzkarPageArguments(
                  title: 'اذكار الصباح',
                  azkarList: MorningAzkar.morningAzkar,
                ),
              );
            },
          ),
          16.verticalSpace,
          CustomButton(
            text: 'أذكار المساء',
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.azkarPage,
                arguments: AzkarPageArguments(
                  title: 'اذكار المساء',
                  azkarList: EveningAzkar.eveningAzkar,
                ),
              );
            },
          ),
          16.verticalSpace,
          CustomButton(
            text: 'تسابيح',
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.azkarPage,
                arguments: AzkarPageArguments(
                  title: "تسابيح",
                  azkarList: TasabihAzkar.tasabihAzkar,
                ),
              );
            },
          ),
          16.verticalSpace,
          CustomButton(
            text: 'اذكار النوم',
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.azkarPage,
                arguments: AzkarPageArguments(
                  title: "اذكار النوم",
                  azkarList: SleepAzkar.sleepAzkar,
                ),
              );
            },
          ),
          16.verticalSpace,
          CustomButton(
            text: 'أذكار الاستيقاط',
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.azkarPage,
                arguments: AzkarPageArguments(
                  title: 'أذكار الاستيقاط',
                  azkarList: WakeUpAzkar.wakeUpAzkar,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
