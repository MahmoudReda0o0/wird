import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/core/custom_widgets/custom_appbar/custom_appbar.dart';
import 'package:my_guide/core/custom_widgets/custom_screen/custom_screen.dart';
import 'package:my_guide/feature/model/azkar_model.dart';
import 'package:my_guide/feature/screen/azkar/custom_widget/azkar_card.dart';

class AzkarPageArguments {
  final List<AzkarModel> azkarList;
  final String title;
  AzkarPageArguments({required this.azkarList, required this.title});
}

class AzkarPageScreen extends StatelessWidget {
  const AzkarPageScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as AzkarPageArguments;
    return CustomScreen(
      appBar: CustomAppBar(title: args.title),
      body: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpace.s6),
        itemCount: args.azkarList.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s3),
        itemBuilder: (context, index) =>
            AzkarCard(azkarModel: args.azkarList[index], index: index + 1),
      ),
    );
  }
}
