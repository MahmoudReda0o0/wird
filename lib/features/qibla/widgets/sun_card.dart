import 'package:flutter/material.dart';
import 'package:my_guide/core/theme/app_theme.dart';

/// Which way to turn after facing the sun: «لفّ يمين 40°».
String sunTurnText(double sunDelta) =>
    '${sunDelta > 0 ? 'يمين' : 'شمال'} ${sunDelta.abs().round()}°';

/// «القبلة بالشمس»: works on any phone, compass or not. Tapping it explains
/// the method, at night too (with a note that the sun has set).
class SunCard extends StatelessWidget {
  const SunCard({
    super.key,
    required this.sunUp,
    required this.sunDelta,
    required this.onTap,
    this.hasCompass = true,
  });

  final bool sunUp;

  /// Without a compass the night text points to the angle instead.
  final bool hasCompass;

  /// From the sun to the qibla, degrees; positive = turn right.
  final double sunDelta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final body = sunUp
        ? 'اقف ووشّك للشمس، ولفّ ${sunTurnText(sunDelta)}'
        : hasCompass
        ? 'الشمس غابت، استخدم البوصلة'
        : 'الشمس غابت، استخدم الزاوية فوق';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: c.cardShadow,
      ),
      child: Material(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s4,
              vertical: AppSpace.s3,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.goldSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    sunUp ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
                    color: c.goldInk,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'القبلة بالشمس',
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        body,
                        style: AppText.label.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: c.primary,
                    semanticLabel: 'إزاي؟',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
