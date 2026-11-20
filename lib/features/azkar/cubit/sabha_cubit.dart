import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_guide/features/azkar/cubit/azkar_progress_cubit.dart';

@immutable
class SabhaState {
  const SabhaState({required this.index, this.finishedCount = 0});

  /// The zikr on screen.
  final int index;

  /// Goes up each time a tap finishes a zikr and the sabha moves on, so
  /// the screen can show «تمّ ✓ — الذكر التالي».
  final int finishedCount;
}

/// One zikr at a time. Counting goes through the section's
/// [AzkarProgressCubit]; this cubit only decides which zikr is shown.
class SabhaCubit extends Cubit<SabhaState> {
  SabhaCubit(this._progress)
    : super(
        SabhaState(
          index: firstOpen(_progress.state.remaining ?? const []) ?? 0,
        ),
      );

  final AzkarProgressCubit _progress;

  int get _length => _progress.state.defaults.length;

  /// Counts one repetition of the zikr on screen. When that finishes it,
  /// moves to the next unfinished zikr. Returns true if a zikr finished.
  bool increment() {
    final finished = _progress.count(state.index);
    if (!finished) return false;
    final next = nextOpen(_progress.state.remaining!, state.index);
    if (next != null) {
      emit(SabhaState(index: next, finishedCount: state.finishedCount + 1));
    }
    return true;
  }

  /// Shows the previous (-1) or next (+1) zikr.
  void go(int delta) {
    final i = state.index + delta;
    if (i < 0 || i >= _length) return;
    emit(SabhaState(index: i, finishedCount: state.finishedCount));
  }

  void resetCurrent() => _progress.reset(state.index);

  /// Starts the whole section again from the first zikr.
  void restartAll() {
    _progress.resetAll();
    emit(SabhaState(index: 0, finishedCount: state.finishedCount));
  }

  /// The first zikr with repetitions left, or null when all are done.
  static int? firstOpen(List<int> remaining) {
    for (var i = 0; i < remaining.length; i++) {
      if (remaining[i] > 0) return i;
    }
    return null;
  }

  /// The next unfinished zikr after [from], wrapping around; null if none.
  static int? nextOpen(List<int> remaining, int from) {
    for (var k = 1; k <= remaining.length; k++) {
      final i = (from + k) % remaining.length;
      if (remaining[i] > 0) return i;
    }
    return null;
  }
}
