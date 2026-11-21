import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:my_guide/features/qibla/data/qibla_math.dart';

/// Where the sun is in the sky: [azimuth] in degrees clockwise from north,
/// [altitude] in degrees above the horizon. Low-precision solar formulas,
/// good to well under a degree, which is plenty to face it.
@immutable
class SunPosition {
  const SunPosition(this.azimuth, this.altitude);

  final double azimuth;
  final double altitude;

  bool get isUp => altitude > 0;

  /// The sun seen from ([lat], [lon]) at [time] (any time zone).
  static SunPosition at(double lat, double lon, DateTime time) {
    final s = _solar(lat, lon, time.toUtc());
    return SunPosition(s.azimuth, s.altitude);
  }

  /// The two moments in [year] when the sun is closest to straight above
  /// the Kaaba (late May and mid July), in UTC. At those moments a shadow
  /// anywhere it's day points away from the qibla.
  static List<DateTime> kaabaTransits(int year) {
    const lat = QiblaMath.kaabaLat;
    const lon = QiblaMath.kaabaLon;
    final solstice = DateTime.utc(year, 6, 21);
    final best = <int, (double, DateTime)>{};
    for (var day = DateTime.utc(year, 4, 1);
        day.isBefore(DateTime.utc(year, 10, 1));
        day = day.add(const Duration(days: 1))) {
      // Solar noon at the Kaaba: start from the clock estimate and correct
      // by the hour angle until it's ~0.
      var t = day.add(Duration(seconds: ((12 - lon / 15) * 3600).round()));
      for (var i = 0; i < 3; i++) {
        final h = _solar(lat, lon, t).hourAngle;
        t = t.subtract(Duration(seconds: (h / 15 * 3600).round()));
      }
      final zenith = 90 - _solar(lat, lon, t).altitude;
      final half = day.isBefore(solstice) ? 0 : 1;
      final current = best[half];
      if (current == null || zenith < current.$1) best[half] = (zenith, t);
    }
    return [best[0]!.$2, best[1]!.$2];
  }

  static ({double azimuth, double altitude, double hourAngle}) _solar(
    double lat,
    double lon,
    DateTime utc,
  ) {
    final d =
        utc.difference(DateTime.utc(2000, 1, 1, 12)).inMicroseconds /
        Duration.microsecondsPerDay;
    final g = _rad((357.529 + 0.98560028 * d) % 360);
    final q = (280.459 + 0.98564736 * d) % 360;
    final l = _rad((q + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g)) % 360);
    final e = _rad(23.439 - 0.00000036 * d);
    final ra = math.atan2(math.cos(e) * math.sin(l), math.cos(l));
    final dec = math.asin(math.sin(e) * math.sin(l));
    final gmst = (18.697374558 + 24.06570982441908 * d) % 24;
    final h = _rad((gmst * 15 + lon) % 360) - ra;
    final la = _rad(lat);
    final alt = math.asin(
      math.sin(la) * math.sin(dec) + math.cos(la) * math.cos(dec) * math.cos(h),
    );
    final az = math.atan2(
      -math.sin(h),
      math.tan(dec) * math.cos(la) - math.sin(la) * math.cos(h),
    );
    return (
      azimuth: QiblaMath.normalize(_deg(az)),
      altitude: _deg(alt),
      hourAngle: QiblaMath.signedDelta(0, _deg(h)),
    );
  }

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;
}
