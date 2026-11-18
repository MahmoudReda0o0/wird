import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/feature/screen/prayer_timing/prayer_timing_data.dart';

/// Home's hero: a live countdown to the next prayer, its adhan time, and a
/// bar showing how much of the wait since the previous prayer has passed.
///
/// Ground `primary`, everything on it `on-primary` (design system:
/// NextPrayerCard).
class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({super.key, required this.window, required this.now});

  final PrayerWindow window;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = c.onPrimary.withValues(alpha: isDark ? 0.80 : 0.86);
    final tint = c.onPrimary.withValues(alpha: isDark ? 0.18 : 0.22);

    final next = window.next;
    final left = next.entry.time.difference(now);
    final hours = left.isNegative ? 0 : left.inHours;
    final minutes = left.isNegative ? 0 : left.inMinutes.remainder(60);
    final previous = window.previous;

    return Semantics(
      container: true,
      label: 'الصلاة القادمة',
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s5),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'الصلاة القادمة',
                  style: AppText.label.copyWith(color: sub),
                ),
                const Spacer(),
                if (next.isTomorrow)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'غدًا',
                      style: AppText.caption.copyWith(
                        color: c.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.s1),
            Text(
              next.entry.name,
              style: AppText.hero.copyWith(color: c.onPrimary),
            ),
            const SizedBox(height: AppSpace.s1),
            // Spoken as a sentence, not as digits every second.
            Semantics(
              label: 'متبقي $hours ساعة و$minutes دقيقة على ${next.entry.name}',
              excludeSemantics: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  PrayerTimingData.countdown(left),
                  textDirection: TextDirection.ltr,
                  style: AppText.countdown.copyWith(color: c.onPrimary),
                ),
              ),
            ),
            Text(
              'متبقي على الأذان · ${PrayerTimingData.format(next.entry.time)}',
              style: AppText.body.copyWith(color: sub),
            ),
            const SizedBox(height: AppSpace.s4),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: window.progressAt(now),
                  minHeight: 6,
                  backgroundColor: tint,
                  color: c.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s2),
            Row(
              children: [
                Text(
                  '${previous.name} ${PrayerTimingData.format(previous.time)}',
                  style: AppText.caption.copyWith(color: sub),
                ),
                const Spacer(),
                Text(
                  '${next.entry.name} ${PrayerTimingData.format(next.entry.time)}',
                  style: AppText.caption.copyWith(color: sub),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
