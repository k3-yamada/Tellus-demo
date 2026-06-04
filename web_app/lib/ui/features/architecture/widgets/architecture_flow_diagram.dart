import 'package:flutter/material.dart';

import '../../../core/theme/command_center_theme.dart';

class ArchitectureFlowDiagram extends StatelessWidget {
  const ArchitectureFlowDiagram({super.key});

  static const _nodes = <_FlowNode>[
    _FlowNode(
      id: 'flutter',
      title: 'Flutter Web',
      subtitle: 'Firebase Hosting',
      icon: Icons.web,
      row: 0,
      col: 0,
    ),
    _FlowNode(
      id: 'bff',
      title: 'BFF (Workers)',
      subtitle: '/api/* プロキシ',
      icon: Icons.cloud,
      row: 0,
      col: 1,
    ),
    _FlowNode(
      id: 'tellus',
      title: 'Tellus API',
      subtitle: 'Traveler + TelluSAR',
      icon: Icons.satellite_alt,
      row: 1,
      col: 1,
    ),
    _FlowNode(
      id: 'json',
      title: 'Static JSON',
      subtitle: 'assets/data/*.json',
      icon: Icons.storage,
      row: 1,
      col: 0,
    ),
    _FlowNode(
      id: 'pipeline',
      title: 'Python Pipeline',
      subtitle: 'fetch · enrich · migrate',
      icon: Icons.settings_ethernet,
      row: 2,
      col: 0,
    ),
    _FlowNode(
      id: 'gha',
      title: 'GitHub Actions',
      subtitle: 'CI · fetch-cron',
      icon: Icons.schedule,
      row: 2,
      col: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'システム構成（docs/ARCHITECTURE.md）',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: CommandCenterTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Flutter Web が BFF または静的 JSON から SAR メタデータを取得。'
          'Python パイプラインが Tellus API から取得し JSON を更新。GitHub Actions が定期実行。',
          style: TextStyle(fontSize: 12, color: CommandCenterTheme.textMuted),
        ),
        const SizedBox(height: 16),
        ..._buildRows(),
        const SizedBox(height: 12),
        _Legend(),
      ],
    );
  }

  List<Widget> _buildRows() {
    final rows = <int, List<_FlowNode>>{};
    for (final n in _nodes) {
      rows.putIfAbsent(n.row, () => []).add(n);
    }
    final sortedKeys = rows.keys.toList()..sort();
    final widgets = <Widget>[];
    for (var i = 0; i < sortedKeys.length; i++) {
      final rowNodes = rows[sortedKeys[i]]!..sort((a, b) => a.col.compareTo(b.col));
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < rowNodes.length; j++) ...[
              if (j > 0) const _FlowArrow(horizontal: true),
              Expanded(child: _NodeCard(node: rowNodes[j])),
            ],
          ],
        ),
      );
      if (i < sortedKeys.length - 1) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Center(child: _FlowArrow(horizontal: false)),
        ));
      }
    }
    return widgets;
  }
}

class _FlowNode {
  const _FlowNode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.row,
    required this.col,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final int row;
  final int col;
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({required this.node});

  final _FlowNode node;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(node.icon, size: 18, color: CommandCenterTheme.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: CommandCenterTheme.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              node.subtitle,
              style: const TextStyle(fontSize: 11, color: CommandCenterTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow({required this.horizontal});

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: horizontal
          ? const EdgeInsets.symmetric(horizontal: 4)
          : const EdgeInsets.symmetric(vertical: 2),
      child: Icon(
        horizontal ? Icons.arrow_forward : Icons.arrow_downward,
        size: 16,
        color: CommandCenterTheme.border,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: const [
        _LegendItem(label: 'HTTPS → BFF', icon: Icons.link),
        _LegendItem(label: 'assets → JSON', icon: Icons.folder_open),
        _LegendItem(label: 'cron → Pipeline', icon: Icons.sync),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: CommandCenterTheme.textMuted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: CommandCenterTheme.textMuted)),
      ],
    );
  }
}
