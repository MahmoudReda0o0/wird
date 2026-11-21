import 'package:flutter/foundation.dart';

/// How much to trust the compass right now.
enum CompassAccuracyLevel { unreliable, low, medium, high }

/// One compass sample.
@immutable
class HeadingReading {
  const HeadingReading({
    required this.heading,
    required this.accuracy,
    required this.needsCalibration,
  });

  /// Degrees clockwise from north: true north when the source knows the
  /// declination, else magnetic north.
  final double heading;
  final CompassAccuracyLevel accuracy;
  final bool needsCalibration;
}

/// Where the Qibla screen gets the phone's direction from. The device
/// implementation wraps the sensor plugins; tests use a fake.
abstract class HeadingSource {
  /// Whether the phone has a usable compass.
  Future<bool> available();

  /// Compass samples, corrected to true north for ([lat], [lon]).
  Stream<HeadingReading> readings({required double lat, required double lon});

  /// How far the magnetic field around the phone is from what Earth's field
  /// should be at ([lat], [lon]), in µT. Large values mean iron or a magnet
  /// nearby. Empty where the platform can't measure it reliably.
  Stream<double> fieldDeviation({required double lat, required double lon});

  Future<void> dispose();
}
