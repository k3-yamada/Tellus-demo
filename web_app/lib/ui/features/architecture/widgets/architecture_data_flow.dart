import 'package:flutter/material.dart';

import '../../../core/theme/command_center_theme.dart';

class ArchitectureDataFlow extends StatelessWidget {
  const ArchitectureDataFlow({super.key});

  static const _steps = <_DataStep>[
    _DataStep(
      number: 1,
      title: 'Fetch',
      plain: 'Tellus Traveler API から地域ごとの SAR シーンを取得します。',
      technical:
          'fetch_tellus_data.py が data-search を BBOX 単位でクエリし、生メタデータを収集します。',
      icon: Icons.cloud_download,
    ),
    _DataStep(
      number: 2,
      title: 'Enrich',
      plain: 'サムネイルやダウンロード URL など表示に必要な情報を付加します。',
      technical:
          'pipeline/enrich_scenes.py が Traveler 応答に thumbnailUrl・downloadUrl を付与（任意）。',
      icon: Icons.auto_fix_high,
    ),
    _DataStep(
      number: 3,
      title: 'Quality / diff',
      plain: '品質レポートとスキーマ v2 へ移行し、前回との差分を記録します。',
      technical:
          'migrate_v2.py が schemaVersion・qualityReport・coverageByYear を付与。'
          '.previous.json と diff 比較・Slack 通知。',
      icon: Icons.fact_check,
    ),
    _DataStep(
      number: 4,
      title: 'Serve',
      plain: 'ダッシュボードが JSON を読み込み、地図とチャートに表示します。',
      technical:
          'Flutter が assets/data/infrastructure_data.json または BFF /api/* から v1/v2 JSON をロード。',
      icon: Icons.dashboard,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'データフロー',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: CommandCenterTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '取得から画面表示までの 4 段階（docs/ARCHITECTURE.md Data Flow）',
          style: TextStyle(fontSize: 12, color: CommandCenterTheme.textMuted),
        ),
        const SizedBox(height: 16),
        for (final step in _steps) ...[
          _StepTile(step: step),
          if (step.number < _steps.length)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
              child: Icon(
                Icons.arrow_downward,
                size: 14,
                color: CommandCenterTheme.border.withValues(alpha: 0.8),
              ),
            ),
        ],
      ],
    );
  }
}

class _DataStep {
  const _DataStep({
    required this.number,
    required this.title,
    required this.plain,
    required this.technical,
    required this.icon,
  });

  final int number;
  final String title;
  final String plain;
  final String technical;
  final IconData icon;
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step});

  final _DataStep step;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: CommandCenterTheme.accent.withValues(alpha: 0.15),
              child: Text(
                '${step.number}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: CommandCenterTheme.accent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(step.icon, size: 16, color: CommandCenterTheme.accentWarm),
                      const SizedBox(width: 6),
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: CommandCenterTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.plain,
                    style: const TextStyle(fontSize: 12, color: CommandCenterTheme.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.technical,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CommandCenterTheme.textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
