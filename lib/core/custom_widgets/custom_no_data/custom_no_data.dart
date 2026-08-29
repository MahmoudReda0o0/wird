import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
 
import 'package:my_guide/core/app/app_colors.dart';
import 'package:my_guide/core/app/app_images.dart';
import 'package:my_guide/core/custom_widgets/custom_image/custom_image.dart';
import 'package:my_guide/core/custom_widgets/custom_text/custom_text.dart';

class CustomNoDataWidget extends StatelessWidget {
  CustomNoDataWidget({super.key, this.height});
  double? height;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: height ?? 100.h),
        CustomImage(image: AppImages.logo),
        CustomText(
          text:'noData',
          color: AppColors.appPrimaryColor,
        ),
        4.verticalSpace,
        // CustomText(
        //   text: context.appWords.noNotificationDescription,
        //   fontSize: 14.w,
        //   fontWeight: FontWeight.w400,
        //   color: AppColors.app6C757DText5,
        // ),
      ],
    );
  }
}
