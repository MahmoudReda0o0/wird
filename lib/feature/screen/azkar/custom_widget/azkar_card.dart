import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_guide/core/app/app_colors.dart';
import 'package:my_guide/core/custom_widgets/custom_container/custom_container.dart';
import 'package:my_guide/core/custom_widgets/custom_text/custom_text.dart';
import 'package:my_guide/feature/model/azkar_model.dart';

class AzkarCard extends StatefulWidget {
  const AzkarCard({super.key, required this.azkarModel, required this.index});
  final AzkarModel azkarModel;
  final int index;
  @override
  State<AzkarCard> createState() => _AzkarCardState();
}

class _AzkarCardState extends State<AzkarCard> {
  bool expanded = false;
  int counter = 0;
  Color cardColor = AppColors.appBlue;
  @override
  void initState() {
    super.initState();
    counter = widget.azkarModel.repetition;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (counter != 0) {
            counter--;
            if (counter == 0) {
              cardColor = AppColors.appGreen;
            }
          }
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                // margin: EdgeInsets.only(right: 10),
                padding: EdgeInsets.symmetric(horizontal: 10),

                height: 40,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                ),
                child: CustomText(
                  text: '$counter مرات تكرار',
                  fontSize: 25,
                  textAlign: TextAlign.center,
                  color: AppColors.appWhite,
                ),
              ),
              Spacer(),
              Container(
                // margin: EdgeInsets.only(right: 10),
                padding: EdgeInsets.symmetric(horizontal: 10),

                height: 20,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                ),
                child: CustomText(
                  text: widget.index.toString(),
                  color: AppColors.appWhite,
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsetsDirectional.only(start: 8, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(5),
                bottomLeft: Radius.circular(expanded ? 0 : 5),
                bottomRight: Radius.circular(expanded ? 0 : 20),
              ),
              border: Border.symmetric(
                horizontal: BorderSide(color: cardColor, width: 4),
                vertical: BorderSide(color: cardColor, width: 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.appPrimaryColor,
                  blurRadius: 4,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                widget.azkarModel.aboveContent != null
                    ? CustomText(
                        text: widget.azkarModel.aboveContent ?? '',
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                        color: AppColors.appGold,
                      )
                    : SizedBox.shrink(),
                CustomText(
                  text: widget.azkarModel.content,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ],
            ),
          ),
          widget.azkarModel.fadl != null
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      expanded = !expanded;
                    });
                    log('expanded: $expanded');
                  },
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axisAlignment: -1,
                            child: child,
                          ),
                        );
                      },
                      child: expanded
                          ? Container(
                              key: const ValueKey('expanded'),
                              width: double.infinity,
                              padding: const EdgeInsets.only(
                                left: 8,
                                right: 8,
                                bottom: 8,
                              ),
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.appPrimaryColor,
                                    blurRadius: 4,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                                color: cardColor,
                                borderRadius:
                                    const BorderRadiusDirectional.only(
                                      bottomStart: Radius.circular(10),
                                      bottomEnd: Radius.circular(10),
                                    ),
                              ),
                              child: CustomText(
                                text: widget.azkarModel.fadl ?? '',
                                color: AppColors.appWhite,
                              ),
                            )
                          : Align(
                              key: const ValueKey('collapsed'),
                              alignment: AlignmentDirectional.bottomEnd,
                              child: Container(
                                margin: const EdgeInsetsDirectional.only(
                                  end: 10,
                                ),
                                width: 25,
                                height: 25,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.appPrimaryColor,
                                      blurRadius: 4,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                  color: cardColor,
                                  borderRadius:
                                      const BorderRadiusDirectional.only(
                                        bottomStart: Radius.circular(10),
                                        bottomEnd: Radius.circular(10),
                                      ),
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_sharp,
                                  color: AppColors.appWhite,
                                  size: 18,
                                ),
                              ),
                            ),
                    ),
                  ),
                )
              : SizedBox.shrink(),
          8.verticalSpace,
        ],
      ),
    );
  }
}
