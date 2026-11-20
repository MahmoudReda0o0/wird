import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/core/notifications/notification_ids.dart';
import 'package:my_guide/features/adhan/data/adhan_plan.dart';

void main() {
  group('NotificationIds', () {
    test('ranges never overlap', () {
      const ranges = [NotificationIds.legacyAdhan, NotificationIds.adhan];
      for (var i = 0; i < ranges.length; i++) {
        for (var j = i + 1; j < ranges.length; j++) {
          final a = ranges[i], b = ranges[j];
          expect(a.end <= b.start || b.end <= a.start, isTrue);
        }
      }
    });

    test('every adhan id fits in the adhan range', () {
      // AdhanPlan ids are day × 10 + row (0–5).
      final largest = (AdhanPlan.days - 1) * 10 + 5;
      expect(NotificationIds.adhan.contains(NotificationIds.adhan.id(0)), isTrue);
      expect(
        NotificationIds.adhan.contains(NotificationIds.adhan.id(largest)),
        isTrue,
      );
      expect(NotificationIds.legacyAdhan.contains(largest), isTrue);
    });

    test('contains is start-inclusive and end-exclusive', () {
      const r = NotificationIdRange(10, 20);
      expect(r.contains(10), isTrue);
      expect(r.contains(19), isTrue);
      expect(r.contains(20), isFalse);
      expect(r.contains(9), isFalse);
    });
  });
}
