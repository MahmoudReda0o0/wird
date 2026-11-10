import 'package:flutter/material.dart';

/// Legacy colors, kept for older widgets that still reference them.
/// New UI reads its colors from the Wird design system: `context.wird`
/// (see app_theme.dart).
class AppColors {
  static const Color appPrimaryColor = Color.fromARGB(255, 174, 175, 175);
  static const Color appWhite = Colors.white;
  static const Color appBlack = Colors.black;
  static const Color appGreen = Color(0xff18BC9C);
  static const Color appBlue = Color(0xff3498DB);
  static const Color appGold = Color(0xffF39C12);
}
