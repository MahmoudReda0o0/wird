import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:my_guide/features/qibla/data/heading_source.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:true_compass/true_compass.dart';

/// The phone's compass through `true_compass` (true north from the offline
/// WMM2025 model), and the raw magnetometer through `sensors_plus` for the
/// "iron nearby" check.
class DeviceHeadingSource implements HeadingSource {
  TrueCompass? _compass;
  TrueCompass get _c => _compass ??= TrueCompass();

  @override
  Future<bool> available() async {
    try {
      return await _c.checkAvailability() == CompassAvailability.available;
    } catch (e) {
      debugPrint('Compass unavailable: $e');
      return false;
    }
  }

  @override
  Stream<HeadingReading> readings({required double lat, required double lon}) {
    _c.setLocation(CompassLocation(latitude: lat, longitude: lon));
    return _c.headings.map(
      (h) => HeadingReading(
        heading: h.bestHeading,
        accuracy: _level(h.accuracy),
        needsCalibration: h.needsCalibration,
      ),
    );
  }

  static CompassAccuracyLevel _level(CompassAccuracy a) => switch (a) {
    CompassAccuracy.unreliable => CompassAccuracyLevel.unreliable,
    CompassAccuracy.low => CompassAccuracyLevel.low,
    CompassAccuracy.high => CompassAccuracyLevel.high,
    // Medium, and platforms that don't say: neither alarming nor "high".
    _ => CompassAccuracyLevel.medium,
  };

  @override
  Stream<double> fieldDeviation({required double lat, required double lon}) {
    // iOS's raw magnetometer includes the phone's own uncalibrated bias, so
    // it would cry wolf; there the heading accuracy already drops near iron.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const Stream.empty();
    }
    final expected =
        MagneticDeclination.field(latitude: lat, longitude: lon).totalIntensity /
        1000; // nT → µT
    return magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval)
        .map(
          (e) => (math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z) - expected).abs(),
        );
  }

  @override
  Future<void> dispose() async {
    try {
      await _compass?.dispose();
    } catch (e) {
      debugPrint('Compass dispose failed: $e');
    }
  }
}
