// Draws the app's SabhaIcon into the PNGs the native splash screen uses.
//
// Run again after changing SabhaIcon or the brand color, then regenerate
// the splash:
//   flutter test tool/render_splash_test.dart
//   dart run flutter_native_splash:create
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_guide/features/azkar/widgets/sabha_icon.dart';

/// Wird primary (`WirdColors.light.primary`).
const _color = Color(0xFF0B6B5D);

Future<void> _render(
  WidgetTester tester, {
  required String path,
  required double canvas,
  required double icon,
}) async {
  final key = GlobalKey();
  tester.view.physicalSize = Size.square(canvas);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox.square(
            dimension: canvas,
            child: Center(
              child: SabhaIcon(size: icon, color: _color),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path)..createSync(recursive: true);
    file.writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('render splash images', (tester) async {
    // Android 11 and older, and iOS: the image is shown at its own size
    // (768 px = 192 dp at xxxhdpi), transparent around the beads.
    await _render(
      tester,
      path: 'assets/splash/sabha.png',
      canvas: 768,
      icon: 512,
    );
    // Android 12+: 1152 × 1152, and only the centre 768 circle is shown,
    // so the beads stay well inside it.
    await _render(
      tester,
      path: 'assets/splash/sabha_android12.png',
      canvas: 1152,
      icon: 560,
    );
  });
}
