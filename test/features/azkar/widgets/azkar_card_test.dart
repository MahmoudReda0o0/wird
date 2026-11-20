import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/azkar/data/models/azkar_model.dart';
import 'package:my_guide/features/azkar/widgets/azkar_card.dart';

import '../../../helpers/test_app.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required int remaining,
    required VoidCallback onCount,
    String? fadl,
  }) async {
    final cubits = TestCubits(await mockPrefs());
    await tester.pumpWidget(
      testApp(
        cubits,
        home: Scaffold(
          body: AzkarCard(
            azkarModel: AzkarModel(
              content: 'سبحان الله وبحمده',
              repetition: 3,
              fadl: fadl,
            ),
            index: 1,
            remaining: remaining,
            onCount: onCount,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the zikr and how many times are left', (tester) async {
    await pumpCard(tester, remaining: 3, onCount: () {});
    expect(find.text('سبحان الله وبحمده'), findsOneWidget);
    expect(find.text('3 مرات'), findsOneWidget);
    expect(find.text('تمّ'), findsNothing);
  });

  testWidgets('tapping the card counts one repetition', (tester) async {
    var taps = 0;
    await pumpCard(tester, remaining: 3, onCount: () => taps++);
    await tester.tap(find.text('سبحان الله وبحمده'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('a finished zikr shows «تمّ» and ignores taps', (tester) async {
    var taps = 0;
    await pumpCard(tester, remaining: 0, onCount: () => taps++);
    expect(find.text('تمّ'), findsOneWidget);
    await tester.tap(find.text('سبحان الله وبحمده'));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('the virtue opens under the card', (tester) async {
    await pumpCard(
      tester,
      remaining: 3,
      onCount: () {},
      fadl: 'من قالها مئة مرة غفرت خطاياه',
    );
    expect(find.text('من قالها مئة مرة غفرت خطاياه'), findsNothing);
    await tester.tap(find.text('فضل الذكر'));
    await tester.pumpAndSettle();
    expect(find.text('من قالها مئة مرة غفرت خطاياه'), findsOneWidget);
  });
}
