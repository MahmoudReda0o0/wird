import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_route.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/core/custom_widgets/custom_appbar/custom_appbar.dart';
import 'package:my_guide/core/custom_widgets/custom_button/menu_tile.dart';
import 'package:my_guide/core/custom_widgets/custom_screen/custom_screen.dart';
import 'package:my_guide/feature/model/azkar_model.dart';
import 'package:my_guide/feature/model/azkar_model/awake_azkar.dart';
import 'package:my_guide/feature/model/azkar_model/evening_azkar.dart';
import 'package:my_guide/feature/model/azkar_model/morning_azkar.dart';
import 'package:my_guide/feature/model/azkar_model/sleep_azkar.dart';
import 'package:my_guide/feature/model/azkar_model/tasabih_azkar.dart';
import 'package:my_guide/feature/screen/azkar/azkar_page.dart';

class AllAzkarScreen extends StatelessWidget {
  const AllAzkarScreen({super.key});

  void _open(BuildContext context, String title, List<AzkarModel> list) {
    Navigator.pushNamed(
      context,
      AppRoutes.azkarPage,
      arguments: AzkarPageArguments(title: title, azkarList: list),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = <(IconData, String, String, List<AzkarModel>)>[
      (
        Icons.wb_twilight_rounded,
        'أذكار الصباح',
        'بعد صلاة الفجر',
        MorningAzkar.morningAzkar,
      ),
      (
        Icons.nights_stay_outlined,
        'أذكار المساء',
        'بعد صلاة العصر',
        EveningAzkar.eveningAzkar,
      ),
      (
        Icons.radio_button_checked_rounded,
        'تسابيح',
        'تسبيح وتحميد وتكبير',
        TasabihAzkar.tasabihAzkar,
      ),
      (
        Icons.bedtime_outlined,
        'أذكار النوم',
        'قبل النوم',
        SleepAzkar.sleepAzkar,
      ),
      (
        Icons.light_mode_outlined,
        'أذكار الاستيقاظ',
        'عند الاستيقاظ من النوم',
        WakeUpAzkar.wakeUpAzkar,
      ),
    ];

    return CustomScreen(
      appBar: const CustomAppBar(title: 'الأذكار'),
      body: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s3),
        itemBuilder: (context, i) {
          final (icon, title, subtitle, list) = sections[i];
          return MenuTile(
            icon: icon,
            title: title,
            subtitle: subtitle,
            onTap: () => _open(context, title, list),
          );
        },
      ),
    );
  }
}
