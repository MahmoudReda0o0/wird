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
      // The padding lives inside the scroll view, so content scrolls to the
      // screen edge instead of being cut off 20px short of it.
      screenPadding: 0,
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
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewPaddingOf(context).bottom,
      ),
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
                        ? _AdhanSoundButton(
                            prayerName: prayers[i].name,
                            sound: adhan.soundOf(prayers[i].key),
                            onSelected: (sound) => context
                                .read<AdhanCubit>()
                                .setSound(prayers[i].key, sound),
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
            subtitle: adhan.enabled ? "تم تشغيل صوت الأذان" : "الأذان صامت",
          ),
          // Android only: iOS can't play past silent mode.
          if (adhan.enabled &&
              defaultTargetPlatform == TargetPlatform.android) ...[
            const SizedBox(height: AppSpace.s3),
            _SettingSwitch(
              on: adhan.asAlarm,
              onChanged: context.read<AdhanCubit>().setAsAlarm,
              icon: Icons.alarm_rounded,
              title: "الأذان في الوضع الصامت",
              subtitle: adhan.asAlarm ? "تشغيل صوت الأذان" : "تم إيقاف الأذان",
            ),
          ],
          const SizedBox(height: AppSpace.s3),
          _EarlyReminderCard(adhan: adhan, onChanged: _setEarly),
        ],
      ),
    );
  }

  Future<void> _setEarly(bool on) async {
    final allowed = await context.read<AdhanCubit>().setEarly(on);
    if (allowed || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'اسمح لوِرْد بالإشعارات من إعدادات الموبايل عشان التنبيه يشتغل.',
        ),
      ),
    );
  }
}

/// The reminder before each prayer: a switch, and under it how many
/// minutes before (5, 10, 15) while it's on.
class _EarlyReminderCard extends StatelessWidget {
  const _EarlyReminderCard({required this.adhan, required this.onChanged});

  final AdhanSettings adhan;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final minutes = adhan.earlyMinutes;
    final unit = minutes > 10 ? 'دقيقة' : 'دقايق';
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: c.cardShadow,
      ),
      child: Material(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SwitchListTile(
              value: adhan.early,
              onChanged: onChanged,
              activeThumbColor: c.onPrimary,
              activeTrackColor: c.primary,
              secondary: Icon(Icons.notifications_paused_rounded,
                  color: c.primary),
              title: Text(
                'تنبيه قبل الأذان',
                style: AppText.heading.copyWith(color: c.ink),
              ),
              subtitle: Text(
                adhan.early
                    ? 'إشعار قبل كل صلاة بـ $minutes $unit'
                    : 'إشعار قبل الصلاة عشان تلحق تتوضّى',
                style: AppText.body.copyWith(color: c.inkMuted),
              ),
            ),
            if (adhan.early)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s4,
                  0,
                  AppSpace.s4,
                  AppSpace.s4,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      for (final m in AdhanSettings.earlyChoices)
                        ButtonSegment(
                          value: m,
                          label: Text('$m د'),
                          tooltip: 'قبل الأذان بـ $m ${m > 10 ? 'دقيقة' : 'دقايق'}',
                        ),
                    ],
                    selected: {minutes},
                    onSelectionChanged: (picked) => context
                        .read<AdhanCubit>()
                        .setEarlyMinutes(picked.first),
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? c.onPrimary
                            : c.ink,
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? c.primary
                            : c.surfaceRaised,
                      ),
                      side: WidgetStatePropertyAll(BorderSide(color: c.line)),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
/// One prayer's adhan: full, opening takbir only, or silent.
class _AdhanSoundButton extends StatelessWidget {
  const _AdhanSoundButton({
    required this.prayerName,
    required this.sound,
    required this.onSelected,
  });
  final String prayerName;
  final AdhanSound sound;
  final ValueChanged<AdhanSound> onSelected;

  static const _labels = {
    AdhanSound.full: 'الأذان كامل',
    AdhanSound.short: 'أول مقطع',
    AdhanSound.silent: 'صامت',
  };

  static IconData _icon(AdhanSound s) => switch (s) {
    AdhanSound.full => Icons.volume_up_rounded,
    AdhanSound.short => Icons.volume_down_rounded,
    AdhanSound.silent => Icons.volume_off_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return PopupMenuButton<AdhanSound>(
      tooltip: 'أذان $prayerName: ${_labels[sound]}',
      initialValue: sound,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      color: c.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      itemBuilder: (_) => [
        for (final s in AdhanSound.values)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Icon(
                  _icon(s),
                  size: 20,
                  color: s == AdhanSound.silent ? c.inkMuted : c.primary,
                ),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Text(
                    _labels[s]!,
                    style: AppText.body.copyWith(
                      color: c.ink,
                      fontWeight: s == sound ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                if (s == sound)
                  Icon(Icons.check_rounded, size: 20, color: c.primary),
              ],
            ),
          ),
      ],
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          _icon(sound),
          size: 22,
          color: sound == AdhanSound.silent ? c.inkMuted : c.primary,
        ),
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
