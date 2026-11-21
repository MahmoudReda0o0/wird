import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/app/router/app_routes.dart';
import 'package:my_guide/features/about/view/about_screen.dart';

import '../../../helpers/test_app.dart';

void main() {
  Future<TestCubits> pumpHome(
    WidgetTester tester, {
    Map<String, Object> saved = const {},
    String version = '1.0.0',
    String buildNumber = '1',
  }) async {
    usePhoneSize(tester);
    final cubits = TestCubits(
      await mockPrefs(saved),
      version: version,
      buildNumber: buildNumber,
    );
    await tester.pumpWidget(testApp(cubits, initialRoute: AppRoutes.home));
    await tester.pump();
    return cubits;
  }

  testWidgets('shows the city, the next prayer and the sections', (
    tester,
  ) async {
    await pumpHome(tester);
    expect(find.text('وِرْد'), findsOneWidget);
    expect(find.text('المنصورة'), findsOneWidget);
    expect(find.text('الأقسام'), findsOneWidget);
    expect(find.text('مواقيت الصلاة'), findsOneWidget);
    expect(find.text('الأذكار'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
  });

  testWidgets('the azkar tile opens the five sections', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('الأذكار'));
    await tester.pumpAndSettle();
    for (final title in [
      'أذكار الصباح',
      'أذكار المساء',
      'تسابيح',
      'أذكار النوم',
      'أذكار الاستيقاظ',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  testWidgets('the qibla tile opens the qibla', (tester) async {
    await pumpHome(tester);
    expect(find.text('اتجاه الكعبة'), findsOneWidget);
    await tester.ensureVisible(find.text('القبلة'));
    await tester.tap(find.text('القبلة'));
    // No compass plugin in tests: the screen gives up on it within 2 s and
    // shows the angle. (Not pumpAndSettle: the spinner never settles.)
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('الموبايل ده مفيهوش بوصلة'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('the prayer-times tile opens prayer times', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('مواقيت الصلاة'));
    await tester.pumpAndSettle();
    expect(find.text('صوت الأذان'), findsOneWidget);
  });

  testWidgets('after an update the badge says «جديد» until «عن التطبيق»', (
    tester,
  ) async {
    final cubits = await pumpHome(
      tester,
      saved: {'app_version_seen': '1.0.0+1'},
      version: '1.1.0',
      buildNumber: '2',
    );
    expect(find.text('جديد 1.1.0'), findsOneWidget);

    await tester.tap(find.text('جديد 1.1.0'));
    await tester.pumpAndSettle();
    expect(cubits.appVersion.state.isNew, isFalse);

    Navigator.of(tester.element(find.byType(AppVersion))).pop();
    await tester.pumpAndSettle();
    expect(find.text('جديد 1.1.0'), findsNothing);
    expect(find.text('1.1.0'), findsOneWidget);
  });
}
