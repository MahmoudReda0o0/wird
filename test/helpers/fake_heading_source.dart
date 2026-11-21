import 'dart:async';

import 'package:my_guide/features/qibla/data/heading_source.dart';

/// A compass the test drives: add readings and field values by hand.
class FakeHeadingSource implements HeadingSource {
  FakeHeadingSource({this.isAvailable = true});

  bool isAvailable;
  final readingsCtrl = StreamController<HeadingReading>.broadcast();
  final fieldCtrl = StreamController<double>.broadcast();
  ({double lat, double lon})? lastTarget;
  bool disposed = false;

  void heading(
    double deg, {
    CompassAccuracyLevel accuracy = CompassAccuracyLevel.high,
    bool needsCalibration = false,
  }) => readingsCtrl.add(
    HeadingReading(
      heading: deg,
      accuracy: accuracy,
      needsCalibration: needsCalibration,
    ),
  );

  @override
  Future<bool> available() async => isAvailable;

  @override
  Stream<HeadingReading> readings({required double lat, required double lon}) {
    lastTarget = (lat: lat, lon: lon);
    return readingsCtrl.stream;
  }

  @override
  Stream<double> fieldDeviation({required double lat, required double lon}) =>
      fieldCtrl.stream;

  @override
  Future<void> dispose() async => disposed = true;
}
