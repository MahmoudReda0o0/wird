import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The app's time. Everything runs on Egypt's time (Africa/Cairo), whatever
/// the phone's own time zone is, so the prayer times, the date on home and
/// the day the azkar progress belongs to always agree.
class AppClock {
  AppClock._();

  static tz.Location? _cairo;

  /// Africa/Cairo. Loads the time-zone database on first use.
  static tz.Location get cairo {
    if (_cairo == null) {
      tz_data.initializeTimeZones();
      _cairo = tz.getLocation('Africa/Cairo');
    }
    return _cairo!;
  }

  /// The current time in Cairo.
  static tz.TZDateTime now() => tz.TZDateTime.now(cairo);
}
