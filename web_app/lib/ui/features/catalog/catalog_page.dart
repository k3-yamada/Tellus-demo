import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/command_center_theme.dart';
import '../dashboard/view_models/dashboard_view_model.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final meta = vm.snapshot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('データカタログ'),
        backgroundColor: CommandCenterTheme.panel,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tellus SAR データセット',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '生成日時: ${meta?.generatedAt ?? "—"} · スキーマ v${meta?.schemaVersion ?? 1}',
            style: const TextStyle(color: CommandCenterTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          for (final region in vm.regions)
            Card(
              child: ListTile(
                leading: const Icon(Icons.place, color: CommandCenterTheme.accent),
                title: Text(region.name),
                subtitle: Text(
                  '${region.type} · ${region.observationCount ?? region.observations.length} 観測',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  vm.selectRegion(region.id);
                  Navigator.pop(context);
                },
              ),
            ),
        ],
      ),
    );
  }
}
