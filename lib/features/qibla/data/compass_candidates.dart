import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:precise_compass/precise_compass.dart' as pc;
import 'package:true_compass/true_compass.dart';

/// One compass package to try side by side on the comparison screen.
/// Every candidate reports degrees from TRUE north: packages that only give
/// magnetic north get the same WMM2025 declination added, so the comparison
/// is about the sensor handling, not the north.
class CompassCandidate {
  const CompassCandidate({
    required this.id,
    required this.name,
    required this.note,
    required this.headings,
  });

  final String id;
  final String name;

  /// One line on how the package gets its heading.
  final String note;

  /// True-north headings for ([lat], [lon]).
  final Stream<double> Function(double lat, double lon) headings;

  /// Degrees to add to a magnetic heading at ([lat], [lon]).
  static double declination(double lat, double lon) =>
      MagneticDeclination.field(latitude: lat, longitude: lon).declination;

  static double _norm(double d) => d % 360;

  static final all = <CompassCandidate>[
    CompassCandidate(
      id: 'true_compass',
      name: 'true_compass',
      note: 'الحالي في التطبيق. شمال حقيقي من موديل WMM2025 وفيه smoothing.',
      headings: (lat, lon) {
        final compass = TrueCompass()
          ..setLocation(CompassLocation(latitude: lat, longitude: lon));
        return compass.headings.map((h) => h.bestHeading);
      },
    ),
    CompassCandidate(
      id: 'flutter_compass',
      name: 'flutter_compass',
      note: 'الأشهر. حساس الـ rotation vector بتاع أندرويد (شمال مغناطيسي).',
      headings: (lat, lon) {
        final d = declination(lat, lon);
        return (FlutterCompass.events ?? const Stream.empty())
            .where((e) => e.heading != null)
            .map((e) => _norm(e.heading! + d));
      },
    ),
    CompassCandidate(
      id: 'precise_compass',
      name: 'precise_compass',
      note: 'دمج الحساسات (fusion)، وبيقدّر غلطه بالدرجات.',
      headings: (lat, lon) {
        final d = declination(lat, lon);
        return pc.PreciseCompass.heading
            .where((r) => r.hasHeading)
            .map(
              (r) =>
                  r.headingTrue ??
                  _norm((r.headingMagnetic ?? r.heading) + d),
            );
      },
    ),
    CompassCandidate(
      id: 'flutter_rotation_sensor',
      name: 'flutter_rotation_sensor',
      note: 'اتجاه الموبايل الكامل من الـ rotation vector، والبوصلة محسوبة منه.',
      headings: (lat, lon) {
        final d = declination(lat, lon);
        RotationSensor.samplingPeriod = const Duration(milliseconds: 66);
        return RotationSensor.orientationStream.map(
          (e) => _norm(e.eulerAngles.azimuth * 180 / math.pi + d),
        );
      },
    ),
  ];
}
