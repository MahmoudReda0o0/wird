import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/core/custom_widgets/custom_appbar/custom_appbar.dart';
import 'package:my_guide/core/custom_widgets/custom_screen/custom_screen.dart';
import 'package:my_guide/feature/screen/pray_timeing/pray_timing_data.dart';

class PrayTimingScreen extends StatefulWidget {
  const PrayTimingScreen({super.key});

  @override
  State<PrayTimingScreen> createState() => _PrayTimingScreenState();
}

class _Prayer {
  const _Prayer(this.name, this.time, {this.isPrayer = true});
  final String name;
  final DateTime time;

  /// Shurooq is listed but is not a prayer, so it's never "next".
  final bool isPrayer;
}

class _PrayTimingScreenState extends State<PrayTimingScreen> {
  PrayTimingData prayTimingData = PrayTimingData();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    prayTimingData.init();
    // Keep the countdown and the highlighted row current.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _remaining(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')} ساعة';
    }
    return '${d.inMinutes < 1 ? 1 : d.inMinutes} دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final data = prayTimingData;

    if (data.loading) {
      return const CustomScreen(
        appBar: CustomAppBar(title: 'مواقيت الصلاة'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final prayers = [
      _Prayer('الفجر', data.fajrTime!),
      _Prayer('الشروق', data.sunriseTime!, isPrayer: false),
      _Prayer('الظهر', data.dhuhrTime!),
      _Prayer('العصر', data.asrTime!),
      _Prayer('المغرب', data.maghribTime!),
      _Prayer('العشاء', data.ishaTime!),
    ];
    final next = prayers
        .where((p) => p.isPrayer && p.time.isAfter(now))
        .firstOrNull;

    return CustomScreen(
      appBar: const CustomAppBar(title: 'مواقيت الصلاة'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: AppSpace.s4),
            _NextPrayerHeader(
              next: next,
              time: next == null ? null : data.formatPrayerTime(next.time),
              remaining: next == null
                  ? null
                  : _remaining(next.time.difference(now)),
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
                        color: prayers[i] == next || prayers[i - 1] == next
                            ? Colors.transparent
                            : c.line,
                      ),
                    _PrayerRow(
                      name: prayers[i].name,
                      time: data.formatPrayerTime(prayers[i].time),
                      isNext: prayers[i] == next,
                      isPast: !prayers[i].time.isAfter(now),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextPrayerHeader extends StatelessWidget {
  const _NextPrayerHeader({
    required this.next,
    required this.time,
    required this.remaining,
  });
  final _Prayer? next;
  final String? time;
  final String? remaining;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    if (next == null || time == null) {
      return Text(
        'انتهت صلوات اليوم',
        style: AppText.body.copyWith(color: c.inkMuted),
      );
    }
    final parts = time!.split(' '); // "3:21 م"
    return Column(
      children: [
        Text(
          'الصلاة القادمة · ${next!.name}',
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
