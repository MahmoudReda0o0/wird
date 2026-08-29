import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_colors.dart';

class CustomContainer extends StatelessWidget {
  CustomContainer({
    super.key,
    required this.child,
    this.color,
    this.borderRadius,
    this.borderColor,
    this.horizontalPadding,
    this.verticalPadding,
    this.usedefaultSahdow = false,
    this.boxShadow,
    this.height,
    this.width,
  });
  Widget child;
  Color? color;
  double? borderRadius;
  Color? borderColor;
  double? horizontalPadding;
  double? verticalPadding;
  bool? usedefaultSahdow;
  BoxShadow? boxShadow;
  double? height;
  double? width;
  @override
  Widget build(BuildContext context) {
    return Container(
      // height: height ?? 32,
      width: width ?? double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? 8,
        vertical: verticalPadding ?? 0,
      ),
      decoration: BoxDecoration(
        color: color ?? AppColors.appPrimaryColor,
        borderRadius: BorderRadius.circular(borderRadius ?? 10),
        border: Border.all(color: borderColor ?? Colors.transparent),
        boxShadow: boxShadow != null
            ? [boxShadow!]
            : usedefaultSahdow == true
            ? [
                BoxShadow(
                  color: AppColors.appPrimaryColor,
                  blurRadius: 4,
                  offset: const Offset(0, 0),
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
