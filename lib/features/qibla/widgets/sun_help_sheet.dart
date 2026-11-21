import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/features/qibla/widgets/sun_card.dart';

/// Opens [SunHelpSheet] from the bottom.
Future<void> showSunHelp(BuildContext context, double sunDelta) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.wird.surfaceRaised,
      builder: (_) => SunHelpSheet(sunDelta: sunDelta),
    );

/// Step by step: face the sun, turn by the angle, that's the qibla.
class SunHelpSheet extends StatelessWidget {
  const SunHelpSheet({super.key, required this.sunDelta});

  /// From the sun to the qibla; positive = turn right.
  final double sunDelta;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final n = sunDelta.abs().round();
    final side = sunDelta > 0 ? 'يمين' : 'شمال';
    final steps = [
      'اقف في مكان مفتوح ووشّك ناحية الشمس. ما تبصّش عليها مباشرة.',
      'لفّ ناحية $sideك $n°، يعني ${n < 90 ? 'أقل' : 'أكتر'} من ربع لفّة '
          '(ربع اللفّة 90°). الكعبة هتبقى قدامك.',
      'كده إنت في اتجاه القبلة.',
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s5,
          0,
          AppSpace.s5,
          AppSpace.s5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'إزاي تعرف القبلة بالشمس؟',
                style: AppText.title.copyWith(color: c.ink),
              ),
            ),
            const SizedBox(height: AppSpace.s3),
            Container(
              padding: const EdgeInsets.all(AppSpace.s2),
              decoration: BoxDecoration(
                color: c.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Semantics(
                  label:
                      'رسمة: واقف ووشّك للشمس، وبعدين بتلف ${sunTurnText(sunDelta)} ناحية الكعبة',
                  image: true,
                  child: CustomPaint(
                    size: const Size(200, 150),
                    painter: _SunTurnPainter(colors: c, sunDelta: sunDelta),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s4),
            for (var i = 0; i < steps.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppText.label.copyWith(
                        color: c.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: AppText.body.copyWith(color: c.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s3),
            ],
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s3,
                vertical: AppSpace.s3,
              ),
              decoration: BoxDecoration(
                color: c.goldSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'الشمس بتتحرك، فالزاوية بتتغيّر طول اليوم والتطبيق بيحدّثها '
                'لوحده. الطريقة أسهل والشمس واطية، الصبح بدري أو قبل المغرب.',
                style: AppText.label.copyWith(color: c.ink),
              ),
            ),
            const SizedBox(height: AppSpace.s4),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text('تمام', style: AppText.heading),
            ),
          ],
        ),
      ),
    );
  }
}

/// You in the middle, the sun ahead, and the turn to the Kaaba.
class _SunTurnPainter extends CustomPainter {
  _SunTurnPainter({required this.colors, required this.sunDelta});
  final WirdColors colors;
  final double sunDelta;

  @override
  void paint(Canvas canvas, Size size) {
    final c = colors;
    const me = Offset(100, 90);
    Offset at(double deg, double r) {
      final a = deg * math.pi / 180;
      return me + Offset(r * math.sin(a), -r * math.cos(a));
    }

    canvas.drawCircle(
      me,
      50,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = c.line
        ..strokeWidth = 2,
    );
    final gold = Paint()
      ..color = c.gold
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const sun = Offset(100, 22);
    canvas.drawCircle(sun, 10, gold);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(sun + d * 13, sun + d * 17, gold);
    }
    final primary = Paint()
      ..color = c.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final sweep = sunDelta * math.pi / 180;
    canvas.drawArc(
      Rect.fromCircle(center: me, radius: 32),
      -math.pi / 2,
      sweep,
      false,
      primary,
    );
    canvas.drawLine(me, at(sunDelta, 50), primary..strokeWidth = 4);
    final k = at(sunDelta, 62);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: k, width: 18, height: 18),
        const Radius.circular(2),
      ),
      Paint()..color = c.kaaba,
    );
    canvas.drawRect(
      Rect.fromLTWH(k.dx - 9, k.dy - 5, 18, 3),
      Paint()..color = c.gold,
    );
    canvas.drawCircle(me, 9, Paint()..color = c.primary);
  }

  @override
  bool shouldRepaint(_SunTurnPainter old) =>
      old.sunDelta != sunDelta || old.colors != colors;
}
