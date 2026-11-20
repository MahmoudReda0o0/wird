import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A string of prayer beads (sabha): seven beads on an open loop with a
/// tassel. Material has no such icon, so it's drawn.
class SabhaIcon extends StatelessWidget {
  const SabhaIcon({super.key, this.size = 28, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Colors.black;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _SabhaPainter(c)),
      ),
    );
  }
}

class _SabhaPainter extends CustomPainter {
  _SabhaPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24; // drawn on a 24×24 grid
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Beads around an arc from about 7 o'clock, over the top, to 5 o'clock.
    final center = Offset(12 * s, 9.6 * s);
    final radius = 6.6 * s;
    const beads = 7;
    const start = math.pi * 0.80; // 144°, lower left
    const sweep = math.pi * 1.40; // to 396°, lower right
    for (var i = 0; i < beads; i++) {
      final a = start + sweep * i / (beads - 1);
      final p = center + Offset(math.cos(a), math.sin(a)) * radius;
      canvas.drawCircle(p, 1.6 * s, stroke);
    }

    // The two ends meet in a knot, then the tassel.
    final knot = Offset(12 * s, 17.4 * s);
    final leftEnd =
        center + Offset(math.cos(start), math.sin(start)) * radius;
    final rightEnd = center +
        Offset(math.cos(start + sweep), math.sin(start + sweep)) * radius;
    canvas.drawLine(leftEnd + Offset(0.9 * s, 1.2 * s), knot, stroke);
    canvas.drawLine(rightEnd + Offset(-0.9 * s, 1.2 * s), knot, stroke);
    canvas.drawLine(knot, Offset(12 * s, 20.8 * s), stroke);
    canvas.drawLine(
      Offset(10.4 * s, 22 * s),
      Offset(13.6 * s, 22 * s),
      stroke,
    );
  }

  @override
  bool shouldRepaint(_SabhaPainter old) => old.color != color;
}
