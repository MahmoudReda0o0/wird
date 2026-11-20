import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_guide/feature/adhan/adhan_settings.dart';

/// Asks the platform for notification permission; true if granted.
typedef AdhanPermissionRequest = Future<bool> Function();

/// Whether the adhan plays and for which prayers. Saved on every change.
///
/// The adhans themselves are scheduled by a listener at the app root
/// (see `main.dart`), so this cubit holds state only.
class AdhanCubit extends Cubit<AdhanSettings> {
  AdhanCubit(this._prefs, {required AdhanPermissionRequest requestPermission})
    : _requestPermission = requestPermission,
      super(_read(_prefs));

  final SharedPreferences _prefs;
  final AdhanPermissionRequest _requestPermission;

  static const _enabledKey = 'adhan_enabled';
  static const _prayersKey = 'adhan_prayers';

  static AdhanSettings _read(SharedPreferences prefs) {
    final saved = prefs.getStringList(_prayersKey);
    return AdhanSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      prayers: saved == null
          ? AdhanSettings.allPrayers
          : [
              for (final k in AdhanSettings.allPrayers)
                if (saved.contains(k)) k,
            ],
    );
  }

  /// Turns the adhan on (asking for permission first) or off.
  /// Returns false when the user refused notifications; it stays off.
  Future<bool> setEnabled(bool on) async {
    if (on && !await _requestPermission()) return false;
    await _save(state.copyWith(enabled: on));
    return true;
  }

  /// Turns one prayer's adhan on or off.
  Future<void> togglePrayer(String prayerKey) =>
      _save(state.toggle(prayerKey));

  Future<void> _save(AdhanSettings value) async {
    emit(value);
    await _prefs.setBool(_enabledKey, value.enabled);
    await _prefs.setStringList(_prayersKey, value.prayers);
  }
}
