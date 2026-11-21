import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/app/background_refresh.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';
import 'package:my_guide/features/about/cubit/update_checker.dart';
import 'package:my_guide/features/about/data/release_info.dart';
import 'package:my_guide/features/about/data/release_source.dart';

import '../../helpers/fake_release_source.dart';
import '../../helpers/test_app.dart';

const _release = ReleaseInfo(version: '1.1.0', build: 3, notes: ['جديد']);

/// The latest release as the network would answer it: null while offline.
class _Network implements ReleaseSource {
  ReleaseInfo? online;
  int reads = 0;

  @override
  Future<ReleaseInfo?> latest() async {
    reads++;
    return online;
  }
}

void main() {
  group('UpdateChecker', () {
    testWidgets('offline at launch: finds the new version once online', (
      tester,
    ) async {
      final prefs = await mockPrefs({'app_version_seen': '1.0.0+2'});
      final cubit = AppVersionCubit(prefs, version: '1.0.0', buildNumber: '2');
      final network = _Network();
      final checker = UpdateChecker(cubit, network);

      await checker.check();
      expect(cubit.state.update, isNull);
      expect(checker.isRetrying, isTrue);

      // Still offline at the first retry: keeps trying.
      await tester.pump(const Duration(minutes: 2));
      expect(network.reads, 2);
      expect(checker.isRetrying, isTrue);

      network.online = _release;
      await tester.pump(const Duration(minutes: 2));
      expect(network.reads, 3);
      expect(cubit.state.update?.version, '1.1.0');
      expect(cubit.state.announceUpdate, isTrue);
      expect(checker.isRetrying, isFalse);

      checker.dispose();
      await cubit.close();
    });

    testWidgets('no retries in the background; checks again on resume', (
      tester,
    ) async {
      final prefs = await mockPrefs({'app_version_seen': '1.0.0+2'});
      final cubit = AppVersionCubit(prefs, version: '1.0.0', buildNumber: '2');
      final network = _Network();
      final checker = UpdateChecker(cubit, network);

      await checker.check();
      checker.onPause();
      await tester.pump(const Duration(minutes: 30));
      expect(network.reads, 1);

      network.online = _release;
      checker.onResume();
      await tester.pump();
      expect(network.reads, 2);
      expect(cubit.state.update?.version, '1.1.0');

      checker.dispose();
      await cubit.close();
    });

    testWidgets('on resume, a recent good check is enough', (tester) async {
      final prefs = await mockPrefs({'app_version_seen': '1.0.0+2'});
      final cubit = AppVersionCubit(prefs, version: '1.0.0', buildNumber: '2');
      final network = _Network()..online = _release;
      var now = DateTime(2026, 11, 21, 10);
      final checker = UpdateChecker(cubit, network, now: () => now);

      await checker.check();
      expect(network.reads, 1);

      now = now.add(const Duration(minutes: 10));
      checker.onResume();
      await tester.pump();
      expect(network.reads, 1);

      now = now.add(const Duration(minutes: 25));
      checker.onResume();
      await tester.pump();
      expect(network.reads, 2);

      checker.dispose();
      await cubit.close();
    });
  });

  group('BackgroundRefresh.checkForUpdate', () {
    test('notifies once per new version', () async {
      final prefs = await mockPrefs({'app_version_seen': '1.0.0+2'});
      final notified = <String>[];
      Future<bool> run(ReleaseInfo? latest) =>
          BackgroundRefresh.checkForUpdate(
            prefs,
            version: '1.0.0',
            buildNumber: '2',
            source: FakeReleaseSource(latest),
            notify: (u) async => notified.add('${u.version}+${u.build}'),
          );

      expect(await run(null), isFalse, reason: 'offline: try again later');
      expect(notified, isEmpty);

      expect(await run(_release), isTrue);
      expect(await run(_release), isTrue);
      expect(notified, ['1.1.0+3']);

      const next = ReleaseInfo(version: '1.2.0', build: 4, notes: []);
      expect(await run(next), isTrue);
      expect(notified, ['1.1.0+3', '1.2.0+4']);
    });

    test('nothing newer: no notification', () async {
      final prefs = await mockPrefs({'app_version_seen': '1.1.0+3'});
      var notified = false;
      final ok = await BackgroundRefresh.checkForUpdate(
        prefs,
        version: '1.1.0',
        buildNumber: '3',
        source: const FakeReleaseSource(_release),
        notify: (_) async => notified = true,
      );
      expect(ok, isTrue);
      expect(notified, isFalse);
    });
  });
}
