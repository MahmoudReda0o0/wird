import 'package:flutter/material.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/features/qibla/data/heading_source.dart';

/// Three bars and a word for how much to trust the compass.
class AccuracyBars extends StatelessWidget {
  const AccuracyBars({super.key, required this.level});
  final CompassAccuracyLevel level;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final (bars, text) = switch (level) {
      CompassAccuracyLevel.high => (3, 'دقة عالية'),
      CompassAccuracyLevel.medium => (2, 'دقة متوسطة'),
      _ => (1, 'دقة ضعيفة'),
    };
    final color = bars == 3 ? c.primary : c.warning;
    return Semantics(
      label: 'البوصلة: $text',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              width: 4,
              height: 5.0 + i * 4.5,
              decoration: BoxDecoration(
                color: i < bars ? color : c.line,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 3),
          ],
          const SizedBox(width: 3),
          Text(
            text,
            style: AppText.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
