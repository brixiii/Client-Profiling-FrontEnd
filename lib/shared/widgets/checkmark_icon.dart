import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Custom painted checkmark icon with document style
class CheckmarkIcon extends StatelessWidget {
  final double size;

  const CheckmarkIcon({
    Key? key,
    this.size = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CheckmarkPainter(),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw document/form background (light square)
    final documentRect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.15,
      size.width * 0.35,
      size.height * 0.5,
    );
canvas.drawRRect(
  RRect.fromRectAndRadius(
    documentRect,
    Radius.circular(size.width * 0.05),
  ),
  paint,
);

    // Draw checkmark
    final path = Path();
    path.moveTo(size.width * 0.35, size.height * 0.55);
    path.lineTo(size.width * 0.5, size.height * 0.7);
    path.lineTo(size.width * 0.8, size.height * 0.35);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
