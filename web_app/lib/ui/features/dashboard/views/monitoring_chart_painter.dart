import 'package:flutter/material.dart';

import '../view_models/dashboard_view_model.dart';
import '../../../core/theme/command_center_theme.dart';

class MonitoringChartPainter extends CustomPainter {
  MonitoringChartPainter({
    required this.points,
    required this.highlightIndex,
    required this.progress,
  });

  final List<ChartPoint> points;
  final int highlightIndex;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final padding = 24.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final origin = Offset(padding, padding);

    final minVal = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxVal = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs() < 0.001 ? 1.0 : maxVal - minVal;

    final gridPaint = Paint()
      ..color = CommandCenterTheme.border.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = origin.dy + chartHeight * i / 4;
      canvas.drawLine(Offset(origin.dx, y), Offset(origin.dx + chartWidth, y), gridPaint);
    }

    final linePath = Path();
    for (var i = 0; i < points.length; i++) {
      final x = origin.dx + chartWidth * i / (points.length - 1).clamp(1, points.length);
      final y = origin.dy + chartHeight * (1 - (points[i].value - minVal) / range);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = CommandCenterTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final fillPath = Path.from(linePath)
      ..lineTo(origin.dx + chartWidth, origin.dy + chartHeight)
      ..lineTo(origin.dx, origin.dy + chartHeight)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CommandCenterTheme.accent.withValues(alpha: 0.35),
            CommandCenterTheme.accent.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(origin.dx, origin.dy, chartWidth, chartHeight)),
    );

    if (highlightIndex >= 0 && highlightIndex < points.length) {
      final hx = origin.dx + chartWidth * highlightIndex / (points.length - 1).clamp(1, points.length);
      canvas.drawLine(
        Offset(hx, origin.dy),
        Offset(hx, origin.dy + chartHeight),
        Paint()
          ..color = CommandCenterTheme.accentWarm.withValues(alpha: 0.9)
          ..strokeWidth = 2,
      );
      final hy = origin.dy + chartHeight * (1 - (points[highlightIndex].value - minVal) / range);
      canvas.drawCircle(
        Offset(hx, hy),
        6,
        Paint()..color = CommandCenterTheme.accentWarm,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MonitoringChartPainter oldDelegate) {
    return oldDelegate.highlightIndex != highlightIndex ||
        oldDelegate.progress != progress ||
        oldDelegate.points.length != points.length;
  }
}
