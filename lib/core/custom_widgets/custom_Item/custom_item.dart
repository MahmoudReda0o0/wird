import 'package:flutter/material.dart';

 import 'package:my_guide/core/app/app_colors.dart';

class CustomItem {
  static Widget customDivider({
    Color? color,
    double? thickness,
    double? horizontalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding ?? 16),
      child: Divider(
        thickness: thickness ?? 1,
        color: color ?? AppColors.appPrimaryColor,
      ),
    );
  }

  // static Widget customLoading({required RxBool loading}) {
  //   return Obx(() {
  //     if (loading.value) {
  //       return Container(
  //         height: double.infinity,
  //         width: double.infinity,
  //         color: AppColors.app9F9F9FText4.withValues(alpha: 0.5),
  //         child: Center(child: CircularProgressIndicator()),
  //       );
  //     } else {
  //       return SizedBox();
  //     }
  //   });
  // }
}
