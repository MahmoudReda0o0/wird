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
  static const _earlyKey = 'adhan_early';
  static const _earlyMinutesKey = 'adhan_early_minutes';
  static const _appNotificationsKey = 'notifications_on';

  /// Prayers that play only the opening takbir. Older installs don't have
  /// it: everything that's on stays the full adhan.
  static const _shortKey = 'adhan_short_prayers';

  /// The saved settings. Also read by the background task, which has no
  /// cubit.
  static AdhanSettings readSaved(SharedPreferences prefs) {
    final saved = prefs.getStringList(_prayersKey);
    final short = prefs.getStringList(_shortKey) ?? const <String>[];
    return AdhanSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      prayers: saved == null
          ? AdhanSettings.allPrayers
          : [
              for (final k in AdhanSettings.allPrayers)
                if (saved.contains(k)) k,
            ],
      shortPrayers: [
        for (final k in AdhanSettings.allPrayers)
          if (short.contains(k)) k,
      ],
      asAlarm: prefs.getBool(_asAlarmKey) ?? false,
      early: prefs.getBool(_earlyKey) ?? false,
      earlyMinutes: switch (prefs.getInt(_earlyMinutesKey)) {
        final m? when AdhanSettings.earlyChoices.contains(m) => m,
        _ => 10,
      },
      appNotifications: prefs.getBool(_appNotificationsKey) ?? true,
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

  /// Turns the reminder before each prayer on (asking for permission
  /// first) or off. Returns false when the user refused notifications.
  Future<bool> setEarly(bool on) async {
    if (on && !await _requestPermission()) return false;
    await _save(state.copyWith(early: on));
    return true;
  }

  /// The app-wide notifications switch (Settings). Turning it on asks for
  /// permission when something is set to notify. False when refused.
  Future<bool> setAppNotifications(bool on) async {
    if (on && (state.enabled || state.early) && !await _requestPermission()) {
      return false;
    }
    await _save(state.copyWith(appNotifications: on));
    return true;
  }

  /// How many minutes before the prayer the reminder comes (5, 10 or 15).
  Future<void> setEarlyMinutes(int minutes) async {
    if (!AdhanSettings.earlyChoices.contains(minutes)) return;
    await _save(state.copyWith(earlyMinutes: minutes));
  }

  /// Full adhan, opening takbir only, or silent for one prayer.
  Future<void> setSound(String prayerKey, AdhanSound sound) =>
      _save(state.withSound(prayerKey, sound));

  /// Turns one prayer's adhan on or off.
  Future<void> togglePrayer(String prayerKey) =>
      _save(state.toggle(prayerKey));

  Future<void> _save(AdhanSettings value) async {
    emit(value);
    await _prefs.setBool(_enabledKey, value.enabled);
    await _prefs.setStringList(_prayersKey, value.prayers);
    await _prefs.setStringList(_shortKey, value.shortPrayers);
    await _prefs.setBool(_asAlarmKey, value.asAlarm);
    await _prefs.setBool(_earlyKey, value.early);
    await _prefs.setInt(_earlyMinutesKey, value.earlyMinutes);
    await _prefs.setBool(_appNotificationsKey, value.appNotifications);
  }
}
