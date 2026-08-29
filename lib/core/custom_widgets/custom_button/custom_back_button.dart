import 'package:flutter/material.dart';

import 'package:my_guide/core/app/app_colors.dart';

class CustomBackButton extends StatelessWidget {
  const CustomBackButton({super.key, this.color = AppColors.appPrimaryColor});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      icon: Icon(size: 20, Icons.arrow_forward_ios_outlined, color: color),
    );
  }
}
