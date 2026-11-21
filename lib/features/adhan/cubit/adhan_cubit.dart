import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_guide/features/adhan/data/adhan_settings.dart';

/// Asks the platform for notification permission; true if granted.
typedef AdhanPermissionRequest = Future<bool> Function();

/// Whether the adhan plays and for which prayers. Saved on every change.
///
/// The adhans themselves are scheduled by a listener at the app root
/// (see `app/app.dart`), so this cubit holds state only.
class AdhanCubit extends Cubit<AdhanSettings> {
  AdhanCubit(this._prefs, {required this._requestPermission})
    : super(readSaved(_prefs));

  final SharedPreferences _prefs;
  final AdhanPermissionRequest _requestPermission;

  static const _enabledKey = 'adhan_enabled';
  static const _prayersKey = 'adhan_prayers';
  static const _asAlarmKey = 'adhan_as_alarm';

  /// The saved settings. Also read by the background task, which has no
  /// cubit.
  static AdhanSettings readSaved(SharedPreferences prefs) {
    final saved = prefs.getStringList(_prayersKey);
    return AdhanSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      prayers: saved == null
          ? AdhanSettings.allPrayers
          : [
              for (final k in AdhanSettings.allPrayers)
                if (saved.contains(k)) k,
            ],
      asAlarm: prefs.getBool(_asAlarmKey) ?? false,
    );
  }

  /// Turns the adhan on (asking for permission first) or off.
  /// Returns false when the user refused notifications; it stays off.
  Future<bool> setEnabled(bool on) async {
    if (on && !await _requestPermission()) return false;
    await _save(state.copyWith(enabled: on));
    return true;
  }

  /// Plays the adhan on the alarm volume (Android), so it sounds on
  /// silent too.
  Future<void> setAsAlarm(bool on) => _save(state.copyWith(asAlarm: on));

  /// Turns one prayer's adhan on or off.
  Future<void> togglePrayer(String prayerKey) =>
      _save(state.toggle(prayerKey));

  Future<void> _save(AdhanSettings value) async {
    emit(value);
    await _prefs.setBool(_enabledKey, value.enabled);
    await _prefs.setStringList(_prayersKey, value.prayers);
    await _prefs.setBool(_asAlarmKey, value.asAlarm);
  }
}
