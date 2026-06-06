import 'package:flutter/material.dart';

import '../../../../domain/models/infrastructure_snapshot.dart';
import '../../../core/theme/command_center_theme.dart';
import '../../../core/widgets/provenance_widgets.dart';

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
    final total = qualityReport?.totalObservations ?? totalObservations;
    final geo = qualityReport?.regionsWithGeometry ?? 0;
    final thumb = qualityReport?.regionsWithThumbnails ?? 0;
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                understood ? 'メタデータ網羅: 良好' : 'メタデータ網羅: 要確認',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: CommandCenterTheme.textPrimary,
                                ),
                              ),
                            ),
                            ProvenanceBadge(
                              provenance: DataProvenance.demo,
                              compact: true,
                              tooltip: '品質スコアは観測メタデータの充足度です。解析精度ではありません。',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '監視地域 $regionCount · 観測 $total 件 · メタ充足スコア ${(score * 100).toStringAsFixed(0)}%',
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
              if (total > 0) ...[
                const SizedBox(height: 12),
                CoverageMeter(
                  label: '位置・撮影範囲メタデータ',
                  numerator: geo,
                  denominator: total,
                  accentColor: CommandCenterTheme.dataReal,
                  caption: 'いつ・どこで撮影したかは全件で把握できます',
                ),
                const SizedBox(height: 8),
                CoverageMeter(
                  label: '画像プレビュー（サムネイル）',
                  numerator: thumb,
                  denominator: total,
                  accentColor: thumb < total ? CommandCenterTheme.accentWarm : CommandCenterTheme.accent,
                  caption: thumb < total
                      ? 'タイムラインの多くの日付では代表画像または未取得表示になります'
                      : '全日付でプレビュー画像があります',
                ),
              ],
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InsightColumn(
                      title: 'この画面でわかること',
                      lines: insights.canUnderstand,
                      icon: Icons.visibility,
                      accent: CommandCenterTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InsightColumn(
                      title: 'わからないこと',
                      lines: insights.cannotUnderstand,
                      icon: Icons.info_outline,
                      accent: CommandCenterTheme.dataDemo,
                    ),
                  ),
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
  const _InsightColumn({
    required this.title,
    required this.lines,
    required this.icon,
    required this.accent,
  });

  final String title;
  final List<String> lines;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '· $line',
              style: const TextStyle(fontSize: 11, color: CommandCenterTheme.textMuted, height: 1.4),
            ),
          ),
      ],
    );
  }
}
