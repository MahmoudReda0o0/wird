import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wird design system — color tokens for the Parchment (light) and
/// Night (dark) themes. Read them with `context.wird`.
@immutable
class WirdColors extends ThemeExtension<WirdColors> {
  const WirdColors({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkMuted,
    required this.primary,
    required this.primaryPressed,
    required this.primarySoft,
    required this.onPrimary,
    required this.gold,
    required this.onGold,
    required this.goldSoft,
    required this.goldInk,
    required this.warning,
    required this.warningSoft,
    required this.onWarning,
    required this.kaaba,
    required this.focus,
    required this.scrim,
    required this.cardShadow,
  });

  /// Scaffold background.
  final Color surface;

  /// Cards, menu tiles, the app bar, the prayer-times panel.
  final Color surfaceRaised;

  /// Wells inside a card (the virtue panel) and pressed tiles.
  final Color surfaceSunken;

  /// Decorative hairlines.
  final Color line;

  /// Borders that carry meaning (outlined controls).
  final Color lineStrong;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color inkMuted;

  /// Brand teal: active / in progress.
  final Color primary;
  final Color primaryPressed;
  final Color primarySoft;
  final Color onPrimary;

  /// Gold: completion only.
  final Color gold;
  final Color onGold;
  final Color goldSoft;

  /// The opening line of a zikr (basmala, isti'adha).
  final Color goldInk;

  /// Orange: "don't trust this right now" (the Qibla compass warnings).
  final Color warning;
  final Color warningSoft;
  final Color onWarning;

  /// The Kaaba drawn on the Qibla dial.
  final Color kaaba;

  final Color focus;
  final Color scrim;
  final List<BoxShadow> cardShadow;

  static const light = WirdColors(
    surface: Color(0xFFF6F3EB),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFECE6D8),
    line: Color(0xFFDDD4C2),
    lineStrong: Color(0xFF8E8676),
    ink: Color(0xFF1C2623),
    inkMuted: Color(0xFF56635E),
    primary: Color(0xFF0B6B5D),
    primaryPressed: Color(0xFF085246),
    primarySoft: Color(0xFFD9EEE8),
    onPrimary: Color(0xFFFFFFFF),
    gold: Color(0xFFE3A82B),
    onGold: Color(0xFF2B1F06),
    goldSoft: Color(0xFFFBF0D6),
    goldInk: Color(0xFF835500),
    warning: Color(0xFFB5531A),
    warningSoft: Color(0xFFFBE3D3),
    onWarning: Color(0xFF3A1A06),
    kaaba: Color(0xFF1C2623),
    focus: Color(0xFF0B6B5D),
    scrim: Color(0x521C2623),
    cardShadow: [
      BoxShadow(color: Color(0x0F1C2623), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x0F1C2623), offset: Offset(0, 6), blurRadius: 16),
    ],
  );

  static const dark = WirdColors(
    surface: Color(0xFF0E1412),
    surfaceRaised: Color(0xFF17201D),
    surfaceSunken: Color(0xFF0A0F0D),
    line: Color(0xFF29342F),
    lineStrong: Color(0xFF6F7C77),
    ink: Color(0xFFE8EFEC),
    inkMuted: Color(0xFF9DADA7),
    primary: Color(0xFF5CCFB9),
    primaryPressed: Color(0xFF86DDCC),
    primarySoft: Color(0xFF11352F),
    onPrimary: Color(0xFF0B1210),
    gold: Color(0xFFE9B84A),
    onGold: Color(0xFF241A04),
    goldSoft: Color(0xFF33280F),
    goldInk: Color(0xFFECC266),
    warning: Color(0xFFF0A36B),
    warningSoft: Color(0xFF33190A),
    onWarning: Color(0xFFF8C9A6),
    kaaba: Color(0xFF0B1210),
    focus: Color(0xFF7FE0CD),
    scrim: Color(0x8F000000),
    cardShadow: [BoxShadow(color: Color(0x0AE8EFEC), spreadRadius: 1)],
  );

  @override
  WirdColors copyWith({
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? line,
    Color? lineStrong,
    Color? ink,
    Color? inkMuted,
    Color? primary,
    Color? primaryPressed,
    Color? primarySoft,
    Color? onPrimary,
    Color? gold,
    Color? onGold,
    Color? goldSoft,
    Color? goldInk,
    Color? warning,
    Color? warningSoft,
    Color? onWarning,
    Color? kaaba,
    Color? focus,
    Color? scrim,
    List<BoxShadow>? cardShadow,
  }) {
    return WirdColors(
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimary: onPrimary ?? this.onPrimary,
      gold: gold ?? this.gold,
      onGold: onGold ?? this.onGold,
      goldSoft: goldSoft ?? this.goldSoft,
      goldInk: goldInk ?? this.goldInk,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      onWarning: onWarning ?? this.onWarning,
      kaaba: kaaba ?? this.kaaba,
      focus: focus ?? this.focus,
      scrim: scrim ?? this.scrim,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  /// These colors with some replaced by name (the [WirdColors] field
  /// names, e.g. `primary`). Unknown names are ignored. Used by seasonal
  /// themes, whose colors come from the server.
  WirdColors withOverrides(Map<String, Color> o) {
    if (o.isEmpty) return this;
    return copyWith(
      surface: o['surface'],
      surfaceRaised: o['surfaceRaised'],
      surfaceSunken: o['surfaceSunken'],
      line: o['line'],
      lineStrong: o['lineStrong'],
      ink: o['ink'],
      inkMuted: o['inkMuted'],
      primary: o['primary'],
      primaryPressed: o['primaryPressed'],
      primarySoft: o['primarySoft'],
      onPrimary: o['onPrimary'],
      gold: o['gold'],
      onGold: o['onGold'],
      goldSoft: o['goldSoft'],
      goldInk: o['goldInk'],
      warning: o['warning'],
      warningSoft: o['warningSoft'],
      onWarning: o['onWarning'],
      kaaba: o['kaaba'],
      focus: o['focus'],
      scrim: o['scrim'],
    );
  }

  @override
  WirdColors lerp(ThemeExtension<WirdColors>? other, double t) {
    if (other is! WirdColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return WirdColors(
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      line: l(line, other.line),
      lineStrong: l(lineStrong, other.lineStrong),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      primary: l(primary, other.primary),
      primaryPressed: l(primaryPressed, other.primaryPressed),
      primarySoft: l(primarySoft, other.primarySoft),
      onPrimary: l(onPrimary, other.onPrimary),
      gold: l(gold, other.gold),
      onGold: l(onGold, other.onGold),
      goldSoft: l(goldSoft, other.goldSoft),
      goldInk: l(goldInk, other.goldInk),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      onWarning: l(onWarning, other.onWarning),
      kaaba: l(kaaba, other.kaaba),
      focus: l(focus, other.focus),
      scrim: l(scrim, other.scrim),
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}

extension WirdThemeContext on BuildContext {
  /// The Wird color tokens for the current theme.
  WirdColors get wird => Theme.of(this).extension<WirdColors>() ?? WirdColors.light;
}

/// Wird type scale. UI text is IBM Plex Sans Arabic, zikr text is Noto
/// Naskh Arabic (picked for clarity on screen). Both ship in the app
/// (`assets/fonts`, declared in pubspec.yaml), so nothing is downloaded.
/// Apply a color with `.copyWith(color: context.wird.ink)`.
class AppText {
  AppText._();

  /// Font family names, as declared in pubspec.yaml.
  static const uiFamily = 'IBMPlexSansArabic';
  static const readingFamily = 'NotoNaskhArabic';

  static TextStyle _ui(double size, double line, FontWeight weight) =>
      TextStyle(
        fontFamily: uiFamily,
        fontSize: size,
        height: line / size,
        fontWeight: weight,
      );

  static TextStyle _reading(double size, double line, FontWeight weight) =>
      TextStyle(
        fontFamily: readingFamily,
        fontSize: size,
        height: line / size,
        fontWeight: weight,
      );

  /// The live countdown on the home next-prayer card ("01:24:37").
  static TextStyle get countdown =>
      _ui(52, 60, FontWeight.w600).copyWith(
        letterSpacing: 1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// The next prayer's name on the home next-prayer card.
  static TextStyle get hero => _ui(28, 38, FontWeight.w600);

  /// The next prayer's time.
  static TextStyle get display => _ui(34, 44, FontWeight.w600);

  /// App-bar titles.
  static TextStyle get title => _ui(20, 30, FontWeight.w600);

  /// Menu-tile labels and prayer names.
  static TextStyle get heading => _ui(17, 26, FontWeight.w600);

  /// Supporting copy and subtitles.
  static TextStyle get body => _ui(15, 24, FontWeight.w400);

  /// Counter pill, buttons, chips.
  static TextStyle get label => _ui(14, 20, FontWeight.w600);

  /// Zikr number, AM/PM marks, metadata.
  static TextStyle get caption => _ui(12, 18, FontWeight.w500);

  /// The zikr text itself. Never smaller than 20px.
  static TextStyle get zikr => _reading(22, 42, FontWeight.w400);

  /// The opening line above a zikr.
  static TextStyle get zikrLead => _reading(18, 32, FontWeight.w700);

  /// The virtue (fadl) text.
  static TextStyle get fadl => _reading(16, 28, FontWeight.w400);
}

/// Spacing scale (space-1 … space-8).
class AppSpace {
  AppSpace._();
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
}

/// Corner radii.
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, WirdColors.light);

  static ThemeData get dark => _build(Brightness.dark, WirdColors.dark);

  /// The light or dark theme with some colors replaced by name
  /// ([WirdColors.withOverrides]) and, when given, the Android navigation
  /// bar colored [navBar]. Used by seasonal themes.
  static ThemeData themed(
    Brightness brightness, {
    Map<String, Color> colors = const {},
    Color? navBar,
  }) {
    final base = brightness == Brightness.dark
        ? WirdColors.dark
        : WirdColors.light;
    return _build(brightness, base.withOverrides(colors), navBar: navBar);
  }

  static ThemeData _build(
    Brightness brightness,
    WirdColors c, {
    Color? navBar,
  }) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primarySoft,
      onPrimaryContainer: c.primary,
      secondary: c.gold,
      onSecondary: c.onGold,
      secondaryContainer: c.goldSoft,
      onSecondaryContainer: c.ink,
      tertiary: c.goldInk,
      onTertiary: c.surfaceRaised,
      error: isDark ? const Color(0xFFF2B8B5) : const Color(0xFFB3261E),
      onError: isDark ? const Color(0xFF601410) : const Color(0xFFFFFFFF),
      surface: c.surfaceRaised,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerHighest: c.surfaceSunken,
      outline: c.lineStrong,
      outlineVariant: c.line,
      scrim: c.scrim,
    );

    final baseText = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.surface,
      fontFamily: AppText.uiFamily,
      textTheme: baseText.apply(
        fontFamily: AppText.uiFamily,
        bodyColor: c.ink,
        displayColor: c.ink,
      ),
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.surfaceRaised,
        foregroundColor: c.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppText.title.copyWith(color: c.primary),
        iconTheme: IconThemeData(color: c.primary),
        systemOverlayStyle: navBar == null
            ? null
            : SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: brightness,
                systemNavigationBarColor: navBar,
                systemNavigationBarIconBrightness:
                    navBar.computeLuminance() > 0.5
                    ? Brightness.dark
                    : Brightness.light,
              ),
      ),
      iconTheme: IconThemeData(color: c.primary),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      focusColor: c.focus.withValues(alpha: 0.24),
      splashColor: c.primarySoft,
      highlightColor: c.surfaceSunken,
    );
  }
}
