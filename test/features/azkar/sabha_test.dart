import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/azkar/cubit/azkar_progress_cubit.dart';
import 'package:my_guide/features/azkar/cubit/sabha_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _day = DateTime(2026, 11, 19, 8);

Future<AzkarProgressCubit> _section(List<int> defaults) async {
  final cubit = AzkarProgressCubit(
    sectionId: 'test',
    defaults: defaults,
    clock: () => _day,
  );
  await cubit.load();
  return cubit;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AzkarProgressCubit', () {
    test('loads full counts on a new day', () async {
      final cubit = await _section([3, 1]);
      expect(cubit.state.remaining, [3, 1]);
      expect(cubit.state.hasProgress, isFalse);
    });

    test('count goes down and reports when a zikr is finished', () async {
      final cubit = await _section([2, 1]);
      expect(cubit.count(0), isFalse);
      expect(cubit.count(0), isTrue);
      expect(cubit.state.remaining, [0, 1]);
      expect(cubit.state.doneCount, 1);
      expect(cubit.state.countedOf(0), 2);
      // Already finished: nothing changes.
      expect(cubit.count(0), isFalse);
      expect(cubit.state.remaining, [0, 1]);
    });

    test('progress is saved and restored the same day', () async {
      final first = await _section([3, 1]);
      first.count(0);
      await Future<void>.delayed(Duration.zero); // let the save finish
      final again = await _section([3, 1]);
      expect(again.state.remaining, [2, 1]);
    });

    test('reset one zikr or the whole section', () async {
      final cubit = await _section([3, 2]);
      cubit.count(0);
      cubit.count(1);
      cubit.reset(0);
      expect(cubit.state.remaining, [3, 1]);
      cubit.resetAll();
      expect(cubit.state.remaining, [3, 2]);
      expect(cubit.state.hasProgress, isFalse);
    });
  });

  group('SabhaCubit', () {
    test('starts at the first unfinished zikr', () async {
      final progress = await _section([1, 2, 3]);
      progress.count(0);
      expect(SabhaCubit(progress).state.index, 1);
    });

    test('stays on a zikr until its count is done', () async {
      final progress = await _section([3, 1]);
      final sabha = SabhaCubit(progress);
      expect(sabha.increment(), isFalse);
      expect(sabha.state.index, 0);
      expect(progress.state.remaining, [2, 1]);
    });

    test('finishing a zikr moves on, skipping finished ones', () async {
      final progress = await _section([1, 1, 2]);
      progress.count(1); // finish the middle one first
      final sabha = SabhaCubit(progress);
      expect(sabha.increment(), isTrue);
      expect(sabha.state.index, 2);
      expect(sabha.state.finishedCount, 1);
    });

    test('wraps around to earlier unfinished azkar', () async {
      final progress = await _section([2, 1]);
      final sabha = SabhaCubit(progress)..go(1);
      expect(sabha.increment(), isTrue);
      expect(sabha.state.index, 0);
    });

    test('finishing the last one finishes the section', () async {
      final progress = await _section([1]);
      final sabha = SabhaCubit(progress);
      expect(sabha.increment(), isTrue);
      expect(progress.state.allDone, isTrue);
      expect(sabha.state.finishedCount, 0); // nowhere to move on to
    });

    test('arrows stay inside the section', () async {
      final progress = await _section([1, 1]);
      final sabha = SabhaCubit(progress);
      sabha.go(-1);
      expect(sabha.state.index, 0);
      sabha.go(1);
      sabha.go(1);
      expect(sabha.state.index, 1);
    });

    test('restart all goes back to the first zikr with full counts', () async {
      final progress = await _section([1, 1]);
      final sabha = SabhaCubit(progress);
      sabha.increment();
      sabha.increment();
      sabha.restartAll();
      expect(sabha.state.index, 0);
      expect(progress.state.remaining, [1, 1]);
    });
  });

  group('SabhaCubit helpers', () {
    test('firstOpen and nextOpen', () {
      expect(SabhaCubit.firstOpen([0, 0, 4, 1]), 2);
      expect(SabhaCubit.firstOpen([0, 0]), isNull);
      expect(SabhaCubit.nextOpen([1, 0, 5], 0), 2);
      expect(SabhaCubit.nextOpen([2, 0, 0], 2), 0);
      expect(SabhaCubit.nextOpen([0, 0], 1), isNull);
    });
  });
}
