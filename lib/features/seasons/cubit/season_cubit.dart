import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/core/time/app_clock.dart';
import 'package:my_guide/features/seasons/data/season_store.dart';
import 'package:my_guide/features/seasons/data/season_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the seasonal themes mean today.
@immutable
class SeasonState {
  const SeasonState({
    this.active,
    this.upcoming,
    this.daysLeft = 0,
    this.images = const {},
    this.noteSeen = true,
    this.hijriOffset = 0,
  });

  /// The theme that's on today (the highest priority one), if any.
  final SeasonTheme? active;

  /// The theme home counts down to today, if any.
  final SeasonTheme? upcoming;

  /// Days until [upcoming] starts.
  final int daysLeft;

  /// The saved images, by bucket path.
  final Map<String, ImageProvider> images;

  /// Whether [active]'s note dialog was already shown.
  final bool noteSeen;

  /// Days added to the Hijri date (`app_config.hijri_offset`).
  final int hijriOffset;

  ImageProvider? image(String? path) => path == null ? null : images[path];

  /// Whether the dialog should show now.
  bool get showNote => active != null && active!.hasNote && !noteSeen;
}

/// The seasonal theme of the day, from what's saved on the phone
/// ([SeasonStore]). [refresh] updates it from Supabase when there's
/// internet; [recompute] moves to a new day.
class SeasonCubit extends Cubit<SeasonState> {
  SeasonCubit(this._prefs, {DateTime Function()? now})
    : _now = now ?? AppClock.now,
      super(const SeasonState()) {
    _load();
  }

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  DateTime? _lastRefresh;
  Map<String, ImageProvider> _images = const {};

  DateTime get _today => SeasonTheme.day(_now());

  /// Reads Supabase (at most every [every]) and applies what's new.
  Future<void> refresh({Duration every = const Duration(minutes: 30)}) async {
    final last = _lastRefresh;
    if (last != null && _now().difference(last) < every) {
      recompute();
      return;
    }
    if (await SeasonStore.refresh(_prefs, _today)) _lastRefresh = _now();
    if (!isClosed) _load();
  }

  /// Picks today's theme again (the day may have changed).
  void recompute() {
    if (!isClosed) emit(_pick(SeasonStore.readThemes(_prefs)));
  }

  /// The note dialog was shown for the active theme.
  Future<void> markNoteSeen() async {
    final active = state.active;
    if (active == null) return;
    await SeasonStore.markNoteSeen(_prefs, active.slug);
    recompute();
  }

  void _load() {
    unawaited(SeasonStore.prune(_prefs, _today));
    _images = {
      for (final e in SeasonStore.readImages(_prefs).entries)
        e.key: MemoryImage(e.value),
    };
    recompute();
  }

  SeasonState _pick(List<SeasonTheme> themes) {
    final today = _today;
    SeasonTheme? active;
    SeasonTheme? upcoming;
    for (final t in themes) {
      if (t.isOn(today) && (active == null || t.priority > active.priority)) {
        active = t;
      }
      if (t.isCountingDown(today) &&
          (upcoming == null || t.startsOn.isBefore(upcoming.startsOn))) {
        upcoming = t;
      }
    }
    return SeasonState(
      active: active,
      upcoming: upcoming,
      daysLeft: upcoming?.daysUntil(today) ?? 0,
      images: _images,
      noteSeen: active == null || SeasonStore.noteSeen(_prefs, active.slug),
      hijriOffset: SeasonStore.hijriOffset(_prefs),
    );
  }
}
