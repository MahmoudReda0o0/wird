import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/theme/theme_cubit.dart';

/// App-bar button that flips between the light and dark themes.
/// Shows the moon while light is on and the sun while dark is on.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
      onPressed: () => context.read<ThemeCubit>().toggle(
        Theme.of(context).brightness,
      ),
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: context.wird.primary,
        size: 24,
      ),
    );
  }
}
