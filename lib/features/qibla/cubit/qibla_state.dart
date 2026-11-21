import 'package:flutter/foundation.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/qibla/data/heading_source.dart';
import 'package:my_guide/features/qibla/data/qibla_math.dart';
import 'package:my_guide/features/qibla/data/sun_position.dart';

enum QiblaStatus { loading, live, noSensor }

/// Everything the Qibla screen shows. Angles are degrees from north.
@immutable
class QiblaState {
  const QiblaState({
    required this.status,
    required this.city,
    required this.qibla,
    required this.sun,
    this.heading,
    this.accuracy = CompassAccuracyLevel.high,
    this.needsCalibration = false,
    this.interference = false,
    this.kaabaSunToday,
    this.alignedCount = 0,
  });

  final QiblaStatus status;
  final PrayerCity city;

  /// Direction of the Kaaba from [city].
  final double qibla;

  /// Where the phone points; null until the first reading.
  final double? heading;
  final CompassAccuracyLevel accuracy;
  final bool needsCalibration;

  /// Iron or a magnet near the phone.
  final bool interference;
  final SunPosition sun;

  /// Today's moment (UTC) the sun is over the Kaaba, if today is one.
  final DateTime? kaabaSunToday;

  /// Goes up each time the phone comes into line with the qibla: the screen
  /// gives one haptic tap per change.
  final int alignedCount;

  /// How far to turn: positive = right (clockwise).
  double get delta =>
      heading == null ? 0 : QiblaMath.signedDelta(heading!, qibla);

  bool get unreliable =>
      needsCalibration ||
      interference ||
      accuracy == CompassAccuracyLevel.unreliable;

  bool get aligned =>
      status == QiblaStatus.live &&
      heading != null &&
      !unreliable &&
      QiblaMath.isAligned(delta);

  /// From the sun to the qibla: positive = turn right after facing the sun.
  double get sunDelta => QiblaMath.signedDelta(sun.azimuth, qibla);

  QiblaState copyWith({
    QiblaStatus? status,
    PrayerCity? city,
    double? qibla,
    double? heading,
    CompassAccuracyLevel? accuracy,
    bool? needsCalibration,
    bool? interference,
    SunPosition? sun,
    ValueGetter<DateTime?>? kaabaSunToday,
    int? alignedCount,
  }) => QiblaState(
    status: status ?? this.status,
    city: city ?? this.city,
    qibla: qibla ?? this.qibla,
    heading: heading ?? this.heading,
    accuracy: accuracy ?? this.accuracy,
    needsCalibration: needsCalibration ?? this.needsCalibration,
    interference: interference ?? this.interference,
    sun: sun ?? this.sun,
    kaabaSunToday: kaabaSunToday != null
        ? kaabaSunToday()
        : this.kaabaSunToday,
    alignedCount: alignedCount ?? this.alignedCount,
  );
}
