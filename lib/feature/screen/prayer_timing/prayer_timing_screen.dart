import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/core/custom_widgets/custom_appbar/custom_appbar.dart';
import 'package:my_guide/core/custom_widgets/custom_screen/custom_screen.dart';
import 'package:my_guide/feature/screen/prayer_timing/prayer_city.dart';
import 'package:my_guide/feature/screen/prayer_timing/prayer_timing_data.dart';

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

  Future<void> _pickCity(BuildContext context, PrayerCity current) async {
    final c = context.wird;
    final picked = await showModalBottomSheet<PrayerCity>(
      context: context,
      backgroundColor: c.surfaceRaised,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.builder(
          itemCount: PrayerCity.all.length,
          itemBuilder: (context, i) {
            final city = PrayerCity.all[i];
            final selected = city.id == current.id;
            return ListTile(
              title: Text(
                city.name,
                style: AppText.heading.copyWith(
                  color: selected ? c.primary : c.ink,
                ),
              ),
              trailing: selected
                  ? Icon(Icons.check_rounded, color: c.primary)
                  : null,
              onTap: () => Navigator.pop(context, city),
            );
          },
        ),
      ),
    );
    if (picked != null) await PrayerCityController.select(picked);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScreen(
      appBar: const CustomAppBar(title: 'مواقيت الصلاة'),
      body: ValueListenableBuilder<PrayerCity>(
        valueListenable: PrayerCityController.city,
        builder: (context, city, _) => _buildBody(context, city),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PrayerCity city) {
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
          _CityChip(name: city.name, onTap: () => _pickCity(context, city)),
          const SizedBox(height: AppSpace.s4),
          _NextPrayerHeader(
            name: next.isTomorrow ? '${next.entry.name} (غدًا)' : next.entry.name,
            time: PrayerTimingData.format(next.entry.time),
            remaining: PrayerTimingData.remaining(next.entry.time.difference(now)),
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
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The selected city; tap to choose another.
class _CityChip extends StatelessWidget {
  const _CityChip({required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return Semantics(
      button: true,
      label: 'المدينة: $name، اضغط للتغيير',
      excludeSemantics: true,
      child: Material(
        color: c.surfaceRaised,
        shape: StadiumBorder(side: BorderSide(color: c.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s4,
              vertical: AppSpace.s2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: c.primary),
                const SizedBox(width: AppSpace.s1),
                Text(name, style: AppText.label.copyWith(color: c.ink)),
                const SizedBox(width: AppSpace.s1),
                Icon(Icons.expand_more_rounded, size: 18, color: c.inkMuted),
              ],
            ),
          ),
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
  });
  final String name;
  final String time;
  final bool isNext;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final color = isNext ? c.primary : (isPast ? c.inkMuted : c.ink);
    final weight = isPast && !isNext ? FontWeight.w500 : FontWeight.w600;
    final parts = time.split(' ');

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
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
        ],
      ),
    );
  }
}
