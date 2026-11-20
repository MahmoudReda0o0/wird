import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_guide/feature/screen/azkar/azkar_progress.dart';

/// Repetitions left for each zikr in one section.
@immutable
class AzkarProgressState {
  const AzkarProgressState({required this.defaults, this.remaining});

  /// Each zikr's full count, in order.
  final List<int> defaults;

  /// Repetitions left per zikr; null until the saved progress is loaded.
  final List<int>? remaining;

  bool get isLoaded => remaining != null;

  int get doneCount => remaining?.where((r) => r <= 0).length ?? 0;

  /// Anything counted at all, so there is something to reset.
  bool get hasProgress {
    final r = remaining;
    if (r == null) return false;
    for (var i = 0; i < r.length; i++) {
      if (r[i] < defaults[i]) return true;
    }
    return false;
  }

  bool get allDone => remaining?.every((r) => r <= 0) ?? false;

  /// Repetitions of zikr [i] counted so far (0 … its full count).
  int countedOf(int i) {
    final left = remaining?[i] ?? defaults[i];
    return (defaults[i] - left).clamp(0, defaults[i]).toInt();
  }
}

/// Counts azkar in one section and saves the progress for the day.
///
/// The azkar page and the sabha share one instance, so both always show
/// the same counts.
class AzkarProgressCubit extends Cubit<AzkarProgressState> {
  AzkarProgressCubit({
    required this.sectionId,
    required List<int> defaults,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(AzkarProgressState(defaults: List.unmodifiable(defaults)));

  final String sectionId;
  final DateTime Function() _clock;

  Future<void> load() async {
    final counts = await AzkarProgress.load(
      sectionId,
      state.defaults,
      now: _clock(),
    );
    if (!isClosed) _update(counts, save: false);
  }

  /// Counts one repetition of zikr [i]. Returns true when that tap
  /// finished the zikr; false if it wasn't finished yet or already was.
  bool count(int i) {
    final r = state.remaining;
    if (r == null || r[i] <= 0) return false;
    final next = List.of(r);
    next[i]--;
    _update(next);
    return next[i] == 0;
  }

  /// Starts zikr [i] again from its full count.
  void reset(int i) {
    final r = state.remaining;
    if (r == null) return;
    final next = List.of(r);
    next[i] = state.defaults[i];
    _update(next);
  }

  /// Starts the whole section again.
  void resetAll() {
    if (state.remaining == null) return;
    _update(List.of(state.defaults));
  }

  void _update(List<int> remaining, {bool save = true}) {
    emit(
      AzkarProgressState(
        defaults: state.defaults,
        remaining: List.unmodifiable(remaining),
      ),
    );
    if (save) AzkarProgress.save(sectionId, remaining, now: _clock());
  }
}
