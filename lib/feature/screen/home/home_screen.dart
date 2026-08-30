import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_guide/core/app/app_route.dart';
import 'package:my_guide/core/custom_widgets/custom_appbar/custom_appbar.dart';
import 'package:my_guide/core/custom_widgets/custom_button/custom_button.dart';
import 'package:my_guide/core/custom_widgets/custom_container/custom_container.dart';
import 'package:my_guide/core/custom_widgets/custom_screen/custom_screen.dart';
import 'package:my_guide/core/custom_widgets/custom_text/custom_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScreen(
      appBar: CustomAppBar(title: 'الصفحة الرئيسية', showBackButton: false),
      body: Column(
        children: [
          CustomButton(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.allAzkar);
            },
            text: 'الأذكار',
          ),
          16.verticalSpace,
          CustomButton(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.prayTiming);
            },
            text: 'مواقيت الصلاة',
          ),
          16.verticalSpace,
        ],
      ),
    );
  }
}
