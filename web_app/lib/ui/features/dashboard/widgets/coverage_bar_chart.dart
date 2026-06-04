import 'package:flutter/material.dart';

import '../../../core/theme/command_center_theme.dart';

class CoverageBarChart extends StatelessWidget {
  const CoverageBarChart({super.key, required this.coverageByYear});

  final Map<String, int> coverageByYear;

  @override
  Widget build(BuildContext context) {
    if (coverageByYear.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('年別観測データなし', style: TextStyle(color: CommandCenterTheme.textMuted, fontSize: 11)),
        ),
      );
    }

    final years = coverageByYear.keys.toList()..sort();
    final maxCount = coverageByYear.values.reduce((a, b) => a > b ? a : b);

    return Semantics(
      label: 'coverage-bar-chart',
      child: SizedBox(
        height: 100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final year in years)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${coverageByYear[year]}',
                        style: const TextStyle(fontSize: 8, color: CommandCenterTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: maxCount > 0 ? coverageByYear[year]! / maxCount : 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: CommandCenterTheme.accent.withValues(alpha: 0.7),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        year.substring(2),
                        style: const TextStyle(fontSize: 8, color: CommandCenterTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
