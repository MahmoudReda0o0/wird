import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/qibla/data/qibla_math.dart';

void main() {
  group('bearingToKaaba', () {
    test('matches known bearings for Egyptian cities', () {
      expect(QiblaMath.bearingToKaaba(31.04673, 31.40337), closeTo(139.9, 0.2));
      expect(QiblaMath.bearingToKaaba(30.0444, 31.2357), closeTo(136.1, 0.2));
      expect(QiblaMath.bearingToKaaba(24.0889, 32.8998), closeTo(111.3, 0.2));
    });

    test('every city points south-east, within 100–150°', () {
      for (final c in PrayerCity.all) {
        expect(
          QiblaMath.bearingToKaaba(c.latitude, c.longitude),
          inInclusiveRange(100, 150),
          reason: c.id,
        );
      }
    });
  });

  group('signedDelta', () {
    test('takes the short way across north', () {
      expect(QiblaMath.signedDelta(359, 1), closeTo(2, 1e-9));
      expect(QiblaMath.signedDelta(1, 359), closeTo(-2, 1e-9));
    });

    test('is half-open: opposite directions give +180', () {
      expect(QiblaMath.signedDelta(100, 280), 180);
      expect(QiblaMath.signedDelta(280, 100), 180);
    });

    test('positive means turn clockwise', () {
      expect(QiblaMath.signedDelta(100, 139.9), closeTo(39.9, 1e-9));
    });
  });

  test('compassPoint names the eight directions in Arabic', () {
    expect(QiblaMath.compassPoint(0), 'شمال');
    expect(QiblaMath.compassPoint(359), 'شمال');
    expect(QiblaMath.compassPoint(45), 'شمال شرق');
    expect(QiblaMath.compassPoint(90), 'شرق');
    expect(QiblaMath.compassPoint(140), 'جنوب شرق');
    expect(QiblaMath.compassPoint(180), 'جنوب');
    expect(QiblaMath.compassPoint(225), 'جنوب غرب');
    expect(QiblaMath.compassPoint(270), 'غرب');
    expect(QiblaMath.compassPoint(315), 'شمال غرب');
  });

  test('isAligned within 3° either way', () {
    expect(QiblaMath.isAligned(3), isTrue);
    expect(QiblaMath.isAligned(-3), isTrue);
    expect(QiblaMath.isAligned(-3.1), isFalse);
  });
}
