import 'package:flutter/foundation.dart';

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
