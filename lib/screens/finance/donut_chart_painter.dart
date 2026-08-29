import 'package:flutter/material.dart';
import '../../models/finance_models.dart';

const double pi = 3.1415926535897932;

class DonutChartPainter extends CustomPainter {
  final List<FinanceCategoryStat> stats;
  final List<Color> colors;

  DonutChartPainter(this.stats, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius - 8);

    double startAngle = -pi / 2;

    if (stats.isEmpty) {
      final paint = Paint()
        ..color = const Color(0xFFD6D6D2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, 0, 2 * pi, false, paint);
      return;
    }

    for (int i = 0; i < stats.length; i++) {
      final stat = stats[i];
      final sweepAngle = (stat.percentage / 100) * 2 * pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
