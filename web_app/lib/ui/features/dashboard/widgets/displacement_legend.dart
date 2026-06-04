import 'package:flutter/material.dart';

import '../../../core/theme/command_center_theme.dart';

class DisplacementLegend extends StatelessWidget {
  const DisplacementLegend({super.key, this.displacementMm});

  final double? displacementMm;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CommandCenterTheme.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CommandCenterTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('変位 (デモ)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            if (displacementMm != null)
              Text(
                '${displacementMm!.toStringAsFixed(1)} mm',
                style: const TextStyle(fontSize: 12, color: CommandCenterTheme.accentWarm),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _swatch(CommandCenterTheme.accent),
                const SizedBox(width: 4),
                const Text('安定', style: TextStyle(fontSize: 9)),
                const SizedBox(width: 8),
                _swatch(CommandCenterTheme.accentWarm),
                const SizedBox(width: 4),
                const Text('変動大', style: TextStyle(fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color color) {
    return Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));
  }
}
