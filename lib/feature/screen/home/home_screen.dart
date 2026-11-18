import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_route.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/core/custom_widgets/custom_appbar/custom_appbar.dart';
import 'package:my_guide/core/custom_widgets/custom_screen/custom_screen.dart';
import 'package:my_guide/feature/adhan/adhan_settings.dart';
import 'package:my_guide/feature/screen/home/widgets/home_grid_tile.dart';
import 'package:my_guide/feature/screen/home/widgets/next_prayer_card.dart';
import 'package:my_guide/feature/screen/prayer_timing/prayer_city.dart';
import 'package:my_guide/feature/screen/prayer_timing/prayer_city_picker.dart';
import 'package:my_guide/feature/screen/prayer_timing/prayer_timing_data.dart';

/// Home: today's date and city, the next prayer with a live countdown,
/// and a two-column grid of sections.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // The countdown shows seconds. Times are recalculated on every build,
    // so the next prayer and the date move on by themselves.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScreen(
      appBar: const CustomAppBar(title: 'وِرْد', showBackButton: false),
      body: ValueListenableBuilder<PrayerCity>(
        valueListenable: PrayerCityController.city,
        builder: (context, city, _) => ValueListenableBuilder<AdhanSettings>(
          valueListenable: AdhanSettingsController.settings,
          builder: (context, adhan, _) => _buildBody(context, city, adhan),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PrayerCity city, AdhanSettings adhan) {
    final c = context.wird;
    final now = PrayerTimingData.now();
    final window = PrayerTimingData.window(city, now);
    final next = window.next;
    final nextLabel =
        '${next.entry.name}${next.isTomorrow ? ' غدًا' : ''} '
        '${PrayerTimingData.format(next.entry.time)}';

    final sections = [
      (
        icon: Icons.schedule_rounded,
        title: 'مواقيت الصلاة',
        subtitle: nextLabel,
        route: AppRoutes.prayerTiming,
      ),
      (
        icon: Icons.auto_stories_outlined,
        title: 'الأذكار',
        subtitle: 'الصباح والمساء والنوم',
        route: AppRoutes.allAzkar,
      ),
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpace.s6),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                PrayerTimingData.dateLabel(now),
                style: AppText.body.copyWith(color: c.inkMuted),
              ),
            ),
            const SizedBox(width: AppSpace.s3),
            PrayerCityChip(name: city.name),
          ],
        ),
        const SizedBox(height: AppSpace.s6),
        NextPrayerCard(
          window: window,
          now: now,
          adhanOn: adhan.enabled,
          onAdhanTap: () =>
              Navigator.pushNamed(context, AppRoutes.prayerTiming),
        ),
        const SizedBox(height: AppSpace.s6),
        Semantics(
          header: true,
          child: Text(
            'الأقسام',
            style: AppText.heading.copyWith(color: c.ink),
          ),
        ),
        const SizedBox(height: AppSpace.s3),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: sections.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpace.s3,
            crossAxisSpacing: AppSpace.s3,
            mainAxisExtent: 156,
          ),
          itemBuilder: (context, i) {
            final s = sections[i];
            return HomeGridTile(
              icon: s.icon,
              title: s.title,
              subtitle: s.subtitle,
              onTap: () => Navigator.pushNamed(context, s.route),
            );
          },
        ),
      ],
    );
  }
}
