# وِرْد — Wird

Flutter app for daily azkar and prayer times. Arabic, right-to-left, with light and dark themes.

## Features

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

**Themes**: light and dark, following the device until you pick one. The choice is remembered.

## Project layout

```
lib/
  core/app/            theme (colors, type, spacing) and routes
  core/custom_widgets/ app bar, screen, menu tile, theme toggle
  feature/model/       azkar data
  feature/screen/
    home/              home menu
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
