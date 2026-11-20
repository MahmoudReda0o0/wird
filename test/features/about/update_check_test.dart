import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';
import 'package:my_guide/features/about/data/release_info.dart';
import 'package:my_guide/features/about/data/release_source.dart';

import '../../helpers/fake_release_source.dart';
import '../../helpers/test_app.dart';

const _release = ReleaseInfo(
  version: '1.1.0',
  build: 2,
  notes: ['تذكير بالأذكار', 'وضع رمضان'],
);

void main() {
  group('ReleaseInfo.fromJson', () {
    test('reads version, build and notes', () {
      final r = ReleaseInfo.fromJson({
        'version': '1.1.0',
        'build': 2,
        'notes': ['أ', '  ', 'ب '],
      })!;
      expect(r.version, '1.1.0');
      expect(r.build, 2);
      expect(r.notes, ['أ', 'ب']);
    });

    test('a build written as text is accepted', () {
      expect(
        ReleaseInfo.fromJson({'version': '1.1.0', 'build': '2'})!.build,
        2,
      );
    });

    test('a broken file is not a release', () {
      expect(ReleaseInfo.fromJson(null), isNull);
      expect(ReleaseInfo.fromJson('1.1.0'), isNull);
      expect(ReleaseInfo.fromJson({'version': '1.1.0'}), isNull);
      expect(ReleaseInfo.fromJson({'version': 'v1.x', 'build': 2}), isNull);
      expect(ReleaseInfo.fromJson({'version': '1.1.0', 'build': -1}), isNull);
    });

    test('survives a round trip through toJson', () {
      final again = ReleaseInfo.fromJson(
        jsonDecode(jsonEncode(_release.toJson())),
      )!;
      expect(again.version, _release.version);
      expect(again.build, _release.build);
      expect(again.notes, _release.notes);
    });
  });

  group('ReleaseInfo.isNewerThan', () {
    ReleaseInfo r(String v, int b) =>
        ReleaseInfo(version: v, build: b, notes: const []);

    test('a higher version is newer', () {
      expect(r('1.1.0', 2).isNewerThan('1.0.0', '1'), isTrue);
      expect(r('1.0.1', 2).isNewerThan('1.0.0', '1'), isTrue);
      expect(r('2.0.0', 1).isNewerThan('1.9.9', '9'), isTrue);
    });

    test('numbers compare as numbers, not text', () {
      expect(r('1.10.0', 1).isNewerThan('1.9.0', '1'), isTrue);
      expect(r('1.9.0', 1).isNewerThan('1.10.0', '1'), isFalse);
    });

    test('same version: a higher build is newer', () {
      expect(r('1.0.0', 2).isNewerThan('1.0.0', '1'), isTrue);
      expect(r('1.0.0', 1).isNewerThan('1.0.0', '1'), isFalse);
    });

    test('the installed one or an older one is not newer', () {
      expect(r('1.0.0', 1).isNewerThan('1.1.0', '2'), isFalse);
      expect(r('1.1', 2).isNewerThan('1.1.0', '2'), isFalse);
    });
  });

  group('AppVersionCubit.checkForUpdate', () {
    test('a newer version on Drive is an update, announced once', () async {
      final prefs = await mockPrefs({'app_version_seen': '1.0.0+1'});
      final cubit = AppVersionCubit(prefs, version: '1.0.0', buildNumber: '1');
      expect(cubit.state.update, isNull);

      await cubit.checkForUpdate(const FakeReleaseSource(_release));
      expect(cubit.state.update?.version, '1.1.0');
      expect(cubit.state.announceUpdate, isTrue);

      await cubit.markUpdateAnnounced();
      expect(cubit.state.announceUpdate, isFalse);
      expect(cubit.state.update, isNotNull, reason: 'still available');

      // Next launch: still an update, but not announced again.
      final again = AppVersionCubit(prefs, version: '1.0.0', buildNumber: '1');
      expect(again.state.update?.version, '1.1.0');
      expect(again.state.announceUpdate, isFalse);
    });

    test('the version on Drive is the installed one: no update', () async {
      final prefs = await mockPrefs({'app_version_seen': '1.1.0+2'});
      final cubit = AppVersionCubit(prefs, version: '1.1.0', buildNumber: '2');
      await cubit.checkForUpdate(const FakeReleaseSource(_release));
      expect(cubit.state.update, isNull);
      expect(cubit.state.announceUpdate, isFalse);
    });

    test('offline, the last known update still shows', () async {
      final prefs = await mockPrefs({'app_version_seen': '1.0.0+1'});
      await AppVersionCubit(
        prefs,
        version: '1.0.0',
        buildNumber: '1',
      ).checkForUpdate(const FakeReleaseSource(_release));

      final offline = AppVersionCubit(
        prefs,
        version: '1.0.0',
        buildNumber: '1',
      );
      await offline.checkForUpdate(const FakeReleaseSource(null));
      expect(offline.state.update?.version, '1.1.0');
    });

    test('after installing it the update is gone and «جديد» shows', () async {
      final prefs = await mockPrefs({'app_version_seen': '1.0.0+1'});
      await AppVersionCubit(
        prefs,
        version: '1.0.0',
        buildNumber: '1',
      ).checkForUpdate(const FakeReleaseSource(_release));

      // The user installed 1.1.0+2; Drive still says 1.1.0+2.
      final updated = AppVersionCubit(
        prefs,
        version: '1.1.0',
        buildNumber: '2',
      );
      expect(updated.state.update, isNull);
      expect(updated.state.isNew, isTrue);
    });

    test('a newer release replaces an older known one', () async {
      final prefs = await mockPrefs({'app_version_seen': '1.0.0+1'});
      final cubit = AppVersionCubit(prefs, version: '1.0.0', buildNumber: '1');
      await cubit.checkForUpdate(const FakeReleaseSource(_release));
      await cubit.markUpdateAnnounced();

      await cubit.checkForUpdate(
        const FakeReleaseSource(
          ReleaseInfo(version: '1.2.0', build: 3, notes: []),
        ),
      );
      expect(cubit.state.update?.version, '1.2.0');
      expect(cubit.state.announceUpdate, isTrue, reason: 'a new version');
    });
  });

  group('HttpReleaseSource', () {
    late HttpServer server;
    late String body;
    late int status;

    setUp(() async {
      body = jsonEncode(_release.toJson());
      status = 200;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response
          ..statusCode = status
          ..headers.contentType = ContentType.json
          ..write(body);
        request.response.close();
      });
    });

    tearDown(() => server.close(force: true));

    String url() => 'http://127.0.0.1:${server.port}/latest.json';

    test('reads the release from the URL', () async {
      final r = await HttpReleaseSource(url()).latest();
      expect(r?.version, '1.1.0');
      expect(r?.notes, _release.notes);
    });

    test('an error page or a broken file gives null', () async {
      status = 404;
      expect(await HttpReleaseSource(url()).latest(), isNull);
      status = 200;
      body = '<html>not json</html>';
      expect(await HttpReleaseSource(url()).latest(), isNull);
    });

    test('no URL yet: nothing is checked', () async {
      expect(await const HttpReleaseSource('').latest(), isNull);
    });
  });
}
