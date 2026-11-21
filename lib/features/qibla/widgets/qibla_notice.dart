import 'package:flutter/material.dart';
import 'package:my_guide/core/theme/app_theme.dart';

/// A bordered card with an icon, a bold line and a second line: the orange
/// compass warnings and the gold "sun over the Kaaba" day.
class QiblaNotice extends StatelessWidget {
  const QiblaNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.gold = false,
  });

  /// Orange warning text for calibration.
  const QiblaNotice.calibrate({super.key})
    : icon = Icons.all_inclusive_rounded,
      title = 'البوصلة محتاجة معايرة',
      body = 'حرّك الموبايل في الهوا على شكل 8 كذا مرة.',
      gold = false;

  /// Orange warning text for iron or a magnet nearby.
  const QiblaNotice.interference({super.key})
    : icon = Icons.warning_amber_rounded,
      title = 'فيه حديد أو مغناطيس قريب',
      body = 'ابعد عن العربيات والأجهزة، أو شيل الجراب لو فيه مغناطيس.',
      gold = false;

  final IconData icon;
  final String title;
  final String body;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return Semantics(
      liveRegion: !gold,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s4,
          vertical: AppSpace.s3,
        ),
        decoration: BoxDecoration(
          color: gold ? c.goldSoft : c.warningSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: gold ? c.gold : c.warning, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: gold ? c.goldInk : c.onWarning, size: 28),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: gold ? c.ink : c.onWarning,
                    ),
                  ),
                  Text(
                    body,
                    style: AppText.label.copyWith(
                      color: gold ? c.inkMuted : c.onWarning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
