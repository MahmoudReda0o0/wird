import 'package:flutter/material.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/features/prayer_times/data/prayer_timing_data.dart';

/// Home's hero: a live countdown to the next prayer, its adhan time, and a
/// bar showing how much of the wait since the previous prayer has passed.
///
/// Ground `primary`, everything on it `on-primary` (design system:
/// NextPrayerCard).
class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({
    super.key,
    required this.window,
    required this.now,
    required this.adhanOn,
    required this.onAdhanTap,
  });

  final PrayerWindow window;
  final DateTime now;

  /// Shows a bell when the adhan is on, «شغّل الأذان» when it's off.
  /// The switch itself lives on the prayer-times screen; this only opens it.
  final bool adhanOn;
  final VoidCallback onAdhanTap;

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
                _AdhanChip(
                  on: adhanOn,
                  onTap: onAdhanTap,
                  color: c.onPrimary,
                  tint: tint,
                ),
                if (next.isTomorrow) const SizedBox(width: AppSpace.s2),
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

/// The adhan status on the card. Opens the prayer-times screen, where the
/// adhan is switched on and off.
class _AdhanChip extends StatelessWidget {
  const _AdhanChip({
    required this.on,
    required this.onTap,
    required this.color,
    required this.tint,
  });
  final bool on;
  final VoidCallback onTap;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: on ? 'الأذان شغال، اضغط للإعدادات' : 'شغّل الأذان',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: tint,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            // Small chip, full-size tap target.
            constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    on
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    size: 18,
                    color: color,
                  ),
                  if (!on) ...[
                    const SizedBox(width: AppSpace.s1),
                    Text(
                      'شغّل الأذان',
                      style: AppText.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
