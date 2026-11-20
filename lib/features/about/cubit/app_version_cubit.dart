import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class AppVersionState {
  const AppVersionState({
    required this.version,
    required this.buildNumber,
    required this.isNew,
  });

  /// `1.0.0` from `version: 1.0.0+1` in pubspec.yaml.
  final String version;

  /// `1` from `version: 1.0.0+1`.
  final String buildNumber;

  /// The user is on a version they haven't looked at yet: it was updated
  /// since they last opened «عن التطبيق». The home badge turns bright.
  final bool isNew;

  /// `1.0.0+1`: what's saved, so a build-number-only release counts too.
  String get full => buildNumber.isEmpty ? version : '$version+$buildNumber';
}

/// The installed version and whether it's new to the user.
class AppVersionCubit extends Cubit<AppVersionState> {
  AppVersionCubit(
    this._prefs, {
    required String version,
    required String buildNumber,
  }) : super(_initial(_prefs, version, buildNumber));

  final SharedPreferences _prefs;
  static const _seenKey = 'app_version_seen';

  static AppVersionState _initial(
    SharedPreferences prefs,
    String version,
    String buildNumber,
  ) {
    final state = AppVersionState(
      version: version,
      buildNumber: buildNumber,
      isNew: false,
    );
    final seen = prefs.getString(_seenKey);
    if (seen == null) {
      // Nothing saved by this feature yet. If the app saved anything else
      // (theme, city, adhan, azkar progress), this is an update from a
      // build made before the badge existed: announce it. Otherwise it's a
      // first install: nothing to announce, and this version is remembered
      // so the next update is the one that lights up.
      if (prefs.getKeys().isNotEmpty) {
        return AppVersionState(
          version: version,
          buildNumber: buildNumber,
          isNew: true,
        );
      }
      prefs.setString(_seenKey, state.full);
      return state;
    }
    return AppVersionState(
      version: version,
      buildNumber: buildNumber,
      isNew: seen != state.full,
    );
  }

  /// The user opened «عن التطبيق»: the badge goes back to normal.
  Future<void> markSeen() async {
    if (!state.isNew) return;
    emit(
      AppVersionState(
        version: state.version,
        buildNumber: state.buildNumber,
        isNew: false,
      ),
    );
    await _prefs.setString(_seenKey, state.full);
  }
}
