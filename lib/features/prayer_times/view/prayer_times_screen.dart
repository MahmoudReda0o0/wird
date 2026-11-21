import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/widgets/custom_appbar.dart';
import 'package:my_guide/core/widgets/custom_screen.dart';
import 'package:my_guide/features/adhan/cubit/adhan_cubit.dart';
import 'package:my_guide/features/adhan/data/adhan_settings.dart';
import 'package:my_guide/features/prayer_times/cubit/city_cubit.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/prayer_times/widgets/prayer_city_picker.dart';
import 'package:my_guide/features/prayer_times/data/prayer_timing_data.dart';

class PrayerTimingScreen extends StatefulWidget {
  const PrayerTimingScreen({super.key});

  @override
  State<PrayerTimingScreen> createState() => _PrayerTimingScreenState();
}

class _PrayerTimingScreenState extends State<PrayerTimingScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Times are recalculated on every build, so this keeps the countdown,
    // the highlighted row and the date (after midnight) current.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
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
      appBar: const CustomAppBar(title: 'مواقيت الصلاة'),
      body: Builder(
        builder: (context) => _buildBody(
          context,
          context.watch<CityCubit>().state,
          context.watch<AdhanCubit>().state,
        ),
      ),
    );
  }

  Future<void> _setAdhan(bool on) async {
    final allowed = await context.read<AdhanCubit>().setEnabled(on);
    if (allowed || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'اسمح لوِرْد بالإشعارات من إعدادات الموبايل عشان الأذان يشتغل.',
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
    final prayers = PrayerTimingData.forDay(city, now);
    final next = PrayerTimingData.next(city, now);
    final nextIndex = next.isTomorrow
        ? -1
        : prayers.indexWhere((p) => p.name == next.entry.name);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          PrayerCityChip(name: city.name),
          const SizedBox(height: AppSpace.s4),
          _NextPrayerHeader(
            name: next.isTomorrow
                ? '${next.entry.name} (غدًا)'
                : next.entry.name,
            time: PrayerTimingData.format(next.entry.time),
            remaining: PrayerTimingData.remaining(
              next.entry.time.difference(now),
            ),
          ),
          const SizedBox(height: AppSpace.s5),
          Container(
            padding: const EdgeInsets.all(AppSpace.s2),
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: c.cardShadow,
            ),
            child: Column(
              children: [
                for (var i = 0; i < prayers.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: AppSpace.s3,
                      endIndent: AppSpace.s3,
                      color: i == nextIndex || i - 1 == nextIndex
                          ? Colors.transparent
                          : c.line,
                    ),
                  _PrayerRow(
                    name: prayers[i].name,
                    time: PrayerTimingData.format(prayers[i].time),
                    isNext: i == nextIndex,
                    isPast: !prayers[i].time.isAfter(now),
                    trailing: adhan.enabled && prayers[i].isPrayer
                        ? _AdhanBell(
                            prayerName: prayers[i].name,
                            on: adhan.isOn(prayers[i].key),
                            onTap: () => context
                                .read<AdhanCubit>()
                                .togglePrayer(prayers[i].key),
                          )
                        : (adhan.enabled ? const SizedBox(width: 40) : null),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          _SettingSwitch(
            on: adhan.enabled,
            onChanged: _setAdhan,
            icon: adhan.enabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            title: 'صوت الأذان',
            subtitle: adhan.enabled
                ? 'هيأذّن في وقت كل صلاة عليها الجرس'
                : 'شغّله عشان يأذّن في وقت كل صلاة',
          ),
          // Android only: iOS can't play past silent mode.
          if (adhan.enabled &&
              defaultTargetPlatform == TargetPlatform.android) ...[
            const SizedBox(height: AppSpace.s3),
            _SettingSwitch(
              on: adhan.asAlarm,
              onChanged: context.read<AdhanCubit>().setAsAlarm,
              icon: Icons.alarm_rounded,
              title: 'يأذّن والموبايل صامت',
              subtitle: adhan.asAlarm
                  ? 'الأذان على صوت المنبّه، فبيشتغل حتى في الصامت'
                  : 'شغّله عشان الأذان يطلع على صوت المنبّه',
            ),
          ],
        ],
      ),
    );
  }
}

/// A raised card with a setting's icon, title, subtitle and switch.
class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.on,
    required this.onChanged,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final bool on;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    // The shadow is outside and the color is on a Material, so the tile's
    // ripple shows when it's tapped.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: c.cardShadow,
      ),
      child: Material(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SwitchListTile(
          value: on,
          onChanged: onChanged,
          activeThumbColor: c.onPrimary,
          activeTrackColor: c.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          secondary: Icon(icon, color: c.primary),
          title: Text(title, style: AppText.heading.copyWith(color: c.ink)),
          subtitle: Text(
            subtitle,
            style: AppText.body.copyWith(color: c.inkMuted),
          ),
        ),
      ),
    );
  }
}

/// Per-prayer adhan on/off, shown beside each time while the adhan is on.
class _AdhanBell extends StatelessWidget {
  const _AdhanBell({
    required this.prayerName,
    required this.on,
    required this.onTap,
  });
  final String prayerName;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return IconButton(
      onPressed: onTap,
      tooltip: on ? 'إيقاف أذان $prayerName' : 'تشغيل أذان $prayerName',
      iconSize: 22,
      style: IconButton.styleFrom(fixedSize: const Size(40, 40)),
      icon: Icon(
        on
            ? Icons.notifications_active_rounded
            : Icons.notifications_off_outlined,
        color: on ? c.primary : c.inkMuted,
      ),
    );
  }
}

class _NextPrayerHeader extends StatelessWidget {
  const _NextPrayerHeader({
    required this.name,
    required this.time,
    required this.remaining,
  });
  final String name;
  final String time;
  final String remaining;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final parts = time.split(' '); // "3:21 م"
    return Column(
      children: [
        Text(
          'الصلاة القادمة · $name',
          style: AppText.body.copyWith(color: c.inkMuted),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: parts.first,
                style: AppText.display.copyWith(color: c.primary),
              ),
              if (parts.length > 1)
                TextSpan(
                  text: ' ${parts.last}',
                  style: AppText.body.copyWith(
                    color: c.inkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s1),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s3,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: c.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            'بعد $remaining',
            style: AppText.label.copyWith(color: c.primary),
          ),
        ),
      ],
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.name,
    required this.time,
    required this.isNext,
    required this.isPast,
    this.trailing,
  });
  final String name;
  final String time;
  final bool isNext;
  final bool isPast;

  /// The adhan bell, when the adhan is on.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final color = isNext ? c.primary : (isPast ? c.inkMuted : c.ink);
    final weight = isPast && !isNext ? FontWeight.w500 : FontWeight.w600;
    final parts = time.split(' ');

    return Container(
      height: 52,
      padding: EdgeInsetsDirectional.only(
        start: AppSpace.s3,
        end: trailing == null ? AppSpace.s3 : AppSpace.s1,
      ),
      decoration: BoxDecoration(
        color: isNext ? c.primarySoft : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Text(
            name,
            style: AppText.heading.copyWith(color: color, fontWeight: weight),
          ),
          const Spacer(),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: parts.first,
                  style: AppText.heading.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (parts.length > 1)
                  TextSpan(
                    text: ' ${parts.last}',
                    style: AppText.caption.copyWith(color: c.inkMuted),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.s1),
            trailing!,
          ],
        ],
      ),
    );
  }
}
