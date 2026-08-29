import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_guide/core/app/app_colors.dart';
import 'package:my_guide/core/app/app_images.dart';
import 'package:my_guide/core/custom_widgets/custom_button/custom_back_button.dart';
import 'package:my_guide/core/custom_widgets/custom_image/custom_image.dart';
import 'package:my_guide/core/custom_widgets/custom_text/custom_text.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.onBackTap,
    this.showBackButton = true,
    this.onHomeTap,
    this.onNotificationTap,
    this.showNotivication = true,
    this.centerTitle = true,
  });

  final String title;
  final VoidCallback? onBackTap;
  final bool showBackButton;
  final VoidCallback? onHomeTap;
  final VoidCallback? onNotificationTap;
  final bool showNotivication;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AppBar(
      centerTitle: centerTitle,
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: AppColors.appPrimaryColor.withValues(alpha: 0.5),

      automaticallyImplyLeading: false,
      title: CustomText(
        text: title,
        fontSize: 17.w,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      actions: [showBackButton ? const CustomBackButton() : SizedBox()],
      // title: Row(
      //   children: [
      //     CustomBackButton(color: primary),
      //     CustomText(
      //       text: title,
      //       fontSize: 17.w,
      //       fontWeight: FontWeight.w700,
      //       color: primary,
      //     ),
      //     8.horizontalSpace,
      //     const Spacer(),

      //     // _buildIconButton(image: AppImages.notifications),
      //     // 4.horizontalSpace,
      //     // (showNotivication)
      //     //     ? _buildIconButton(
      //     //         height: 30,
      //     //         image: AppImages.logo,
      //     //         onTap: () => Get.toNamed(AppRoutes.notifications),
      //     //       )
      //     //     : SizedBox.shrink(),
      //     // 5.horizontalSpace,
      //     // _buildIconButton(
      //     //   image: AppImages.logo,
      //     //   onTap: () => Get.offAllNamed(AppRoutes.home),
      //     // ),
      //   ],
      // ),
    );
  }

  Widget _buildIconButton({
    required String image,
    VoidCallback? onTap,
    double height = 24,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: height.h,
        width: 30.w,
        // padding: const EdgeInsets.all(4),
        child: CustomImage(fit: BoxFit.contain, image: image),
      ),
    );
  }
}
