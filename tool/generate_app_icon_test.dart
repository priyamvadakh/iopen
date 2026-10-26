// Renders the iOpen giraffe icon to PNG files for launcher and web icons.
// Run: flutter test tool/generate_app_icon_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/widgets/giraffe.dart';

Future<void> _render(String path, {required bool rounded}) async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  GiraffeIconPainter(rounded: rounded).paint(canvas, const Size(size, size));
  final image = await recorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('generate app icon', () async {
    await _render('assets/brand/app_icon.png', rounded: true);
    await _render('assets/brand/app_icon_square.png', rounded: false);
  });
}
