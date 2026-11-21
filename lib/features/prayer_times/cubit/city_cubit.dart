import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_guide/features/prayer_times/data/prayer_city.dart';

/// The city the prayer times are calculated for. Saved like the theme.
class CityCubit extends Cubit<PrayerCity> {
  CityCubit(this._prefs) : super(readSaved(_prefs));

  final SharedPreferences _prefs;
  static const _prefsKey = 'prayer_city';

  /// The saved city (Mansoura if none). Also read by the background task,
  /// which has no cubit.
  static PrayerCity readSaved(SharedPreferences prefs) =>
      PrayerCity.byId(prefs.getString(_prefsKey));

  Future<void> select(PrayerCity city) async {
    emit(city);
    await _prefs.setString(_prefsKey, city.id);
  }
}
