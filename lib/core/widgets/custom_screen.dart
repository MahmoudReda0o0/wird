import 'package:flutter/material.dart';

import 'package:my_guide/core/widgets/custom_appbar.dart';

/// Base page: app bar, padded body, and tap-outside to dismiss the keyboard.
class CustomScreen extends StatelessWidget {
  const CustomScreen({
    super.key,
    this.appBarTitle,
    required this.body,
    this.screenPadding,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });
  final String? appBarTitle;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final double? screenPadding;
  final Widget? floatingActionButton;

  /// Defaults to a padded button docked at the bottom centre.
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton:
              floatingActionButton == null ||
                  floatingActionButtonLocation != null
              ? floatingActionButton
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: floatingActionButton,
                ),
          floatingActionButtonLocation:
              floatingActionButtonLocation ??
              FloatingActionButtonLocation.centerDocked,
          appBar: appBarTitle != null
              ? CustomAppBar(title: appBarTitle ?? '')
              : appBar,
          body: Padding(
            padding: EdgeInsets.all(screenPadding ?? 20),
            child: body,
          ),
        ),
      ),
    );
  }
}
