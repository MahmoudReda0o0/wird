import 'dart:async';

import 'package:my_guide/features/about/cubit/app_version_cubit.dart';
import 'package:my_guide/features/about/data/release_source.dart';

/// Keeps [AppVersionCubit] up to date while the app is open, so a new
/// version shows up as soon as the phone has internet:
///
/// * [check] on launch.
/// * [onResume]: checks again when the app comes back, if the last good
///   check is older than [freshFor] (or there wasn't one).
/// * While a check fails (offline), tries again every [retryEvery] until
///   one works or the app goes to the background ([onPause]).
///
/// The app root owns one and forwards the lifecycle to it.
class UpdateChecker {
  UpdateChecker(
    this._cubit,
    this._source, {
    this.retryEvery = const Duration(minutes: 2),
    this.freshFor = const Duration(minutes: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppVersionCubit _cubit;
  final ReleaseSource _source;
  final Duration retryEvery;
  final Duration freshFor;
  final DateTime Function() _now;

  DateTime? _lastSuccess;
  Timer? _retry;
  bool _checking = false;
  bool _foreground = true;

  /// Whether a failed check is waiting to be tried again.
  bool get isRetrying => _retry != null;

  /// Reads the latest version now. One check at a time.
  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    _retry?.cancel();
    _retry = null;
    final ok = await _cubit.checkForUpdate(_source);
    _checking = false;
    if (ok) {
      _lastSuccess = _now();
    } else if (_foreground && !_cubit.isClosed) {
      _retry = Timer(retryEvery, () {
        _retry = null;
        unawaited(check());
      });
    }
  }

  /// The app is back in the foreground.
  void onResume() {
    _foreground = true;
    final last = _lastSuccess;
    if (last == null || _now().difference(last) >= freshFor) {
      unawaited(check());
    }
  }

  /// The app went to the background: no retries until it's back.
  void onPause() {
    _foreground = false;
    _retry?.cancel();
    _retry = null;
  }

  void dispose() => onPause();
}
