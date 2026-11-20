import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_guide/features/about/data/release_info.dart';
import 'package:my_guide/features/about/data/release_source.dart';

@immutable
class AppVersionState {
  const AppVersionState({
    required this.version,
    required this.buildNumber,
    required this.isNew,
    this.update,
    this.announceUpdate = false,
  });

  /// `1.0.0` from `version: 1.0.0+1` in pubspec.yaml.
  final String version;

  /// `1` from `version: 1.0.0+1`.
  final String buildNumber;

  /// The user is on a version they haven't looked at yet: it was updated
  /// since they last opened «عن التطبيق». The home badge turns bright.
  final bool isNew;

  /// A newer version published on Drive, not installed yet; null when the
  /// installed one is the latest (or it couldn't be checked).
  final ReleaseInfo? update;

  /// [update] hasn't been announced to the user yet: home shows a message
  /// once per new version.
  final bool announceUpdate;

  /// `1.0.0+1`: what's saved, so a build-number-only release counts too.
  String get full => buildNumber.isEmpty ? version : '$version+$buildNumber';

  AppVersionState copyWith({
    bool? isNew,
    ReleaseInfo? Function()? update,
    bool? announceUpdate,
  }) => AppVersionState(
    version: version,
    buildNumber: buildNumber,
    isNew: isNew ?? this.isNew,
    update: update != null ? update() : this.update,
    announceUpdate: announceUpdate ?? this.announceUpdate,
  );
}

/// The installed version, whether it's new to the user, and whether a
/// newer one is published.
///
/// The cycle:
/// 1. A new APK and `latest.json` are put on Drive.
/// 2. [checkForUpdate] (on every launch) finds a version newer than the
///    installed one: the badge says «تحديث», home announces it once, and
///    «عن التطبيق» shows its notes with a download button.
/// 3. The user installs it: no newer version any more, and the badge turns
///    gold «جديد» ([AppVersionState.isNew]) until «عن التطبيق» is opened.
class AppVersionCubit extends Cubit<AppVersionState> {
  AppVersionCubit(
    this._prefs, {
    required String version,
    required String buildNumber,
  }) : super(_initial(_prefs, version, buildNumber));

  final SharedPreferences _prefs;
  static const _seenKey = 'app_version_seen';

  /// The last `latest.json` read, so a known update still shows offline.
  static const _latestKey = 'latest_release';

  /// The update (`version+build`) home already announced.
  static const _announcedKey = 'update_announced';

  static AppVersionState _initial(
    SharedPreferences prefs,
    String version,
    String buildNumber,
  ) {
    final installed = AppVersionState(
      version: version,
      buildNumber: buildNumber,
      isNew: false,
    );
    final seen = prefs.getString(_seenKey);
    final bool isNew;
    if (seen == null) {
      // Nothing saved by this feature yet. If the app saved anything else
      // (theme, city, adhan, azkar progress), this is an update from a
      // build made before the badge existed: announce it. Otherwise it's a
      // first install: nothing to announce, and this version is remembered
      // so the next update is the one that lights up.
      isNew = prefs.getKeys().isNotEmpty;
      if (!isNew) prefs.setString(_seenKey, installed.full);
    } else {
      isNew = seen != installed.full;
    }
    return _withUpdate(
      prefs,
      installed.copyWith(isNew: isNew),
      _cached(prefs),
    );
  }

  static ReleaseInfo? _cached(SharedPreferences prefs) {
    final saved = prefs.getString(_latestKey);
    if (saved == null) return null;
    try {
      return ReleaseInfo.fromJson(jsonDecode(saved));
    } catch (_) {
      return null;
    }
  }

  static String _key(ReleaseInfo r) => '${r.version}+${r.build}';

  /// [state] with [latest] as its update when it's newer than what's
  /// installed.
  static AppVersionState _withUpdate(
    SharedPreferences prefs,
    AppVersionState state,
    ReleaseInfo? latest,
  ) {
    final update =
        latest != null && latest.isNewerThan(state.version, state.buildNumber)
        ? latest
        : null;
    return state.copyWith(
      update: () => update,
      announceUpdate:
          update != null && prefs.getString(_announcedKey) != _key(update),
    );
  }

  /// Reads the latest published version from [source]. Keeps the last
  /// known one when it can't be read (offline).
  Future<void> checkForUpdate(ReleaseSource source) async {
    final latest = await source.latest();
    if (latest == null || isClosed) return;
    await _prefs.setString(_latestKey, jsonEncode(latest.toJson()));
    if (!isClosed) emit(_withUpdate(_prefs, state, latest));
  }

  /// Home showed the update message: don't show it again for this version.
  Future<void> markUpdateAnnounced() async {
    final update = state.update;
    if (update == null || !state.announceUpdate) return;
    emit(state.copyWith(announceUpdate: false));
    await _prefs.setString(_announcedKey, _key(update));
  }

  /// The user opened «عن التطبيق»: the «جديد» badge goes back to normal.
  Future<void> markSeen() async {
    if (!state.isNew) return;
    emit(state.copyWith(isNew: false));
    await _prefs.setString(_seenKey, state.full);
  }
}
