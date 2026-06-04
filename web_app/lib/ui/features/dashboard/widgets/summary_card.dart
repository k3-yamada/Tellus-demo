import 'package:flutter/material.dart';

import '../../../../domain/models/infrastructure_snapshot.dart';
import '../../../core/theme/command_center_theme.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.qualityReport,
    required this.insights,
    required this.regionCount,
    required this.totalObservations,
  });

  final QualityReport? qualityReport;
  final SummaryInsights insights;
  final int regionCount;
  final int totalObservations;

  @override
  Widget build(BuildContext context) {
    final score = qualityReport?.overallScore ?? 0.0;
    final understood = score >= 0.6;

    return Semantics(
      label: 'summary-card',
      child: Card(
        key: const ValueKey('summary_card'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    understood ? Icons.check_circle_outline : Icons.help_outline,
                    color: understood ? CommandCenterTheme.accent : CommandCenterTheme.accentWarm,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          understood ? 'データ品質: 良好' : 'データ品質: 要確認',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: CommandCenterTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '監視地域 $regionCount / 観測 ${qualityReport?.totalObservations ?? totalObservations} 件 '
                          '· 品質スコア ${(score * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CommandCenterTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _InsightColumn(title: 'この画面でわかること', lines: insights.canUnderstand, icon: Icons.visibility)),
                  const SizedBox(width: 12),
                  Expanded(child: _InsightColumn(title: 'わからないこと', lines: insights.cannotUnderstand, icon: Icons.info_outline)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightColumn extends StatelessWidget {
  const _InsightColumn({required this.title, required this.lines, required this.icon});

  final String title;
  final List<String> lines;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: CommandCenterTheme.accent),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('· $line', style: const TextStyle(fontSize: 10, color: CommandCenterTheme.textMuted, height: 1.35)),
          ),
      ],
    );
  }
}
