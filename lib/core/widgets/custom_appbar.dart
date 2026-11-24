import 'package:flutter/material.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/widgets/theme_toggle_button.dart';

/// Top bar: centered title, back button at the leading (right) edge,
/// theme toggle at the trailing (left) edge.
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
    this.leadingWidget,
    this.leadingWidth,
    this.actions = const [],
    this.background,
  });

  final String title;
  final VoidCallback? onBackTap;
  final bool showBackButton;
  /// Replaces the back button, e.g. the version badge on home.
  final Widget? leadingWidget;

  /// Room for a [leadingWidget] wider than an icon.
  final double? leadingWidth;
  final VoidCallback? onHomeTap;
  final VoidCallback? onNotificationTap;
  final bool showNotivication;
  final bool centerTitle;

  /// Shown before the theme toggle.
  final List<Widget> actions;

  /// Drawn behind the title and buttons (a seasonal strip).
  final Widget? background;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final c = context.wird;

    return AppBar(
      centerTitle: centerTitle,
      backgroundColor: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: c.line)),
      flexibleSpace: background,
      automaticallyImplyLeading: false,
      leadingWidth: leadingWidth,
      leading:
          leadingWidget ??
          (showBackButton
              ? IconButton(
                  tooltip: 'رجوع',
                  onPressed: onBackTap ?? () => Navigator.maybePop(context),
                  // Mirrors in RTL, so it points right (back).
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: c.primary,
                    size: 22,
                  ),
                )
              : null),
      title: Text(title, style: AppText.title.copyWith(color: c.primary)),
      actions: [
        ...actions,
        const ThemeToggleButton(),
        const SizedBox(width: AppSpace.s1),
      ],
    );
  }
}
