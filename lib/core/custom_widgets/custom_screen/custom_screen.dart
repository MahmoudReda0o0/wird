import 'package:flutter/material.dart';

import 'package:my_guide/core/custom_widgets/custom_appbar/custom_appbar.dart';

/// Base page: app bar, padded body, and tap-outside to dismiss the keyboard.
class CustomScreen extends StatelessWidget {
  const CustomScreen({
    super.key,
    this.appBarTitle,
    required this.body,
    this.screenPadding,
    this.appBar,
    this.floatingActionButton,
  });
  final String? appBarTitle;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final double? screenPadding;
  final Widget? floatingActionButton;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: floatingActionButton == null
              ? null
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: floatingActionButton,
                ),
          floatingActionButtonLocation:
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
