import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/core/time/app_clock.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/qibla/cubit/qibla_state.dart';
import 'package:my_guide/features/qibla/data/heading_source.dart';
import 'package:my_guide/features/qibla/data/qibla_math.dart';
import 'package:my_guide/features/qibla/data/sun_position.dart';
import 'package:timezone/timezone.dart' as tz;

/// Turns compass readings, the chosen city and the clock into a
/// [QiblaState]. Owns [HeadingSource] and disposes it on [close].
class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit(
    this._source,
    PrayerCity city, {
    DateTime Function()? nowUtc,
    this.startTimeout = const Duration(seconds: 2),
  }) : _now = nowUtc ?? (() => DateTime.now().toUtc()),
       super(_initial(city, (nowUtc ?? DateTime.now)().toUtc()));

  final HeadingSource _source;
  final DateTime Function() _now;

  /// No reading this long after start means the compass isn't working.
  final Duration startTimeout;

  /// Field this far (µT) from Earth's, for [_interferenceAfter], is iron.
  static const _interferenceLimit = 20.0;
  static const _interferenceAfter = Duration(seconds: 1);

  StreamSubscription<HeadingReading>? _readings;
  StreamSubscription<double>? _field;
  Timer? _startTimer;
  Timer? _interferenceTimer;
  bool? _fieldHigh;
  DateTime _sunAt = DateTime.utc(0);

  static QiblaState _initial(PrayerCity city, DateTime now) => QiblaState(
    status: QiblaStatus.loading,
    city: city,
    qibla: QiblaMath.bearingToKaaba(city.latitude, city.longitude),
    sun: SunPosition.at(city.latitude, city.longitude, now),
    kaabaSunToday: _kaabaDay(now),
  );

  Future<void> start() async {
    _sunAt = _now();
    if (!await _source.available()) {
      if (!isClosed) emit(state.copyWith(status: QiblaStatus.noSensor));
      return;
    }
    if (isClosed) return;
    _listen();
    _startTimer = Timer(startTimeout, () {
      if (state.status == QiblaStatus.loading) _stop();
    });
  }

  void setCity(PrayerCity city) {
    if (city.id == state.city.id) return;
    final now = _now();
    _sunAt = now;
    emit(
      state.copyWith(
        city: city,
        qibla: QiblaMath.bearingToKaaba(city.latitude, city.longitude),
        sun: SunPosition.at(city.latitude, city.longitude, now),
      ),
    );
    if (state.status != QiblaStatus.noSensor) _listen();
  }

  void _listen() {
    unawaited(_readings?.cancel());
    unawaited(_field?.cancel());
    final c = state.city;
    _readings = _source
        .readings(lat: c.latitude, lon: c.longitude)
        .listen(_onReading, onError: (Object _) => _stop());
    _field = _source
        .fieldDeviation(lat: c.latitude, lon: c.longitude)
        .listen(_onField, onError: (Object _) {});
  }

  void _onReading(HeadingReading r) {
    if (isClosed) return;
    _startTimer?.cancel();
    final wasAligned = state.aligned;
    var next = state.copyWith(
      status: QiblaStatus.live,
      heading: r.heading,
      accuracy: r.accuracy,
      needsCalibration: r.needsCalibration,
    );
    final now = _now();
    if (now.difference(_sunAt) >= const Duration(minutes: 1)) {
      _sunAt = now;
      next = next.copyWith(
        sun: SunPosition.at(next.city.latitude, next.city.longitude, now),
        kaabaSunToday: () => _kaabaDay(now),
      );
    }
    _emitCounting(next, wasAligned);
  }

  void _onField(double deviation) {
    final high = deviation > _interferenceLimit;
    if (high == _fieldHigh) return;
    _fieldHigh = high;
    _interferenceTimer?.cancel();
    if (high == state.interference) return;
    _interferenceTimer = Timer(_interferenceAfter, () {
      if (isClosed) return;
      _emitCounting(state.copyWith(interference: high), state.aligned);
    });
  }

  void _emitCounting(QiblaState next, bool wasAligned) {
    emit(
      next.aligned && !wasAligned
          ? next.copyWith(alignedCount: next.alignedCount + 1)
          : next,
    );
  }

  void _stop() {
    unawaited(_readings?.cancel());
    unawaited(_field?.cancel());
    _readings = null;
    _field = null;
    if (!isClosed) emit(state.copyWith(status: QiblaStatus.noSensor));
  }

  /// The Kaaba sun moment on [now]'s Cairo date, or null.
  static DateTime? _kaabaDay(DateTime now) {
    final cairo = AppClock.cairo;
    final today = tz.TZDateTime.from(now, cairo);
    for (final t in SunPosition.kaabaTransits(today.year)) {
      final day = tz.TZDateTime.from(t, cairo);
      if (day.year == today.year &&
          day.month == today.month &&
          day.day == today.day) {
        return t;
      }
    }
    return null;
  }

  @override
  Future<void> close() async {
    _startTimer?.cancel();
    _interferenceTimer?.cancel();
    await _readings?.cancel();
    await _field?.cancel();
    await _source.dispose();
    return super.close();
  }
}
