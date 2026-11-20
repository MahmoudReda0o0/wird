import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/app/router/app_routes.dart';
import 'package:my_guide/features/about/data/app_info.dart';
import 'package:my_guide/features/about/data/release_info.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/fake_release_source.dart';
import '../../../helpers/test_app.dart';

const _release = ReleaseInfo(
  version: '1.1.0',
  build: 2,
  notes: ['تذكير بالأذكار بعد الفجر والعصر'],
);

/// Home on 1.0.0+1, with [release] published on Drive (null: none).
Future<TestCubits> _home(WidgetTester tester, ReleaseInfo? release) async {
  usePhoneSize(tester);
  final cubits = TestCubits(await mockPrefs({'app_version_seen': '1.0.0+1'}));
  await tester.pumpWidget(testApp(cubits, initialRoute: AppRoutes.home));
  await tester.pump();
  await cubits.appVersion.checkForUpdate(FakeReleaseSource(release));
  // One frame delivers the Cubit's new state, the next rebuilds with it.
  await tester.pump();
  await tester.pump();
  return cubits;
}

void main() {
  testWidgets('no newer version: the badge shows the installed one', (
    tester,
  ) async {
    await _home(tester, null);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.textContaining('تحديث'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a newer version: «تحديث» badge and a message, once', (
    tester,
  ) async {
    final cubits = await _home(tester, _release);
    expect(find.text('تحديث 1.1.0'), findsOneWidget);
    expect(find.text('فيه نسخة جديدة من وِرْد: 1.1.0'), findsOneWidget);
    expect(cubits.appVersion.state.announceUpdate, isFalse);

    // Checking again on the same version doesn't repeat the message.
    // Let the message finish showing (its 8 s start after it slides in).
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(find.text('فيه نسخة جديدة من وِرْد: 1.1.0'), findsNothing);
    await cubits.appVersion.checkForUpdate(const FakeReleaseSource(_release));
    await tester.pump();
    await tester.pump();
    expect(find.text('فيه نسخة جديدة من وِرْد: 1.1.0'), findsNothing);
  });

  testWidgets('the message opens «عن التطبيق» with the new version', (
    tester,
  ) async {
    await _home(tester, _release);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('التفاصيل'));
    await tester.pumpAndSettle();
    expect(find.text('نسخة جديدة متاحة'), findsOneWidget);
  });

  testWidgets('«عن التطبيق» shows the new version, its notes and download', (
    tester,
  ) async {
    await _home(tester, _release);
    await tester.tap(find.text('تحديث 1.1.0'));
    await tester.pumpAndSettle();

    expect(find.text('نسخة جديدة متاحة'), findsOneWidget);
    expect(find.text('الإصدار 1.1.0 (2)'), findsOneWidget);
    expect(find.text('تذكير بالأذكار بعد الفجر والعصر'), findsOneWidget);
    expect(find.text('تنزيل النسخة الجديدة'), findsOneWidget);
    // The installed version is still there, labelled as the current one.
    expect(find.text('الإصدار 1.0.0 (1)'), findsOneWidget);
    expect(find.text('الجديد في نسختك الحالية (1.0.0)'), findsOneWidget);
  });

  testWidgets('without a newer version there is no download section', (
    tester,
  ) async {
    await _home(tester, null);
    await tester.tap(find.text('1.0.0'));
    await tester.pumpAndSettle();
    expect(find.text('نسخة جديدة متاحة'), findsNothing);
    expect(find.text('تنزيل النسخة الجديدة'), findsNothing);
    expect(find.text('الجديد في هذا الإصدار'), findsOneWidget);
  });

  testWidgets('the QR code and link are the public Drive folder', (
    tester,
  ) async {
    await _home(tester, _release);
    await tester.tap(find.text('تحديث 1.1.0'));
    await tester.pumpAndSettle();

    // The QR is built from AppInfo.downloadUrl (see about_screen.dart);
    // the same link is printed under it.
    await tester.scrollUntilVisible(find.byType(QrImageView), 300);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(
      AppInfo.downloadUrl,
      startsWith('https://drive.google.com/drive/folders/'),
    );
    expect(find.text(AppInfo.downloadUrl), findsOneWidget);
  });
}
