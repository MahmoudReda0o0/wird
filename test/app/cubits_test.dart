import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/core/theme/theme_cubit.dart';
import 'package:my_guide/features/adhan/data/adhan_settings.dart';
import 'package:my_guide/features/adhan/cubit/adhan_cubit.dart';
import 'package:my_guide/features/prayer_times/cubit/city_cubit.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  group('ThemeCubit', () {
    test('follows the device until the user picks one', () async {
      expect(ThemeCubit(await _prefs()).state, ThemeMode.system);
    });

    test('restores the saved choice', () async {
      final prefs = await _prefs({'theme_mode': 'dark'});
      expect(ThemeCubit(prefs).state, ThemeMode.dark);
    });

    test('toggles away from what is shown and saves it', () async {
      final prefs = await _prefs();
      final cubit = ThemeCubit(prefs);
      await cubit.toggle(Brightness.light);
      expect(cubit.state, ThemeMode.dark);
      expect(prefs.getString('theme_mode'), 'dark');
      await cubit.toggle(Brightness.dark);
      expect(cubit.state, ThemeMode.light);
    });
  });

  group('CityCubit', () {
    test('Mansoura by default, unknown ids too', () async {
      expect(CityCubit(await _prefs()).state.id, 'mansoura');
      final odd = await _prefs({'prayer_city': 'nowhere'});
      expect(CityCubit(odd).state.id, 'mansoura');
    });

    test('select emits and saves', () async {
      final prefs = await _prefs();
      final cubit = CityCubit(prefs);
      await cubit.select(PrayerCity.byId('cairo'));
      expect(cubit.state.id, 'cairo');
      expect(CityCubit(prefs).state.id, 'cairo');
    });
  });

  group('AdhanCubit', () {
    test('off by default with all five prayers', () async {
      final cubit = AdhanCubit(
        await _prefs(),
        requestPermission: () async => true,
      );
      expect(cubit.state.enabled, isFalse);
      expect(cubit.state.prayers, AdhanSettings.allPrayers);
    });

    test('turning on asks for permission, then saves', () async {
      final prefs = await _prefs();
      var asked = 0;
      final cubit = AdhanCubit(
        prefs,
        requestPermission: () async {
          asked++;
          return true;
        },
      );
      expect(await cubit.setEnabled(true), isTrue);
      expect(asked, 1);
      expect(cubit.state.enabled, isTrue);
      expect(prefs.getBool('adhan_enabled'), isTrue);
    });

    test('stays off when permission is refused', () async {
      final cubit = AdhanCubit(
        await _prefs(),
        requestPermission: () async => false,
      );
      expect(await cubit.setEnabled(true), isFalse);
      expect(cubit.state.enabled, isFalse);
    });

    test('turning off never asks', () async {
      var asked = 0;
      final cubit = AdhanCubit(
        await _prefs({'adhan_enabled': true}),
        requestPermission: () async {
          asked++;
          return true;
        },
      );
      expect(await cubit.setEnabled(false), isTrue);
      expect(asked, 0);
      expect(cubit.state.enabled, isFalse);
    });

    test('per-prayer toggles are saved in prayer order', () async {
      final prefs = await _prefs();
      final cubit = AdhanCubit(prefs, requestPermission: () async => true);
      await cubit.togglePrayer('asr');
      expect(cubit.state.prayers, ['fajr', 'dhuhr', 'maghrib', 'isha']);
      expect(
        AdhanCubit(prefs, requestPermission: () async => true).state.prayers,
        ['fajr', 'dhuhr', 'maghrib', 'isha'],
      );
    });
  });
}
