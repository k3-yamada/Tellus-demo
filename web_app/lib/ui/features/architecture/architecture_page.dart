import 'package:flutter/material.dart';

import '../../core/theme/command_center_theme.dart';
import 'widgets/architecture_explainer_panel.dart';

class ArchitecturePage extends StatelessWidget {
  const ArchitecturePage({super.key});

  static const docsPath = 'docs/ARCHITECTURE.md';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('システム構成'),
        backgroundColor: CommandCenterTheme.panel,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'アーキテクチャ解説 · リポジトリ内ドキュメントと同期',
                    style: TextStyle(fontSize: 12, color: CommandCenterTheme.textMuted),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('詳細はリポジトリの docs/ARCHITECTURE.md を参照してください。'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text(docsPath),
                  style: TextButton.styleFrom(
                    foregroundColor: CommandCenterTheme.accent,
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: ArchitectureExplainerPanel()),
        ],
      ),
    );
  }
}
