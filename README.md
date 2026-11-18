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

**Themes**: light and dark, following the device until you pick one. The choice is remembered.

## Project layout

```
lib/
  core/app/            theme (colors, type, spacing) and routes
  core/custom_widgets/ app bar, screen, menu tile, theme toggle
  feature/model/       azkar data
  feature/screen/
    home/              home: next-prayer countdown card and sections grid
    azkar/             section list, azkar page, card, saved progress, sabha mode
    prayer_timing/     cities, calculation, prayer-times screen
test/                  unit tests for prayer times, azkar progress and the sabha
```

## Run

```
flutter pub get
flutter test
flutter run
```

App ID: `com.mahmoudreda.wird` (Android and iOS).
