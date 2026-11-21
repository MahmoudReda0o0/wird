import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/qibla/data/sun_position.dart';

void main() {
  test('sun over Mansoura at 2 PM Cairo, 21 Nov 2026', () {
    final p = SunPosition.at(31.04673, 31.40337, DateTime.utc(2026, 11, 21, 12));
    expect(p.azimuth, closeTo(218, 1.5));
    expect(p.altitude, closeTo(28.9, 1.5));
    expect(p.isUp, isTrue);
  });

  test('sun is down at midnight', () {
    final p = SunPosition.at(31.04673, 31.40337, DateTime.utc(2026, 11, 21, 22));
    expect(p.isUp, isFalse);
  });

  test('a non-UTC time is treated as the same instant', () {
    final utc = DateTime.utc(2026, 11, 21, 12);
    final a = SunPosition.at(30, 31, utc);
    final b = SunPosition.at(30, 31, utc.toLocal());
    expect(b.azimuth, closeTo(a.azimuth, 1e-9));
  });

  test('the sun passes over the Kaaba in late May and mid July', () {
    final t = SunPosition.kaabaTransits(2027);
    expect(t, hasLength(2));
    expect(t[0].isUtc, isTrue);
    expect(t[0].month, 5);
    expect(t[0].day, inInclusiveRange(27, 28));
    expect(t[1].month, 7);
    expect(t[1].day, inInclusiveRange(15, 16));
    // Makkah is UTC+3: about 12:18 and 12:27 there.
    expect(t[0].hour, 9);
    expect(t[0].minute, inInclusiveRange(14, 22));
    expect(t[1].hour, 9);
    expect(t[1].minute, inInclusiveRange(23, 31));
  });
}
