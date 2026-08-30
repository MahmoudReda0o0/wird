import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_colors.dart';
import 'package:my_guide/core/custom_widgets/custom_appbar/custom_appbar.dart';
import 'package:my_guide/core/custom_widgets/custom_screen/custom_screen.dart';
import 'package:my_guide/core/custom_widgets/custom_text/custom_image_text_value.dart';
import 'package:my_guide/feature/screen/pray_timeing/pray_timing_data.dart';

class PrayTimingScreen extends StatefulWidget {
  const PrayTimingScreen({super.key});

  @override
  State<PrayTimingScreen> createState() => _PrayTimingScreenState();
}

class _PrayTimingScreenState extends State<PrayTimingScreen> {
  PrayTimingData prayTimingData = PrayTimingData();
  @override
  void initState() {
    super.initState();
    prayTimingData.init();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScreen(
      appBar: CustomAppBar(title: 'مواقيت الصلاة'),
      body: prayTimingData.loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                CustomTextValueAndImage(
                  text: 'الفجر',
                  textSize: 30,
                  spacing: 30,
                  textColor: AppColors.appGreen,
                  valueColor: AppColors.appGold,
                  valueSize: 25,
                  value: prayTimingData.fajrTimeFormatted,
                ),
                CustomTextValueAndImage(
                  text: 'الشروق',
                  textSize: 30,
                  spacing: 30,
                  textColor: AppColors.appGreen,
                  valueColor: AppColors.appGold,
                  valueSize: 25,
                  value: prayTimingData.sunriseTimeFormatted,
                ),
                CustomTextValueAndImage(
                  text: 'الظهر',
                  textSize: 30,
                  spacing: 30,
                  textColor: AppColors.appGreen,
                  valueColor: AppColors.appGold,
                  valueSize: 25,
                  value: prayTimingData.dhuhrTimeFormatted,
                ),
                CustomTextValueAndImage(
                  text: 'العصر',
                  textSize: 30,
                  spacing: 30,
                  textColor: AppColors.appGreen,
                  valueColor: AppColors.appGold,
                  valueSize: 25,
                  value: prayTimingData.asrTimeFormatted,
                ),
                CustomTextValueAndImage(
                  text: 'المغرب',
                  textSize: 30,
                  spacing: 30,
                  textColor: AppColors.appGreen,
                  valueColor: AppColors.appGold,
                  valueSize: 25,
                  value: prayTimingData.maghribTimeFormatted,
                ),
                CustomTextValueAndImage(
                  text: 'العشاء',
                  textSize: 30,
                  spacing: 30,
                  textColor: AppColors.appGreen,
                  valueColor: AppColors.appGold,
                  valueSize: 25,
                  value: prayTimingData.ishaTimeFormatted,
                ),
              ],
            ),
    );
  }
}
