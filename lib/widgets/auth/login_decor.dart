import 'package:flutter/material.dart';

/// Soft beige city skyline used as login background decoration.
class LoginCitySkylinePainter extends CustomPainter {
  final Color color;
  final bool mirror;

  const LoginCitySkylinePainter({
    required this.color,
    this.mirror = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (mirror) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final path = Path();
    final h = size.height;
    final w = size.width;

    path.moveTo(0, h);
    path.lineTo(0, h * 0.62);
    path.lineTo(w * 0.04, h * 0.62);
    path.lineTo(w * 0.04, h * 0.38);
    path.lineTo(w * 0.09, h * 0.38);
    path.lineTo(w * 0.09, h * 0.52);
    path.lineTo(w * 0.13, h * 0.52);
    path.lineTo(w * 0.13, h * 0.22);
    path.lineTo(w * 0.19, h * 0.22);
    path.lineTo(w * 0.19, h * 0.48);
    path.lineTo(w * 0.24, h * 0.48);
    path.lineTo(w * 0.24, h * 0.34);
    path.lineTo(w * 0.30, h * 0.34);
    path.lineTo(w * 0.30, h * 0.58);
    path.lineTo(w * 0.36, h * 0.58);
    path.lineTo(w * 0.36, h * 0.18);
    path.lineTo(w * 0.42, h * 0.18);
    path.lineTo(w * 0.42, h * 0.42);
    path.lineTo(w * 0.48, h * 0.42);
    path.lineTo(w * 0.48, h * 0.28);
    path.lineTo(w * 0.55, h * 0.28);
    path.lineTo(w * 0.55, h * 0.55);
    path.lineTo(w * 0.62, h * 0.55);
    path.lineTo(w * 0.62, h * 0.30);
    path.lineTo(w * 0.68, h * 0.30);
    path.lineTo(w * 0.68, h * 0.15);
    path.lineTo(w * 0.74, h * 0.15);
    path.lineTo(w * 0.74, h * 0.40);
    path.lineTo(w * 0.80, h * 0.40);
    path.lineTo(w * 0.80, h * 0.50);
    path.lineTo(w * 0.86, h * 0.50);
    path.lineTo(w * 0.86, h * 0.25);
    path.lineTo(w * 0.92, h * 0.25);
    path.lineTo(w * 0.92, h * 0.45);
    path.lineTo(w * 0.97, h * 0.45);
    path.lineTo(w * 0.97, h * 0.60);
    path.lineTo(w, h * 0.60);
    path.lineTo(w, h);
    path.close();

    canvas.drawPath(path, paint);

    // Simple window dots
    final windowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    for (final wx in [0.055, 0.155, 0.385, 0.655, 0.885]) {
      for (var i = 0; i < 3; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * wx, h * (0.28 + i * 0.08), w * 0.012, h * 0.05),
            const Radius.circular(1),
          ),
          windowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LoginCitySkylinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.mirror != mirror;
  }
}

class LoginDashedRoutePainter extends CustomPainter {
  final Color color;

  const LoginDashedRoutePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.05,
        size.width * 0.72,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.65,
        size.width * 0.94,
        size.height * 0.78,
      );

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    const dash = 5.0;
    const gap = 4.0;
    var distance = 0.0;
    while (distance < metric.length) {
      final next = (distance + dash).clamp(0.0, metric.length);
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance = next + gap;
    }
  }

  @override
  bool shouldRepaint(covariant LoginDashedRoutePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
