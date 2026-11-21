import 'dart:math' as math;

/// The direction of the Kaaba, and angles between directions. All angles
/// are degrees clockwise from north.
class QiblaMath {
  QiblaMath._();

  static const kaabaLat = 21.4225;
  static const kaabaLon = 39.8262;

  /// The phone counts as facing the qibla within this many degrees.
  static const alignedWithin = 3.0;

  /// Great-circle initial bearing from ([lat], [lon]) to the Kaaba, 0–360.
  static double bearingToKaaba(double lat, double lon) {
    final p1 = _rad(lat);
    final p2 = _rad(kaabaLat);
    final dl = _rad(kaabaLon - lon);
    final y = math.sin(dl) * math.cos(p2);
    final x =
        math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
    return normalize(math.atan2(y, x) * 180 / math.pi);
  }

  /// [deg] in 0–360.
  static double normalize(double deg) => deg % 360;

  /// How far to turn from [from] to [to], the short way, in (-180, 180].
  /// Positive is clockwise (turn right), negative is counter-clockwise.
  static double signedDelta(double from, double to) {
    final d = (to - from) % 360;
    return d > 180 ? d - 360 : d;
  }

  static const _points = [
    'شمال',
    'شمال شرق',
    'شرق',
    'جنوب شرق',
    'جنوب',
    'جنوب غرب',
    'غرب',
    'شمال غرب',
  ];

  /// The nearest of the eight directions, in Arabic ("جنوب شرق").
  static String compassPoint(double deg) =>
      _points[((normalize(deg) + 22.5) / 45).floor() % 8];

  static bool isAligned(double delta) => delta.abs() <= alignedWithin;

  static double _rad(double deg) => deg * math.pi / 180;
}
