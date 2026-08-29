import 'package:flutter/material.dart';
import 'package:my_guide/core/custom_widgets/custom_appbar/custom_appbar.dart';
import 'package:my_guide/core/custom_widgets/custom_container/custom_container.dart';
import 'package:my_guide/core/custom_widgets/custom_screen/custom_screen.dart';
import 'package:my_guide/core/custom_widgets/custom_text/custom_text.dart';
import 'package:my_guide/feature/model/azkar_model.dart';
import 'package:my_guide/feature/model/azkar_model/morning_azkar.dart';
import 'package:my_guide/feature/screen/azkar/custom_widget/azkar_card.dart';

class AzkarPageArguments {
  final List<AzkarModel> azkarList;
  final String title;
  AzkarPageArguments({required this.azkarList, required this.title});
}

class AzkarPage extends StatelessWidget {
  const AzkarPage({super.key});
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as AzkarPageArguments;
    return CustomScreen(
      appBar: CustomAppBar(title: args.title, centerTitle: true),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: List.generate(args.azkarList.length, (index) {
            return AzkarCard(
              azkarModel: args.azkarList[index],
              index: index + 1,
            );
          }),
        ),
      ),
    );
  }
}
