# القبلة (Qibla) — design

Date: 2026-11-21 · Status: approved by Mahmoud ("ابدا ف التنفيذ")
Design canvas: https://claude.ai/artifact/RpBu25V8JMBVydr7ixRWgQ (`Wird — القبلة`)

## Intent

A Qibla screen in Wird that a regular person can trust while standing to pray,
reached from a new home tile. Accuracy problems in practice come from the
phone's compass (magnetic north, iron nearby, no calibration), not from the
math, so the screen's job is to show the direction **and** to say honestly
when the compass can't be trusted, with a fallback (the sun) that works on any
phone.

## Goals

- Direction from the chosen city (`PrayerCity` lat/lon) — no GPS, no location
  permission. City-level error is < 1° (Makkah is 1,000+ km away).
- Rotating dial, fixed pointer at the top; turn until the Kaaba is under it.
  "لفّ يمين/شمال N°" (physical clockwise / counter-clockwise, not screen RTL).
- Aligned within ±3°: ring and Kaaba chip turn primary, "إنت في اتجاه القبلة",
  one light haptic on entering alignment.
- True north: magnetic heading + declination (≈4° E over Egypt).
- The five extras Mahmoud picked:
  1. **Iron / magnet nearby** warning from the magnetic field strength.
  2. **Qibla by the sun**: sun on the dial; a card "اقف ووشّك للشمس، ولفّ
     يمين/شمال N°"; tapping it opens a bottom sheet that explains it step by
     step. At night: "الشمس غابت، استخدم البوصلة". Twice a year, on the days
     the sun passes over the Kaaba, a gold card with the time.
  3. **Screen stays on** while the screen is open (icon in the app bar).
  4. **Next prayer** line at the bottom ("العصر بعد 38 دقيقة · 2:38 م").
  5. **Compass accuracy** indicator (3 bars: عالية / متوسطة / ضعيفة).
- **No compass**: big "140° جنوب شرق" from north + the sun card as the main
  way.
- Home: a third grid tile «القبلة», subtitle «اتجاه الكعبة».

## Non-goals

GPS / current location (plan item 9), maps, camera/AR, a distance-to-Makkah
figure (removed on request), the angle number on the main screen when there's
a compass (removed on request — the number shows only without a compass),
notification for the Kaaba sun days (later, with the azkar reminders).

## Anti-goals

A confident arrow when the compass is unreliable. Every unreliable state
(calibration, interference, unavailable) dims the dial and says so.

## Approaches (compass source)

| | Package | Trade-off |
|---|---|---|
| A | `flutter_compass` 0.8.1 | Most used, but last release Nov 2024; magnetic only (we'd need our own declination table, no reliable data at hand); 3-step accuracy; no Swift PM; author of B lists open Android build issues and we're on AGP 9. |
| B ✅ | `true_compass` 0.0.2 | True north from an offline WMM2025 model (valid to 2030), accuracy + `calibrationNeeded` streams, smoothing that handles 359→0, screen-rotation compensation, no permissions, claims AGP 8/9 + Swift PM. Brand new (2 days), unverified uploader, needs **iOS 15**. |
| C | `sensors_plus` + our own fusion | Most control, much more work, jittery without proper fusion. |

**Pick: B, behind our own `HeadingSource` interface**, so swapping to A or C
touches one file. CI's APK build catches Android build breaks before the
phone. Our call (Mahmoud handed over the how).
Field strength for the interference warning comes from
`sensors_plus` `magnetometerEventStream` (µT); true_compass doesn't expose it.
Screen-on: `wakelock_plus`. Haptic: `HapticFeedback.lightImpact` (no package).

## Design (how it's built)

Feature `lib/features/qibla/`, same layering as the others
(view → cubit → data → core):

- `data/qibla_math.dart` — pure:
  - `bearingToKaaba(lat, lon)` (great-circle initial bearing; Kaaba
    21.4225, 39.8262). Mansoura → 139.9°.
  - `signedDelta(from, to)` in (-180, 180].
  - `compassPoint(deg)` → Arabic 8-point name ("جنوب شرق").
- `data/sun_position.dart` — pure NOAA-style solar position:
  `azimuth/altitude(lat, lon, DateTime utc)`; `kaabaSunTransits(year)` →
  the two moments the sun is closest to the Kaaba's zenith (≈27–28 May and
  15–16 July). Checked against known values in tests.
- `data/heading_source.dart` — `HeadingSource` interface:
  `Stream<HeadingReading>` (true heading if known else magnetic, accuracy
  enum, needsCalibration), `Future<bool> available()`, `Stream<double>`
  field strength µT, `dispose()`. `TrueCompassHeadingSource` implements it
  with `true_compass` + `sensors_plus`; tests use a fake.
- `cubit/qibla_cubit.dart` — `QiblaState`: `status` (loading / live /
  noSensor), `heading`, `qibla`, `delta`, `aligned`, `accuracy`,
  `needsCalibration`, `interference` (field outside ~20–70 µT for > 1 s),
  `unreliable` (= calibration || interference || accuracy unreliable).
  Takes the city (re-targets when `CityCubit` changes) and a clock.
  Emits a one-shot `justAligned` for the haptic.
- `view/qibla_screen.dart` + `widgets/qibla_dial.dart` (CustomPainter:
  ticks, ش ق ج غ, sun, Kaaba chip, fixed pointer), `sun_card.dart`
  + `sun_help_sheet.dart`, `accuracy_bars.dart`, warning card,
  no-compass view, next-prayer line (reuses `PrayerTimingData.next`).
  Wakelock on in `initState`, off in `dispose`.
- Home: third `HomeGridTile` → `AppRoutes.qibla`.
- iOS: deployment target 13 → 15; `NSMotionUsageDescription` for
  sensors_plus.
- All colors through `context.wird`; gold/warning tokens added to
  `WirdColors` if missing (no hex in screens).

## Tests

Pure: bearings for known cities (Mansoura 139.9, Cairo 136.1, Aswan 111.3),
delta wrap-around, compass points, sun azimuth (Mansoura 21 Nov 2026 14:00 →
≈218°), Kaaba transit dates. Cubit with a fake `HeadingSource`: aligned
window, haptic once, calibration/interference → unreliable, noSensor, city
change. Widgets: each state renders without overflow on a narrow phone, sheet
opens/closes, home tile opens the screen.

## Left to the builder

Exact interference thresholds and debounce, smoothing amounts, dial painter
details, the sun-help sheet's illustration (painter or SVG-free widgets).
