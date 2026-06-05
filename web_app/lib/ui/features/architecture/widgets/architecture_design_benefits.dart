import 'package:flutter/material.dart';

import '../../../core/theme/command_center_theme.dart';

class ArchitectureDesignBenefits extends StatefulWidget {
  const ArchitectureDesignBenefits({super.key});

  @override
  State<ArchitectureDesignBenefits> createState() => _ArchitectureDesignBenefitsState();
}

class _ArchitectureDesignBenefitsState extends State<ArchitectureDesignBenefits> {
  final _technicalMode = <String, bool>{
    'serverless': false,
    'security': false,
    'lowcost': false,
  };

  static const _benefits = <_BenefitCard>[
    _BenefitCard(
      id: 'serverless',
      title: 'サーバーレス',
      icon: Icons.cloud_outlined,
      plain:
          'フロントは Firebase、API キーは Workers に閉じ込め、バッチは GitHub Actions で動かすため、常時サーバー管理が不要です。',
      technical:
          'Flutter Web → Firebase Hosting。BFF は Cloudflare Workers（/api/*）。'
          'ETL は scripts/ + GHA cron。スケールはエッジと静的配信中心。',
    ),
    _BenefitCard(
      id: 'security',
      title: 'セキュリティ',
      icon: Icons.shield_outlined,
      plain:
          'ブラウザに Tellus API キーを載せず、BFF が Bearer トークンを保持してプロキシします。',
      technical:
          'backend/ Workers が API キーをサーバー側のみで保持。'
          'クライアントは HTTPS + 公開 JSON のみ。品質 diff は .previous.json で監査可能。',
    ),
    _BenefitCard(
      id: 'lowcost',
      title: '低コスト',
      icon: Icons.savings_outlined,
      plain:
          '静的ホスティングと週次バッチ中心のため、デモ・ PoC 運用のインフラ費用を抑えられます。',
      technical:
          'Hosting: Firebase static。Compute: Workers 従量 + GHA スケジュール。'
          'データ: assets JSON（v2）で CDN キャッシュ可能。Tellus API は取得頻度を cron で制御。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '設計の強み',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: CommandCenterTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '各カードで「やさしい説明」と「技術説明」を切り替えられます。',
          style: TextStyle(fontSize: 12, color: CommandCenterTheme.textMuted),
        ),
        const SizedBox(height: 16),
        for (final b in _benefits)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BenefitToggleCard(
              benefit: b,
              technical: _technicalMode[b.id] ?? false,
              onToggle: (v) => setState(() => _technicalMode[b.id] = v),
            ),
          ),
      ],
    );
  }
}

class _BenefitCard {
  const _BenefitCard({
    required this.id,
    required this.title,
    required this.icon,
    required this.plain,
    required this.technical,
  });

  final String id;
  final String title;
  final IconData icon;
  final String plain;
  final String technical;
}

class _BenefitToggleCard extends StatelessWidget {
  const _BenefitToggleCard({
    required this.benefit,
    required this.technical,
    required this.onToggle,
  });

  final _BenefitCard benefit;
  final bool technical;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(benefit.icon, color: CommandCenterTheme.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    benefit.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: CommandCenterTheme.accent,
                    ),
                  ),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('やさしく')),
                    ButtonSegment(value: true, label: Text('技術')),
                  ],
                  selected: {technical},
                  onSelectionChanged: (s) => onToggle(s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              technical ? benefit.technical : benefit.plain,
              style: TextStyle(
                fontSize: 12,
                color: technical ? CommandCenterTheme.textPrimary : CommandCenterTheme.textMuted,
                height: 1.45,
                fontFamily: technical ? 'monospace' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
