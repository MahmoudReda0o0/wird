import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_guide/feature/screen/prayer_timing/prayer_city.dart';

/// The city the prayer times are calculated for. Saved like the theme.
class CityCubit extends Cubit<PrayerCity> {
  CityCubit(this._prefs) : super(PrayerCity.byId(_prefs.getString(_prefsKey)));

  final SharedPreferences _prefs;
  static const _prefsKey = 'prayer_city';

  Future<void> select(PrayerCity city) async {
    emit(city);
    await _prefs.setString(_prefsKey, city.id);
  }
}
