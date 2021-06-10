import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class CanvasPainter extends CustomPainter {
  CanvasPainter({this.background, required this.allPoints});
  final List<List<Offset>> allPoints;
  ui.Image? background;

  @override
  void paint(Canvas canvas, Size size) {
    if (background != null) {
      final imageSize =
          Size(background!.width.toDouble(), background!.height.toDouble());
      final src = Offset.zero & imageSize;
      final dst = Offset.zero & size;
      canvas.drawImageRect(background!, src, dst, Paint());
    }
    Paint paintLine = new Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (var offset1 in allPoints) {
      for (int i = 0; i < offset1.length; i++) {
        canvas.drawCircle(offset1[i], 8.0, paintLine);
      }
    }
  }

  bool shouldRepaint(CanvasPainter other) =>
      true; //other.allPoints != allPoints;
}
