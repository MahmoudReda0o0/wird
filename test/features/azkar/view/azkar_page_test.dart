import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/azkar/data/models/azkar_model.dart';
import 'package:my_guide/features/azkar/view/azkar_page_screen.dart';

import '../../../helpers/test_app.dart';

final _azkar = [
  AzkarModel(content: 'سبحان الله', repetition: 2),
  AzkarModel(content: 'الحمد لله', repetition: 1),
];

Future<TestCubits> _openSection(
  WidgetTester tester, {
  Map<String, Object> saved = const {},
}) async {
  usePhoneSize(tester);
  final cubits = TestCubits(await mockPrefs(saved));
  await tester.pumpWidget(
    testApp(
      cubits,
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: RouteSettings(
          arguments: AzkarPageArguments(
            id: 'test_section',
            title: 'قسم تجريبي',
            azkarList: _azkar,
          ),
        ),
        builder: (_) => const AzkarPageScreen(),
      ),
    ),
  );
  await tester.pump();
  return cubits;
}

void main() {
  testWidgets('lists the azkar with nothing counted yet', (tester) async {
    await _openSection(tester);
    expect(find.text('قسم تجريبي'), findsOneWidget);
    expect(find.text('سبحان الله'), findsOneWidget);
    expect(find.text('الحمد لله'), findsOneWidget);
    expect(find.text('تم 0 من 2'), findsOneWidget);
  });

  testWidgets('counting every zikr finishes the section', (tester) async {
    await _openSection(tester);

    await tester.tap(find.text('سبحان الله'));
    await tester.pump();
    expect(find.text('تم 0 من 2'), findsOneWidget);

    await tester.tap(find.text('سبحان الله'));
    await tester.pump();
    expect(find.text('تم 1 من 2'), findsOneWidget);

    await tester.tap(find.text('الحمد لله'));
    await tester.pumpAndSettle();
    expect(find.text('تمّ القسم كله'), findsOneWidget);
  });

  testWidgets('progress is saved and shown again on reopening', (tester) async {
    final cubits = await _openSection(tester);
    await tester.tap(find.text('الحمد لله'));
    await tester.pumpAndSettle();
    expect(find.text('تم 1 من 2'), findsOneWidget);

    // Same preferences, a new page: the count is still there.
    final saved = {
      for (final k in cubits.prefs.getKeys()) k: cubits.prefs.get(k)!,
    };
    await tester.pumpWidget(const SizedBox());
    await _openSection(tester, saved: saved);
    expect(find.text('تم 1 من 2'), findsOneWidget);
  });

  testWidgets('«من جديد» asks first, then starts the section again', (
    tester,
  ) async {
    await _openSection(tester);
    await tester.tap(find.text('الحمد لله'));
    await tester.pumpAndSettle();
    expect(find.text('تم 1 من 2'), findsOneWidget);

    await tester.tap(find.text('من جديد'));
    await tester.pumpAndSettle();
    expect(find.text('البدء من جديد؟'), findsOneWidget);

    // Cancel keeps the progress.
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.text('تم 1 من 2'), findsOneWidget);

    await tester.tap(find.text('من جديد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعادة'));
    await tester.pumpAndSettle();
    expect(find.text('تم 0 من 2'), findsOneWidget);
  });

  group('sabha', () {
    Future<void> openSabha(WidgetTester tester) async {
      await tester.tap(find.byTooltip('وضع السبحة'));
      await tester.pumpAndSettle();
      expect(find.text('وضع السبحة'), findsOneWidget);
    }

    Future<void> tapBead(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel('تسبيحة'));
      await tester.pump();
    }

    testWidgets('one zikr at a time, moving on when it is done', (
      tester,
    ) async {
      await _openSection(tester);
      await openSabha(tester);
      expect(find.text('سبحان الله'), findsOneWidget);
      expect(find.text('الحمد لله'), findsNothing);

      await tapBead(tester);
      expect(find.text('سبحان الله'), findsOneWidget);
      await tapBead(tester);
      // Finished: the sabha moves to the next zikr by itself.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('الحمد لله'), findsOneWidget);
      expect(find.text('تمّ ✓ — الذكر التالي'), findsOneWidget);

      // The message goes away on its own.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('تمّ ✓ — الذكر التالي'), findsNothing);
    });

    testWidgets('finishing the last zikr finishes the section', (tester) async {
      await _openSection(tester);
      await openSabha(tester);
      await tapBead(tester);
      await tapBead(tester);
      await tester.pump(const Duration(seconds: 2));
      await tapBead(tester);
      await tester.pumpAndSettle();
      expect(find.text('تمّ القسم كله'), findsOneWidget);
      expect(find.text('رجوع للقائمة'), findsOneWidget);
    });

    testWidgets('shares its counts with the page', (tester) async {
      await _openSection(tester);
      await openSabha(tester);
      await tapBead(tester);
      await tapBead(tester);
      await tester.pump(const Duration(seconds: 2));

      Navigator.of(tester.element(find.text('وضع السبحة'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('تم 1 من 2'), findsOneWidget);
    });
  });
}
