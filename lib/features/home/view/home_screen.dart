import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/app/router/app_routes.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/time/hijri_date.dart';
import 'package:my_guide/core/widgets/custom_appbar.dart';
import 'package:my_guide/core/widgets/custom_screen.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';
import 'package:my_guide/features/adhan/data/adhan_settings.dart';
import 'package:my_guide/features/adhan/cubit/adhan_cubit.dart';
import 'package:my_guide/features/about/widgets/version_badge.dart';
import 'package:my_guide/features/calendar/data/hijri_calendar.dart';
import 'package:my_guide/features/prayer_times/cubit/city_cubit.dart';
import 'package:my_guide/features/home/widgets/home_grid_tile.dart';
import 'package:my_guide/features/home/widgets/next_prayer_card.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/prayer_times/widgets/prayer_city_picker.dart';
import 'package:my_guide/features/prayer_times/data/prayer_timing_data.dart';
import 'package:my_guide/features/seasons/cubit/season_cubit.dart';
import 'package:my_guide/features/seasons/widgets/season_widgets.dart';

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
      if (!mounted) return;
      _announceUpdate(context.read<AppVersionCubit>().state);
      _showSeasonNote(context.read<SeasonCubit>().state);
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

  /// «الأيام البيض بعد 5 أيام» for the calendar tile.
  static String _nextOccasion(DateTime now, int offset) {
    final next = HijriCalendarData.upcoming(now, offset: offset, count: 1);
    if (next.isEmpty) return 'المناسبات والصيام';
    final u = next.first;
    return '${u.occasion.name} ${HijriCalendarData.daysLeftLabel(u.daysLeft)}';
  }

  bool _noteOpen = false;

  /// «رمضان كريم», once, on the first day a seasonal theme is on.
  Future<void> _showSeasonNote(SeasonState season) async {
    if (!season.showNote || _noteOpen) return;
    _noteOpen = true;
    final cubit = context.read<SeasonCubit>();
    await showSeasonNote(context, season);
    _noteOpen = false;
    await cubit.markNoteSeen();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AppVersionCubit, AppVersionState>(
          listenWhen: (prev, next) =>
              next.announceUpdate && !prev.announceUpdate,
          listener: (_, version) => _announceUpdate(version),
        ),
        BlocListener<SeasonCubit, SeasonState>(
          listenWhen: (prev, next) => next.showNote && !prev.showNote,
          listener: (_, season) => _showSeasonNote(season),
        ),
      ],
      child: BlocBuilder<SeasonCubit, SeasonState>(
        builder: (context, season) => _buildScreen(season),
      ),
    );
  }

  Widget _buildScreen(SeasonState season) {
    return CustomScreen(
      backdrop: SeasonBackdrop(state: season),
      appBar: CustomAppBar(
        background: SeasonAppBarArt(state: season),
        title: 'وِرْد',
        showBackButton: false,
        // The installed version; «تحديث» when a newer one is on Drive,
        // «جديد» right after updating. Opens «عن التطبيق».
        leadingWidget: const VersionBadge(),
        leadingWidth: 112,
        actions: [
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            icon: Icon(Icons.settings_outlined, color: context.wird.primary),
          ),
        ],
      ),
      body: Builder(
        builder: (context) => _buildBody(
          context,
          context.watch<CityCubit>().state,
          context.watch<AdhanCubit>().state,
          season,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PrayerCity city,
    AdhanSettings adhan,
    SeasonState season,
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
      (
        icon: Icons.explore_outlined,
        title: 'القبلة',
        subtitle: 'اتجاه الكعبة',
        route: AppRoutes.qibla,
      ),
      (
        icon: Icons.calendar_month_outlined,
        title: 'التقويم الهجري',
        subtitle: _nextOccasion(now, season.hijriOffset),
        route: AppRoutes.hijriCalendar,
      ),
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpace.s6),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PrayerTimingData.dateLabel(now),
                    style: AppText.body.copyWith(color: c.inkMuted),
                  ),
                  // Opens the Hijri calendar.
                  InkWell(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.hijriCalendar),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Text(
                      HijriDate.of(now, offset: season.hijriOffset).label,
                      style: AppText.caption.copyWith(
                        color: c.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: c.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s3),
            PrayerCityChip(name: city.name),
          ],
        ),
        if (season.upcoming != null) ...[
          const SizedBox(height: AppSpace.s4),
          SeasonCountdownBanner(state: season),
          const SizedBox(height: AppSpace.s4),
        ] else
          const SizedBox(height: AppSpace.s6),
        NextPrayerCard(
          window: window,
          now: now,
          art: season.image(season.active?.heroImage),
          greeting: season.active?.heroOverline,
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
