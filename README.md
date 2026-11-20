# وِرْد — Wird

Flutter app for daily azkar and prayer times. Arabic, right-to-left, with light and dark themes.

## Features

**Home**: today's date and city, a card with a live countdown (HH:MM:SS) to the next prayer and a bar showing how much of the wait has passed, then a two-column grid of sections.

**Azkar**: 97 azkar in five sections: morning, evening, tasabih, before sleep and on waking.
- Tap a card to count one repetition. When the count reaches zero the card turns gold and shows «تمّ».
- Each zikr's virtue (فضل الذكر) opens under the card when it has one.
- Progress is saved per section for the current day and starts again the next day.
- Each section shows how many azkar are done, with a button to start over.
- **Sabha mode**: the beads button at the bottom right of any section opens one zikr at a time with a big count button, calm colors, and arrows to move between azkar. When a zikr is finished it moves on to the next one by itself. It shares the section's saved progress.

**Prayer times**
- Fajr, Shurooq, Dhuhr, Asr, Maghrib and Isha for the selected city, calculated on the device.
- Method: Egyptian General Authority of Survey. Asr follows the Shafi madhab.
- 27 Egyptian cities, with Mansoura as the default. The chosen city is remembered.
- The next prayer is highlighted, with a countdown to it. After Isha it shows tomorrow's Fajr.
- The times update by themselves after midnight.

**Adhan**: a «صوت الأذان» switch on the prayer-times screen, with a bell per prayer, and a chip on the home next-prayer card that shows whether it's on and opens that screen. Each enabled prayer gets a notification with the adhan sound at its time: a Fajr adhan for Fajr and the regular adhan for the others. Adhans are scheduled 10 days ahead, and again on every app start or city change. Turning the adhan on asks for notification permission, and for exact alarms on Android.

Sounds:
- Android: `res/raw/adhan.mp3` and `res/raw/adhan_fajr.mp3` at full length. `res/raw/keep.xml` keeps them in release builds.
- iOS: `ios/Runner/adhan.caf` and `adhan_fajr.caf`, already in the Runner target. iOS plays at most 30 seconds of a notification sound, so these are the first 30 seconds with a fade-out.

**About / version**: the installed version (from `version:` in pubspec.yaml) sits beside the home title and opens «عن التطبيق».
- On every launch the app reads `release/latest.json` from the `new_version` branch on GitHub (`AppInfo.latestReleaseUrl`, the raw file of the public repo). If it names a newer version, the badge turns green «تحديث 1.1.0», home shows a message once for that version, and «عن التطبيق» shows the new version, its notes and a «تنزيل النسخة الجديدة» button that opens the Drive folder. The last file read is saved, so a known update still shows offline; no internet or no file just means no update section.
- Right after installing an update the badge turns gold «جديد» until «عن التطبيق» is opened.
- «عن التطبيق» also shows the installed version and what's new in it (`AppInfo.releaseNotes`), and the Drive folder link (`AppInfo.downloadUrl`) with a QR code, an open button and a copy button.

**Themes**: light and dark, following the device until you pick one. The choice is remembered.

## State management

The app's state lives in Cubits (`flutter_bloc`):

| Cubit | State | Where |
| --- | --- | --- |
| `ThemeCubit` | `ThemeMode`, saved | app root |
| `CityCubit` | the selected `PrayerCity`, saved | app root |
| `AdhanCubit` | `AdhanSettings` (on/off + per-prayer), saved; asks for permission when turned on | app root |
| `AzkarProgressCubit` | repetitions left per zikr in one section, saved for the day | each azkar page, shared with its sabha |
| `AppVersionCubit` | installed version + whether it's new to the user | app root |
| `SabhaCubit` | which zikr the sabha shows; moves on when one is finished | the sabha screen |

`app/bootstrap.dart` reads `SharedPreferences` once, creates the app-wide Cubits, and `app/app.dart` and provides them with a `MultiBlocProvider`. A `MultiBlocListener` there reschedules the adhan notifications whenever the city or the adhan settings change. The prayer-time calculation (`PrayerTimingData`, `AdhanPlan`) stays as pure functions; screens recalculate from the current state on each tick.

## Project layout

```
lib/
  main.dart            calls bootstrap()
  app/
    bootstrap.dart     reads saved state, creates the app-wide Cubits, runs the app
    app.dart           MyApp: providers, adhan listeners, MaterialApp
    router/            route names (app_routes) and the route table (app_router)
  core/                shared by every feature; imports no feature
    theme/             colors, type, spacing, radius, ThemeCubit
    widgets/           app bar, screen, menu tile, theme toggle
  features/
    home/              next-prayer countdown card and sections grid
    azkar/             data (azkar, saved progress), cubits, screens, sabha mode
    prayer_times/      cities, calculation, prayer-times screen, city picker
    adhan/             settings, plan, scheduling the notifications
    about/             app info, version badge, «عن التطبيق» screen
test/                  mirrors lib/: test/features/<feature>/…
```

Each feature folder uses the same parts, only the ones it needs:
`data/` (models, storage, pure logic), `cubit/`, `view/` (screens) and `widgets/`.

Adding a feature: create `lib/features/<name>/`, add its screen to
`app/router/app_router.dart` and its name to `app_routes.dart`, and, if its
state is app-wide, create its Cubit in `app/bootstrap.dart` and provide it in
`app/app.dart`. Code flows one way: `view` → `cubit` → `data` → `core`.

## Run

```
flutter pub get
flutter test
flutter run
```

App ID: `com.mahmoudreda.wird` (Android and iOS).

## Releasing a new version

1. Bump `version:` in `pubspec.yaml` (e.g. `1.0.0+1` → `1.1.0+2`).
2. Write the changes in `AppInfo.releaseNotes` (`lib/features/about/data/app_info.dart`), one line each.
3. `flutter build apk --release` and upload the APK to the Drive folder in `AppInfo.downloadUrl`, shared as "Anyone with the link".
4. Update `release/latest.json` with the new `version`, `build` and `notes` (the same lines as `releaseNotes`), commit, and only after the APK is on Drive, bring the `new_version` branch up to that commit and push it (`git push origin main:new_version`). Raw GitHub files can take a few minutes to refresh.

Users on the old version see «تحديث» on home and the download button in «عن التطبيق». After they install it they see the gold «جديد» badge until they open «عن التطبيق».
