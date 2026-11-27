import 'package:flutter/foundation.dart';

/// What one prayer's adhan sounds like.
enum AdhanSound {
  /// The whole adhan.
  full,

  /// Just the opening «الله أكبر، الله أكبر» (first 12 seconds).
  short,

  /// No adhan for this prayer.
  silent,
}

/// Whether the adhan plays, and how for each of the five prayers.
@immutable
class AdhanSettings {
  const AdhanSettings({
    required this.enabled,
    required this.prayers,
    this.shortPrayers = const [],
    this.asAlarm = false,
    this.early = false,
    this.earlyMinutes = 10,
  });

  /// The five prayers that can have an adhan, in order.
  static const allPrayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  /// Off until the user turns it on (that's when permission is asked).
  static const initial = AdhanSettings(enabled: false, prayers: allPrayers);

  final bool enabled;

  /// Keys from [allPrayers] that have the adhan on (full or short).
  final List<String> prayers;

  /// Keys from [prayers] that play only the opening takbir.
  final List<String> shortPrayers;

  /// Android: play the adhan on the alarm volume, so it sounds even when
  /// the phone is on silent or vibrate. Off by default.
  final bool asAlarm;

  /// A reminder notification [earlyMinutes] before every prayer. Separate
  /// from the adhan: it works with the adhan off or silent.
  final bool early;

  /// One of [earlyChoices].
  final int earlyMinutes;

  /// The minutes the early reminder can be set to.
  static const earlyChoices = [5, 10, 15];

  bool isOn(String prayerKey) => enabled && prayers.contains(prayerKey);

  /// This prayer's choice, kept even while the master switch is off.
  AdhanSound soundOf(String prayerKey) => !prayers.contains(prayerKey)
      ? AdhanSound.silent
      : shortPrayers.contains(prayerKey)
      ? AdhanSound.short
      : AdhanSound.full;

  AdhanSettings copyWith({
    bool? enabled,
    List<String>? prayers,
    List<String>? shortPrayers,
    bool? asAlarm,
    bool? early,
    int? earlyMinutes,
  }) => AdhanSettings(
    enabled: enabled ?? this.enabled,
    prayers: prayers ?? this.prayers,
    shortPrayers: shortPrayers ?? this.shortPrayers,
    asAlarm: asAlarm ?? this.asAlarm,
    early: early ?? this.early,
    earlyMinutes: earlyMinutes ?? this.earlyMinutes,
  );

  /// Sets one prayer to [sound], keeping [allPrayers] order.
  AdhanSettings withSound(String prayerKey, AdhanSound sound) {
    bool on(String k) =>
        k == prayerKey ? sound != AdhanSound.silent : prayers.contains(k);
    bool short(String k) =>
        k == prayerKey ? sound == AdhanSound.short : shortPrayers.contains(k);
    return copyWith(
      prayers: [for (final k in allPrayers) if (on(k)) k],
      shortPrayers: [for (final k in allPrayers) if (on(k) && short(k)) k],
    );
  }

  /// Turns one prayer between silent and the full adhan.
  AdhanSettings toggle(String prayerKey) => withSound(
    prayerKey,
    prayers.contains(prayerKey) ? AdhanSound.silent : AdhanSound.full,
  );
}
