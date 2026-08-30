import 'dart:developer';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'dart:developer';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class PrayTimingData {
  bool loading = false;

  late tz.Location location;

  DateTime date = DateTime.now();

  final Coordinates coordinates =
      const Coordinates(31.046730, 31.403370);

  final CalculationParameters params =
      CalculationMethodParameters.muslimWorldLeague()
        ..madhab = Madhab.hanafi;

  PrayerTimes? prayerTimes;

  DateTime? fajrTime;
  DateTime? sunriseTime;
  DateTime? dhuhrTime;
  DateTime? asrTime;
  DateTime? maghribTime;
  DateTime? ishaTime;

  // =========================
  // Initialization
  // =========================

  void init() {
    loading = true;

    // Initialize timezone database
    tz_data.initializeTimeZones();

    // Egypt timezone
    location = tz.getLocation('Africa/Cairo');

    getPrayerTime();

    loading = false;
  }

  // =========================
  // Get Prayer Times
  // =========================

  void getPrayerTime() {
    prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: date,
      calculationParameters: params,
      precision: true,
    );

    fajrTime = tz.TZDateTime.from(
      prayerTimes!.fajr,
      location,
    );

    sunriseTime = tz.TZDateTime.from(
      prayerTimes!.sunrise,
      location,
    );

    dhuhrTime = tz.TZDateTime.from(
      prayerTimes!.dhuhr,
      location,
    );

    asrTime = tz.TZDateTime.from(
      prayerTimes!.asr,
      location,
    );

    maghribTime = tz.TZDateTime.from(
      prayerTimes!.maghrib,
      location,
    );

    ishaTime = tz.TZDateTime.from(
      prayerTimes!.isha,
      location,
    );

    log('Fajr: ${formatPrayerTime(fajrTime!)}');
    log('Sunrise: ${formatPrayerTime(sunriseTime!)}');
    log('Dhuhr: ${formatPrayerTime(dhuhrTime!)}');
    log('Asr: ${formatPrayerTime(asrTime!)}');
    log('Maghrib: ${formatPrayerTime(maghribTime!)}');
    log('Isha: ${formatPrayerTime(ishaTime!)}');
  }

  // =========================
  // Format Time
  // =========================

  String formatPrayerTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.hour >= 12 ? 'م' : 'ص';

    return '$hour:$minute $period';
  }

  // =========================
  // Formatted Prayer Times
  // =========================

  String get fajrTimeFormatted =>
      formatPrayerTime(fajrTime!);

  String get sunriseTimeFormatted =>
      formatPrayerTime(sunriseTime!);

  String get dhuhrTimeFormatted =>
      formatPrayerTime(dhuhrTime!);

  String get asrTimeFormatted =>
      formatPrayerTime(asrTime!);

  String get maghribTimeFormatted =>
      formatPrayerTime(maghribTime!);

  String get ishaTimeFormatted =>
      formatPrayerTime(ishaTime!);
}