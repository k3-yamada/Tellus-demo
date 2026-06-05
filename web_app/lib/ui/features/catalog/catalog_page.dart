import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/sar_dataset.dart';
import '../../core/theme/command_center_theme.dart';
import '../../core/widgets/provenance_widgets.dart';
import '../dashboard/view_models/dashboard_view_model.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final meta = vm.snapshot;
    final catalog = vm.datasetsCatalog;
    final portal = vm.tellusPortalUrl ?? 'https://www.tellusxdp.com/';

    return Scaffold(
      appBar: AppBar(
        title: const Text('データカタログ'),
        backgroundColor: CommandCenterTheme.panel,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HeroClaimBar(
            icon: Icons.inventory_2_outlined,
            title: 'データカタログ',
            subtitle: 'Tellus で利用できる SAR データセットの一覧です。下の「購入済み」は UI デモ用のモック表示です。',
          ),
          const SizedBox(height: 12),
          const Text(
            'Tellus SAR データセット',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '生成日時: ${meta?.generatedAt ?? "—"} · スキーマ v${meta?.schemaVersion ?? 1}',
            style: const TextStyle(color: CommandCenterTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          SelectableText(
            'Tellus ポータル: $portal',
            style: const TextStyle(fontSize: 11, color: CommandCenterTheme.accent),
          ),
          const SizedBox(height: 16),
          if (catalog.isEmpty)
            const Text(
              'データセット一覧は fetch 後に meta.datasetsCatalog に格納されます。',
              style: TextStyle(fontSize: 12),
            )
          else
            for (final ds in catalog)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.satellite_alt, color: CommandCenterTheme.accent),
                  title: Text(ds.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${ds.id.substring(0, 8)}… · 本デモ内 ${ds.observationCount} 件\n${ds.description ?? ""}',
                    style: const TextStyle(fontSize: 11),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                ),
              ),

          const SizedBox(height: 24),
          Row(
            children: [
              Text('購入画面デモ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              const ProvenanceBadge(provenance: DataProvenance.mock, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          const DataProvenanceBanner(
            message: '実際の購入済みデータ検索ではありません。本デモ内でヒットしたデータセットを再表示している UI モックです。',
            provenance: DataProvenance.mock,
            icon: Icons.shopping_bag_outlined,
          ),
          const SizedBox(height: 8),
          ..._purchasedEntries(vm).map(
            (ds) => Card(
              color: CommandCenterTheme.panel,
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: CommandCenterTheme.dataMock),
                title: Row(
                  children: [
                    Expanded(child: Text(ds.name, maxLines: 2, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    ProvenanceBadge(provenance: DataProvenance.mock, compact: true),
                  ],
                ),
                subtitle: Text('本デモ内 ${ds.observationCount} 件ヒット · ${ds.id.substring(0, 8)}…'),
                dense: true,
              ),
            ),
          ),
          if (_purchasedEntries(vm).isEmpty)
            const Text('購入済み相当のデータはまだありません。', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
          const Text('監視地域', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          for (final region in vm.regions)
            Card(
              child: ListTile(
                leading: const Icon(Icons.place, color: CommandCenterTheme.accentWarm),
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

List<SarDatasetEntry> _purchasedEntries(DashboardViewModel vm) {
  return vm.datasetsCatalog.where((d) => d.observationCount > 0).toList();
}
