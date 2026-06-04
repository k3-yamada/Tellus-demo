import 'package:flutter/material.dart';

import '../../../../domain/models/infrastructure_snapshot.dart';
import '../../../core/theme/command_center_theme.dart';

class DisplacementChart extends StatelessWidget {
  const DisplacementChart({super.key, required this.demo, this.highlightDate});

  final DisplacementDemo demo;
  final String? highlightDate;

  @override
  Widget build(BuildContext context) {
    if (demo.values.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 72,
      child: CustomPaint(
        painter: _DisplacementPainter(demo: demo, highlightDate: highlightDate),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DisplacementPainter extends CustomPainter {
  _DisplacementPainter({required this.demo, this.highlightDate});

  final DisplacementDemo demo;
  final String? highlightDate;

  @override
  void paint(Canvas canvas, Size size) {
    final values = demo.values;
    final padding = 8.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;
    final origin = Offset(padding, padding);

    final mmValues = values.map((v) => v.displacementMm).toList();
    final minMm = mmValues.reduce((a, b) => a < b ? a : b);
    final maxMm = mmValues.reduce((a, b) => a > b ? a : b);
    final range = (maxMm - minMm).abs() < 0.01 ? 1.0 : maxMm - minMm;

    final linePaint = Paint()
      ..color = CommandCenterTheme.accentWarm
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = origin.dx + w * i / (values.length - 1).clamp(1, values.length);
      final norm = (values[i].displacementMm - minMm) / range;
      final y = origin.dy + h * (1 - norm);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    if (highlightDate != null) {
      for (var i = 0; i < values.length; i++) {
        if (values[i].date.compareTo(highlightDate!) <= 0) {
          final x = origin.dx + w * i / (values.length - 1).clamp(1, values.length);
          final norm = (values[i].displacementMm - minMm) / range;
          final y = origin.dy + h * (1 - norm);
          canvas.drawCircle(
            Offset(x, y),
            4,
            Paint()..color = CommandCenterTheme.accent,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DisplacementPainter oldDelegate) {
    return oldDelegate.highlightDate != highlightDate || oldDelegate.demo != demo;
  }
}
