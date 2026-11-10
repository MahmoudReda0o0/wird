import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_route.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/core/custom_widgets/custom_appbar/custom_appbar.dart';
import 'package:my_guide/core/custom_widgets/custom_button/menu_tile.dart';
import 'package:my_guide/core/custom_widgets/custom_screen/custom_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScreen(
      appBar: const CustomAppBar(title: 'وِرْد', showBackButton: false),
      body: Column(
        children: [
          MenuTile(
            icon: Icons.auto_stories_outlined,
            title: 'الأذكار',
            subtitle: 'الصباح والمساء والنوم والاستيقاظ',
            onTap: () => Navigator.pushNamed(context, AppRoutes.allAzkar),
          ),
          const SizedBox(height: AppSpace.s3),
          MenuTile(
            icon: Icons.schedule_rounded,
            title: 'مواقيت الصلاة',
            subtitle: 'مواقيت اليوم والصلاة القادمة',
            onTap: () => Navigator.pushNamed(context, AppRoutes.prayTiming),
          ),
        ],
      ),
    );
  }
}
