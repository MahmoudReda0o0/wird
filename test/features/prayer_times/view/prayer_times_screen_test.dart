import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/prayer_times/view/prayer_times_screen.dart';

import '../../../helpers/test_app.dart';

void main() {
  Future<TestCubits> pumpScreen(
    WidgetTester tester, {
    bool permissionGranted = true,
  }) async {
    usePhoneSize(tester);
    final cubits = TestCubits(
      await mockPrefs(),
      permissionGranted: permissionGranted,
    );
    await tester.pumpWidget(testApp(cubits, home: const PrayerTimingScreen()));
    return cubits;
  }

  testWidgets('shows the six times for the saved city', (tester) async {
    await pumpScreen(tester);
    expect(find.text('المنصورة'), findsOneWidget);
    for (final name in [
      'الفجر',
      'الشروق',
      'الظهر',
      'العصر',
      'المغرب',
      'العشاء',
    ]) {
      expect(find.text(name), findsWidgets, reason: name);
    }
  });

  testWidgets('choosing another city updates the screen and is saved', (
    tester,
  ) async {
    final cubits = await pumpScreen(tester);
    await tester.tap(find.text('المنصورة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('القاهرة'));
    await tester.pumpAndSettle();

    expect(find.text('القاهرة'), findsOneWidget);
    expect(find.text('المنصورة'), findsNothing);
    expect(cubits.city.state.id, 'cairo');
    expect(cubits.prefs.getString('prayer_city'), 'cairo');
  });

  testWidgets('turning the adhan on shows a bell per prayer', (tester) async {
    final cubits = await pumpScreen(tester);
    expect(find.byTooltip('إيقاف أذان الفجر'), findsNothing);

    await tester.tap(find.text('صوت الأذان'));
    await tester.pumpAndSettle();

    expect(cubits.adhan.state.enabled, isTrue);
    expect(find.byTooltip('إيقاف أذان الفجر'), findsOneWidget);

    // One bell turns that prayer off and keeps the others.
    await tester.tap(find.byTooltip('إيقاف أذان الفجر'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('تشغيل أذان الفجر'), findsOneWidget);
    expect(cubits.adhan.state.isOn('fajr'), isFalse);
    expect(cubits.adhan.state.isOn('dhuhr'), isTrue);
  });

  testWidgets('a refused permission keeps the adhan off and explains why', (
    tester,
  ) async {
    final cubits = await pumpScreen(tester, permissionGranted: false);
    await tester.tap(find.text('صوت الأذان'));
    await tester.pumpAndSettle();

    expect(cubits.adhan.state.enabled, isFalse);
    expect(
      find.text(
        'اسمح لوِرْد بالإشعارات من إعدادات الموبايل عشان الأذان يشتغل.',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('إيقاف أذان الفجر'), findsNothing);
  });
}
