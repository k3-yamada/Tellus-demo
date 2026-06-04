import 'package:flutter/material.dart';

import '../../core/theme/command_center_theme.dart';

class ArchitecturePage extends StatelessWidget {
  const ArchitecturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アーキテクチャ'),
        backgroundColor: CommandCenterTheme.panel,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('システム構成', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 12),
          _ArchBlock(
            title: 'Flutter Web',
            body: 'ダッシュボード UI · Explorer/Analyst モード · 地図 footprint · 品質サマリー',
          ),
          _ArchBlock(
            title: 'Python Pipeline',
            body: 'fetch_tellus_data.py → enrich_scenes → migrate_v2 → infrastructure_data.json',
          ),
          _ArchBlock(
            title: 'Cloudflare Workers BFF',
            body: '/api/datasets · /api/search — API キー秘匿プロキシ',
          ),
          _ArchBlock(
            title: 'GitHub Actions',
            body: 'CI (analyze/build/e2e) · 週次 fetch-cron · Slack 通知',
          ),
          SizedBox(height: 16),
          Text(
            '詳細は docs/ARCHITECTURE.md を参照してください。',
            style: TextStyle(color: CommandCenterTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ArchBlock extends StatelessWidget {
  const _ArchBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: CommandCenterTheme.accent)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
