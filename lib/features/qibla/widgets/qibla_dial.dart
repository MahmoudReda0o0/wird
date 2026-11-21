import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/features/qibla/data/qibla_math.dart';

/// The compass dial: it turns with the phone, the pointer on top stays
/// still, and the phone faces the qibla when the Kaaba is under it.
/// Angles are degrees from north.
class QiblaDial extends StatelessWidget {
  const QiblaDial({
    super.key,
    required this.heading,
    required this.qibla,
    required this.aligned,
    required this.dimmed,
    this.sunAzimuth,
    this.showPointer = true,
  });

  /// Where the phone points.
  final double heading;
  final double qibla;
  final bool aligned;

  /// The compass can't be trusted right now.
  final bool dimmed;

  /// Where the sun is, or null at night.
  final double? sunAzimuth;

  /// False for a still, north-up map (no compass): no phone pointer.
  final bool showPointer;

  static const size = Size(300, 316);

  @override
  Widget build(BuildContext context) {
    final delta = QiblaMath.signedDelta(heading, qibla);
    final turn = delta.abs().round();
    final label = !showPointer
        ? 'القبلة ${qibla.round()} درجة من الشمال، ${QiblaMath.compassPoint(qibla)}'
        : aligned
        ? 'الموبايل في اتجاه القبلة'
        : 'القبلة على بعد $turn درجة ${delta > 0 ? 'يمين' : 'شمال'}';
    return Semantics(
      label: label,
      image: true,
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: CustomPaint(
          size: size,
          painter: _DialPainter(
            colors: context.wird,
            heading: heading,
            qibla: qibla,
            aligned: aligned,
            sunAzimuth: sunAzimuth,
            showPointer: showPointer,
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.colors,
    required this.heading,
    required this.qibla,
    required this.aligned,
    required this.sunAzimuth,
    required this.showPointer,
    required this.textDirection,
  });

  final WirdColors colors;
  final double heading;
  final double qibla;
  final bool aligned;
  final double? sunAzimuth;
  final bool showPointer;
  final TextDirection textDirection;

  static const _center = Offset(150, 166);
  static const _ring = 136.0;

  /// The point [r] from the centre in direction [deg] from north, on a dial
  /// turned so the phone's heading is up.
  Offset _at(double deg, double r) {
    final a = (deg - heading) * math.pi / 180;
    return _center + Offset(r * math.sin(a), -r * math.cos(a));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = colors;
    canvas.drawCircle(
      _center,
      _ring,
      Paint()..color = aligned ? c.primarySoft : c.surfaceRaised,
    );
    canvas.drawCircle(
      _center,
      _ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = aligned ? 3 : 2
        ..color = aligned ? c.primary : c.line,
    );

    for (var i = 0; i < 72; i++) {
      final major = i % 6 == 0;
      canvas.drawLine(
        _at(i * 5.0, 134),
        _at(i * 5.0, major ? 120 : 127),
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = major ? 2.5 : 1.5
          ..color = major ? c.inkMuted : c.lineStrong,
      );
    }

    for (final (text, deg) in const [
      ('ش', 0.0),
      ('ق', 90.0),
      ('ج', 180.0),
      ('غ', 270.0),
    ]) {
      final north = deg == 0;
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: AppText.heading.copyWith(
            fontSize: 17,
            fontWeight: north ? FontWeight.w700 : FontWeight.w500,
            color: north ? c.ink : c.inkMuted,
          ),
        ),
        textDirection: textDirection,
      )..layout();
      tp.paint(canvas, _at(deg, 104) - Offset(tp.width / 2, tp.height / 2));
    }

    final sun = sunAzimuth;
    if (sun != null) {
      final p = _at(sun, 82);
      final gold = Paint()
        ..color = c.gold
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(p, 7, gold);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        final d = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(p + d * 10, p + d * 13, gold);
      }
    }

    // The phone's direction: a dashed line straight up.
    if (showPointer) _paintPhoneLine(canvas);
    canvas.drawLine(
      _center,
      _at(qibla, 116),
      Paint()
        ..color = c.primary
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(_center, 7, Paint()..color = c.primary);

    final k = _at(qibla, _ring);
    canvas.drawCircle(
      k,
      19,
      Paint()..color = aligned ? c.primarySoft : c.surfaceRaised,
    );
    canvas.drawCircle(
      k,
      19,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = c.primary,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: k, width: 16, height: 16),
        const Radius.circular(2),
      ),
      Paint()..color = c.kaaba,
    );
    canvas.drawRect(
      Rect.fromLTWH(k.dx - 8, k.dy - 4, 16, 3),
      Paint()..color = c.gold,
    );

    if (!showPointer) return;
    canvas.drawPath(
      Path()
        ..moveTo(140, 0)
        ..lineTo(160, 0)
        ..lineTo(150, 14)
        ..close(),
      Paint()..color = aligned ? c.primary : c.ink,
    );
  }

  void _paintPhoneLine(Canvas canvas) {
    final dash = Paint()
      ..color = colors.lineStrong
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var y = _center.dy; y > 46; y -= 10) {
      canvas.drawLine(Offset(150, y), Offset(150, math.max(46, y - 4)), dash);
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.heading != heading ||
      old.qibla != qibla ||
      old.aligned != aligned ||
      old.sunAzimuth != sunAzimuth ||
      old.showPointer != showPointer ||
      old.colors != colors;
}
