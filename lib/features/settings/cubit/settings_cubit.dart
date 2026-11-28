import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The reading and counting preferences from Settings.
@immutable
class AppPreferences {
  const AppPreferences({this.zikrScale = 1.0, this.sabhaHaptics = true});

  /// The zikr text sizes: small, normal, large.
  static const zikrScales = [0.85, 1.0, 1.2];

  /// Multiplies the zikr font size (one of [zikrScales]).
  final double zikrScale;

  /// A short vibration with each count, and a stronger one when a zikr is
  /// done (the sabha and the azkar cards).
  final bool sabhaHaptics;

  AppPreferences copyWith({double? zikrScale, bool? sabhaHaptics}) =>
      AppPreferences(
        zikrScale: zikrScale ?? this.zikrScale,
        sabhaHaptics: sabhaHaptics ?? this.sabhaHaptics,
      );
}

/// [AppPreferences], saved on every change.
class SettingsCubit extends Cubit<AppPreferences> {
  SettingsCubit(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;
  static const _zikrScaleKey = 'zikr_scale';
  static const _hapticsKey = 'sabha_haptics';

  static AppPreferences _read(SharedPreferences prefs) {
    final scale = prefs.getDouble(_zikrScaleKey);
    return AppPreferences(
      zikrScale: AppPreferences.zikrScales.contains(scale) ? scale! : 1.0,
      sabhaHaptics: prefs.getBool(_hapticsKey) ?? true,
    );
  }

  Future<void> setZikrScale(double scale) async {
    if (!AppPreferences.zikrScales.contains(scale)) return;
    emit(state.copyWith(zikrScale: scale));
    await _prefs.setDouble(_zikrScaleKey, scale);
  }

  Future<void> setSabhaHaptics(bool on) async {
    emit(state.copyWith(sabhaHaptics: on));
    await _prefs.setBool(_hapticsKey, on);
  }
}
