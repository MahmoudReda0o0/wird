import 'package:flutter/material.dart';

/// One seasonal theme, a row of the `themes` table on Supabase (Ramadan,
/// the last ten nights, Eid...). Nothing here knows which occasion it is:
/// the dates run it.
///
/// * From [countdownFrom] until the day before [startsOn], home shows
///   [countdownLabel] with the days left (when it's set).
/// * From [startsOn] to [endsOn] (both included) the theme is on: its
///   colors, images and, once, the note dialog.
@immutable
class SeasonTheme {
  const SeasonTheme({
    required this.slug,
    required this.startsOn,
    required this.endsOn,
    this.leadDays = 0,
    this.priority = 1,
    this.colorsLight = const {},
    this.colorsDark = const {},
    this.navBarLight,
    this.navBarDark,
    this.heroImage,
    this.appbarImage,
    this.patternImage,
    this.patternOpacity = 0.08,
    this.countdownLabel,
    this.heroOverline,
    this.noteTitle,
    this.noteBody,
    this.noteButton = 'تمام',
  });

  final String slug;

  /// Days, as UTC midnights (see [day]).
  final DateTime startsOn;
  final DateTime endsOn;
  final int leadDays;
  final int priority;

  /// Color overrides by `WirdColors` field name.
  final Map<String, Color> colorsLight;
  final Map<String, Color> colorsDark;
  final Color? navBarLight;
  final Color? navBarDark;

  /// Paths in the public `themes` storage bucket.
  final String? heroImage;
  final String? appbarImage;
  final String? patternImage;
  final double patternOpacity;

  final String? countdownLabel;
  final String? heroOverline;
  final String? noteTitle;
  final String? noteBody;
  final String noteButton;

  /// The first day home counts down to [startsOn].
  DateTime get countdownFrom => startsOn.subtract(Duration(days: leadDays));

  /// Every image this theme uses.
  List<String> get images => [
    for (final p in [heroImage, appbarImage, patternImage])
      if (p != null && p.isNotEmpty) p,
  ];

  bool get hasNote => (noteTitle ?? '').isNotEmpty;

  /// Whether the theme is on, on [today] (a [day]).
  bool isOn(DateTime today) =>
      !today.isBefore(startsOn) && !today.isAfter(endsOn);

  /// Whether home counts down to this theme on [today].
  bool isCountingDown(DateTime today) =>
      (countdownLabel ?? '').isNotEmpty &&
      today.isBefore(startsOn) &&
      !today.isBefore(countdownFrom);

  /// Whole days from [today] to [startsOn].
  int daysUntil(DateTime today) => startsOn.difference(today).inDays;

  /// Whether the phone should keep this theme on [today]: it hasn't ended,
  /// and it (or its countdown) starts within [window] days.
  bool isWanted(DateTime today, {int window = 15}) =>
      !today.isAfter(endsOn) &&
      !countdownFrom.isAfter(today.add(Duration(days: window)));

  /// A calendar day as a UTC midnight, so day maths ignores time zones.
  static DateTime day(DateTime t) => DateTime.utc(t.year, t.month, t.day);

  /// Reads a row (from Supabase or from what was saved). Null when it isn't
  /// a usable theme.
  static SeasonTheme? fromJson(Object? json) {
    if (json is! Map) return null;
    final slug = json['slug'];
    final starts = _date(json['starts_on']);
    final ends = _date(json['ends_on']);
    if (slug is! String || starts == null || ends == null) return null;
    if (ends.isBefore(starts)) return null;
    return SeasonTheme(
      slug: slug,
      startsOn: starts,
      endsOn: ends,
      leadDays: _int(json['lead_days']) ?? 0,
      priority: _int(json['priority']) ?? 1,
      colorsLight: _colors(json['colors_light']),
      colorsDark: _colors(json['colors_dark']),
      navBarLight: parseColor(json['nav_bar_color_light']),
      navBarDark: parseColor(json['nav_bar_color_dark']),
      heroImage: _text(json['hero_image']),
      appbarImage: _text(json['appbar_image']),
      patternImage: _text(json['pattern_image']),
      patternOpacity:
          ((json['pattern_opacity'] as num?)?.toDouble() ?? 0.08)
              .clamp(0.0, 0.3)
              .toDouble(),
      countdownLabel: _text(json['countdown_label']),
      heroOverline: _text(json['hero_overline']),
      noteTitle: _text(json['note_title']),
      noteBody: _text(json['note_body']),
      noteButton: _text(json['note_button']) ?? 'تمام',
    );
  }

  Map<String, Object?> toJson() => {
    'slug': slug,
    'starts_on': _iso(startsOn),
    'ends_on': _iso(endsOn),
    'lead_days': leadDays,
    'priority': priority,
    'colors_light': {for (final e in colorsLight.entries) e.key: _hex(e.value)},
    'colors_dark': {for (final e in colorsDark.entries) e.key: _hex(e.value)},
    'nav_bar_color_light': navBarLight == null ? null : _hex(navBarLight!),
    'nav_bar_color_dark': navBarDark == null ? null : _hex(navBarDark!),
    'hero_image': heroImage,
    'appbar_image': appbarImage,
    'pattern_image': patternImage,
    'pattern_opacity': patternOpacity,
    'countdown_label': countdownLabel,
    'hero_overline': heroOverline,
    'note_title': noteTitle,
    'note_body': noteBody,
    'note_button': noteButton,
  };

  /// `#RRGGBB` → an opaque color; anything else → null.
  static Color? parseColor(Object? v) {
    if (v is! String) return null;
    final m = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(v.trim());
    if (m == null) return null;
    return Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
  }

  static Map<String, Color> _colors(Object? v) {
    if (v is! Map) return const {};
    return {
      for (final e in v.entries)
        if (e.key is String && parseColor(e.value) != null)
          e.key as String: parseColor(e.value)!,
    };
  }

  static DateTime? _date(Object? v) {
    if (v is! String) return null;
    final t = DateTime.tryParse(v);
    return t == null ? null : day(t);
  }

  static int? _int(Object? v) => v is int ? v : (v is num ? v.toInt() : null);

  static String? _text(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
