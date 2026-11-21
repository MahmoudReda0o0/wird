import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/features/qibla/widgets/qibla_dial.dart';

Future<void> _pump(
  WidgetTester tester,
  QiblaDial dial, {
  bool dark = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: Center(child: dial)),
    ),
  ),
);

void main() {
  for (final dark in [false, true]) {
    for (final heading in [0.0, 139.9, 359.0]) {
      testWidgets('paints heading $heading (dark: $dark)', (tester) async {
        await _pump(
          tester,
          QiblaDial(
            heading: heading,
            qibla: 139.9,
            aligned: heading == 139.9,
            dimmed: false,
            sunAzimuth: 218,
          ),
          dark: dark,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(QiblaDial), findsOneWidget);
        expect(tester.getSize(find.byType(QiblaDial)), const Size(300, 316));
      });
    }
  }

  testWidgets('tells screen readers which way to turn', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const QiblaDial(heading: 100, qibla: 139.9, aligned: false, dimmed: false),
    );
    expect(find.bySemanticsLabel(RegExp('يمين')), findsOneWidget);

    await _pump(
      tester,
      const QiblaDial(heading: 180, qibla: 139.9, aligned: false, dimmed: false),
    );
    expect(find.bySemanticsLabel(RegExp('شمال')), findsOneWidget);

    await _pump(
      tester,
      const QiblaDial(heading: 139, qibla: 139.9, aligned: true, dimmed: false),
    );
    expect(find.bySemanticsLabel(RegExp('اتجاه القبلة')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('dimmed when the compass is not trusted', (tester) async {
    await _pump(
      tester,
      const QiblaDial(heading: 90, qibla: 139.9, aligned: false, dimmed: true),
    );
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(QiblaDial),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0.45);
  });
}
