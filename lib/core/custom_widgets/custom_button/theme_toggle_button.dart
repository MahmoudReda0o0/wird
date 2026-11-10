import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_theme.dart';

/// App-bar button that flips between the light and dark themes.
/// Shows the moon while light is on and the sun while dark is on.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
      onPressed: () => ThemeController.toggle(context),
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: context.wird.primary,
        size: 24,
      ),
    );
  }
}
