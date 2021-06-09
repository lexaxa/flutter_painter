import 'dart:ui';

import 'package:flutter/material.dart';

class SignaturePainter extends CustomPainter {
  SignaturePainter({required this.allPoints, required this.points});
  final List<Offset> points;
  final List<List<Offset>> allPoints;

  void paint(Canvas canvas, Size size) {
    Paint paintLine = new Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;
    // for (int i = 0; i < points.length - 1; i++) {
    //   // if (points[i] != null && points[i + 1] != null)
    //   // canvas.drawLine(points[i], points[i + 1], paint);
    //   canvas.drawCircle(points[i], 5.0, paintLine);
    // }

    for (var offset1 in allPoints) {
      for (int i = 0; i < offset1.length; i++) {
        canvas.drawCircle(offset1[i], 8.0, paintLine);
      }
    }
  }

  bool shouldRepaint(SignaturePainter other) => true; //other.points != points;
}
