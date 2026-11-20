import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/app/router/app_routes.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/widgets/custom_appbar.dart';
import 'package:my_guide/core/widgets/custom_screen.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';
import 'package:my_guide/features/adhan/data/adhan_settings.dart';
import 'package:my_guide/features/adhan/cubit/adhan_cubit.dart';
import 'package:my_guide/features/about/widgets/version_badge.dart';
import 'package:my_guide/features/prayer_times/cubit/city_cubit.dart';
import 'package:my_guide/features/home/widgets/home_grid_tile.dart';
import 'package:my_guide/features/home/widgets/next_prayer_card.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/prayer_times/widgets/prayer_city_picker.dart';
import 'package:my_guide/features/prayer_times/data/prayer_timing_data.dart';

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
    // so the next prayer and the date move on by themselves. While another
    // screen covers home, ticks are skipped; the next tick after coming
    // back (within a second) brings everything up to date.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (ModalRoute.isCurrentOf(context) ?? true) setState(() {});
    });
    // An update already known from the last check (e.g. offline) is
    // announced as soon as home shows.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _announceUpdate(context.read<AppVersionCubit>().state);
    });
  }

  /// Tells the user once per new version that it's on Drive, with a
  /// shortcut to «عن التطبيق» where the download button is.
  void _announceUpdate(AppVersionState version) {
    final update = version.update;
    if (update == null || !version.announceUpdate) return;
    context.read<AppVersionCubit>().markUpdateAnnounced();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('فيه نسخة جديدة من وِرْد: ${update.version}'),
        duration: const Duration(seconds: 8),
        // A snack bar with an action stays forever by default; this one
        // goes away by itself (the badge keeps showing the update).
        persist: false,
        action: SnackBarAction(
          label: 'التفاصيل',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.appVersion),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppVersionCubit, AppVersionState>(
      listenWhen: (prev, next) => next.announceUpdate && !prev.announceUpdate,
      listener: (_, version) => _announceUpdate(version),
      child: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    return CustomScreen(
      appBar: const CustomAppBar(
        title: 'وِرْد',
        showBackButton: false,
        // The installed version; «تحديث» when a newer one is on Drive,
        // «جديد» right after updating. Opens «عن التطبيق».
        leadingWidget: VersionBadge(),
        leadingWidth: 112,
      ),
      body: Builder(
        builder: (context) => _buildBody(
          context,
          context.watch<CityCubit>().state,
          context.watch<AdhanCubit>().state,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PrayerCity city,
    AdhanSettings adhan,
  ) {
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
          child: Text('الأقسام', style: AppText.heading.copyWith(color: c.ink)),
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
