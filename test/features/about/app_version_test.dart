import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  group('AppVersionCubit', () {
    test('first install is not "new", and is remembered', () async {
      final prefs = await _prefs();
      final cubit = AppVersionCubit(prefs, version: '1.0.0', buildNumber: '1');
      expect(cubit.state.isNew, isFalse);
      expect(prefs.getString('app_version_seen'), '1.0.0+1');
    });

    test('an update from a build before the badge is new', () async {
      // The user has used the app (a saved city), but no version is saved.
      final prefs = await _prefs({'prayer_city': 'cairo'});
      final cubit = AppVersionCubit(prefs, version: '1.1.0', buildNumber: '2');
      expect(cubit.state.isNew, isTrue);

      await cubit.markSeen();
      expect(prefs.getString('app_version_seen'), '1.1.0+2');
      final again = AppVersionCubit(prefs, version: '1.1.0', buildNumber: '2');
      expect(again.state.isNew, isFalse);
    });

    test('same version as last seen is not new', () async {
      final prefs = await _prefs({'app_version_seen': '1.0.0+1'});
      final cubit = AppVersionCubit(prefs, version: '1.0.0', buildNumber: '1');
      expect(cubit.state.isNew, isFalse);
    });

    test('an update is new until «عن التطبيق» is opened', () async {
      final prefs = await _prefs({'app_version_seen': '1.0.0+1'});
      final cubit = AppVersionCubit(prefs, version: '1.1.0', buildNumber: '2');
      expect(cubit.state.isNew, isTrue);

      await cubit.markSeen();
      expect(cubit.state.isNew, isFalse);
      expect(prefs.getString('app_version_seen'), '1.1.0+2');

      // Next launch on the same version: stays normal.
      final again = AppVersionCubit(prefs, version: '1.1.0', buildNumber: '2');
      expect(again.state.isNew, isFalse);
    });

    test('a build-number-only release counts as new', () async {
      final prefs = await _prefs({'app_version_seen': '1.0.0+1'});
      final cubit = AppVersionCubit(prefs, version: '1.0.0', buildNumber: '2');
      expect(cubit.state.isNew, isTrue);
    });

    test('full joins version and build number', () async {
      final prefs = await _prefs();
      expect(
        AppVersionCubit(prefs, version: '2.0.0', buildNumber: '').state.full,
        '2.0.0',
      );
    });
  });
}
