import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RepaintBoundary toImage ishlaydimi', (t) async {
    final k = GlobalKey();
    await t.pumpWidget(MaterialApp(
      home: RepaintBoundary(
        key: k,
        child: const ColoredBox(color: Color(0xFF0A0A0B)),
      ),
    ));
    await t.pump();
    final rb = k.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await rb.toImage();
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    print('PIKSEL BAYT: ${bd!.lengthInBytes}');
    expect(bd.lengthInBytes, greaterThan(0));
  });
}
