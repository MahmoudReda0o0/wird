import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/feature/screen/azkar/sabha_screen.dart';

void main() {
  group('SabhaLogic.count', () {
    test('counts down and stays on the zikr until it is finished', () {
      final remaining = [3, 1];
      final step = SabhaLogic.count(remaining, 0);
      expect(remaining, [2, 1]);
      expect(step!.finishedZikr, isFalse);
    });

    test('finishing a zikr moves to the next unfinished one', () {
      final remaining = [1, 0, 5];
      final step = SabhaLogic.count(remaining, 0)!;
      expect(remaining, [0, 0, 5]);
      expect(step.finishedZikr, isTrue);
      expect(step.nextIndex, 2); // skips the finished one in between
    });

    test('wraps around to earlier unfinished azkar', () {
      final remaining = [2, 0, 1];
      final step = SabhaLogic.count(remaining, 2)!;
      expect(step.finishedZikr, isTrue);
      expect(step.nextIndex, 0);
    });

    test('finishing the last open zikr finishes the section', () {
      final remaining = [0, 1, 0];
      final step = SabhaLogic.count(remaining, 1)!;
      expect(step.finishedZikr, isTrue);
      expect(step.nextIndex, isNull);
      expect(remaining.every((r) => r == 0), isTrue);
    });

    test('a finished zikr does not count below zero', () {
      final remaining = [0, 3];
      expect(SabhaLogic.count(remaining, 0), isNull);
      expect(remaining, [0, 3]);
    });
  });

  group('SabhaLogic.firstOpen', () {
    test('starts at the first unfinished zikr', () {
      expect(SabhaLogic.firstOpen([0, 0, 4, 1]), 2);
    });

    test('is null when everything is done', () {
      expect(SabhaLogic.firstOpen([0, 0]), isNull);
    });
  });
}
