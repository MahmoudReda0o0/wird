import 'package:flutter/material.dart';
import 'package:my_guide/app/router/app_routes.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/widgets/custom_appbar.dart';
import 'package:my_guide/core/widgets/menu_tile.dart';
import 'package:my_guide/core/widgets/custom_screen.dart';
import 'package:my_guide/features/azkar/data/models/azkar_model.dart';
import 'package:my_guide/features/azkar/data/sources/awake_azkar.dart';
import 'package:my_guide/features/azkar/data/sources/evening_azkar.dart';
import 'package:my_guide/features/azkar/data/sources/morning_azkar.dart';
import 'package:my_guide/features/azkar/data/sources/sleep_azkar.dart';
import 'package:my_guide/features/azkar/data/sources/tasabih_azkar.dart';
import 'package:my_guide/features/azkar/view/azkar_page_screen.dart';

class AllAzkarScreen extends StatelessWidget {
  const AllAzkarScreen({super.key});

  void _open(
    BuildContext context,
    String id,
    String title,
    List<AzkarModel> list,
  ) {
    Navigator.pushNamed(
      context,
      AppRoutes.azkarPage,
      arguments: AzkarPageArguments(id: id, title: title, azkarList: list),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = <(String, IconData, String, String, List<AzkarModel>)>[
      (
        'morning',
        Icons.wb_twilight_rounded,
        'أذكار الصباح',
        'بعد صلاة الفجر',
        MorningAzkar.morningAzkar,
      ),
      (
        'evening',
        Icons.nights_stay_outlined,
        'أذكار المساء',
        'بعد صلاة العصر',
        EveningAzkar.eveningAzkar,
      ),
      (
        'tasabih',
        Icons.radio_button_checked_rounded,
        'تسابيح',
        'تسبيح وتحميد وتكبير',
        TasabihAzkar.tasabihAzkar,
      ),
      (
        'sleep',
        Icons.bedtime_outlined,
        'أذكار النوم',
        'قبل النوم',
        SleepAzkar.sleepAzkar,
      ),
      (
        'wake_up',
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
          final (id, icon, title, subtitle, list) = sections[i];
          return MenuTile(
            icon: icon,
            title: title,
            subtitle: subtitle,
            onTap: () => _open(context, id, title, list),
          );
        },
      ),
    );
  }
}
