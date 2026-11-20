import 'package:flutter/foundation.dart';

/// A city the prayer times can be calculated for.
@immutable
class PrayerCity {
  const PrayerCity(this.id, this.name, this.latitude, this.longitude);

  /// Stable key saved in preferences. Never change an existing one.
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  /// Egyptian governorate capitals and a few large cities.
  /// All of them use the Africa/Cairo time zone.
  static const all = <PrayerCity>[
    PrayerCity('mansoura', 'المنصورة', 31.046730, 31.403370),
    PrayerCity('cairo', 'القاهرة', 30.0444, 31.2357),
    PrayerCity('giza', 'الجيزة', 30.0131, 31.2089),
    PrayerCity('alexandria', 'الإسكندرية', 31.2001, 29.9187),
    PrayerCity('tanta', 'طنطا', 30.7865, 31.0004),
    PrayerCity('zagazig', 'الزقازيق', 30.5877, 31.5020),
    PrayerCity('benha', 'بنها', 30.4660, 31.1848),
    PrayerCity('shebin', 'شبين الكوم', 30.5596, 31.0109),
    PrayerCity('damanhour', 'دمنهور', 31.0341, 30.4682),
    PrayerCity('kafr_elsheikh', 'كفر الشيخ', 31.1107, 30.9388),
    PrayerCity('damietta', 'دمياط', 31.4165, 31.8133),
    PrayerCity('port_said', 'بورسعيد', 31.2653, 32.3019),
    PrayerCity('ismailia', 'الإسماعيلية', 30.5965, 32.2715),
    PrayerCity('suez', 'السويس', 29.9668, 32.5498),
    PrayerCity('fayoum', 'الفيوم', 29.3084, 30.8428),
    PrayerCity('beni_suef', 'بني سويف', 29.0661, 31.0994),
    PrayerCity('minya', 'المنيا', 28.1099, 30.7503),
    PrayerCity('assiut', 'أسيوط', 27.1783, 31.1859),
    PrayerCity('sohag', 'سوهاج', 26.5591, 31.6957),
    PrayerCity('qena', 'قنا', 26.1551, 32.7160),
    PrayerCity('luxor', 'الأقصر', 25.6872, 32.6396),
    PrayerCity('aswan', 'أسوان', 24.0889, 32.8998),
    PrayerCity('hurghada', 'الغردقة', 27.2579, 33.8116),
    PrayerCity('marsa_matrouh', 'مرسى مطروح', 31.3543, 27.2373),
    PrayerCity('arish', 'العريش', 31.1316, 33.7984),
    PrayerCity('sharm', 'شرم الشيخ', 27.9158, 34.3300),
    PrayerCity('kharga', 'الخارجة', 25.4390, 30.5586),
  ];

  static PrayerCity get fallback => all.first;

  static PrayerCity byId(String? id) =>
      all.firstWhere((c) => c.id == id, orElse: () => fallback);
}
