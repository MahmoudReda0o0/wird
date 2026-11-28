import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's theme mode. Follows the device until the user picks light or
/// dark; that choice is saved and restored on the next launch.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;
  static const _prefsKey = 'theme_mode';

  static ThemeMode _read(SharedPreferences prefs) {
    final saved = prefs.getString(_prefsKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  /// Switches away from what is shown right now ([current]; with
  /// [ThemeMode.system] that's the device's brightness) and saves it.
  Future<void> toggle(Brightness current) async {
    final mode = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    emit(mode);
    await _prefs.setString(_prefsKey, mode.name);
  }

  /// Light, dark, or follow the device ([ThemeMode.system]), saved.
  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    await _prefs.setString(_prefsKey, mode.name);
  }
}
