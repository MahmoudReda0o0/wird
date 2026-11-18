import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the adhan plays, and for which of the five prayers.
@immutable
class AdhanSettings {
  const AdhanSettings({required this.enabled, required this.prayers});

  /// The five prayers that can have an adhan, in order.
  static const allPrayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  /// Off until the user turns it on (that's when permission is asked).
  static const initial = AdhanSettings(enabled: false, prayers: allPrayers);

  final bool enabled;

  /// Keys from [allPrayers] that have the adhan on.
  final List<String> prayers;

  bool isOn(String prayerKey) => enabled && prayers.contains(prayerKey);

  AdhanSettings copyWith({bool? enabled, List<String>? prayers}) =>
      AdhanSettings(
        enabled: enabled ?? this.enabled,
        prayers: prayers ?? this.prayers,
      );

  /// Turns one prayer on or off, keeping [allPrayers] order.
  AdhanSettings toggle(String prayerKey) {
    final on = prayers.contains(prayerKey);
    return copyWith(
      prayers: [
        for (final k in allPrayers)
          if (k == prayerKey ? !on : prayers.contains(k)) k,
      ],
    );
  }
}

/// The saved adhan settings. Load once in main() before runApp().
class AdhanSettingsController {
  AdhanSettingsController._();

  static const _enabledKey = 'adhan_enabled';
  static const _prayersKey = 'adhan_prayers';

  static final ValueNotifier<AdhanSettings> settings = ValueNotifier(
    AdhanSettings.initial,
  );

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prayersKey);
    settings.value = AdhanSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      prayers: saved == null
          ? AdhanSettings.allPrayers
          : [
              for (final k in AdhanSettings.allPrayers)
                if (saved.contains(k)) k,
            ],
    );
  }

  static Future<void> update(AdhanSettings value) async {
    settings.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value.enabled);
    await prefs.setStringList(_prayersKey, value.prayers);
  }
}
