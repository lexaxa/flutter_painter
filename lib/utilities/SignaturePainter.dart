import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SignaturePainter extends CustomPainter {
  SignaturePainter(
      {this.background, required this.allPoints, required this.points});
  final List<Offset> points;
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
      canvas.drawImage(background!, Offset.zero, Paint());
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

  bool shouldRepaint(SignaturePainter other) => true; //other.points != points;
}
