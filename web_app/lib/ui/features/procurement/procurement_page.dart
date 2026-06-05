import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../data/services/tellus_bff_client.dart';
import '../../core/theme/command_center_theme.dart';
import '../dashboard/view_models/dashboard_view_model.dart';

class ProcurementPage extends StatefulWidget {
  const ProcurementPage({super.key});

  @override
  State<ProcurementPage> createState() => _ProcurementPageState();
}

class _ProcurementPageState extends State<ProcurementPage> {
  final _cart = <String>[];
  String? _lastOrderId;

  @override
  Widget build(BuildContext context) {
    final demoMode = AppConfig.instance.demoMode;
    final vm = context.watch<DashboardViewModel>();
    final items = vm.datasetsCatalog.isNotEmpty
        ? vm.datasetsCatalog
            .map((d) => {
                  'id': d.id,
                  'name': d.name,
                  'desc': d.description ?? 'Tellus SAR dataset',
                })
            .toList()
        : _fallbackDatasets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('データ調達 (デモ)'),
        backgroundColor: CommandCenterTheme.panel,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!demoMode)
            const Banner(
              message: 'DEMO_MODE=false — 本番 API は無効',
              location: BannerLocation.topStart,
            ),
          const Text(
            'カートデモ (DEMO_MODE)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '有償データの自動購入は行いません。発注 API 呼び出しは dry-run のみです。',
            style: TextStyle(color: CommandCenterTheme.accentWarm, fontSize: 12),
          ),
          const SizedBox(height: 16),
          for (final item in items)
            Card(
              child: ListTile(
                title: Text(item['name']!),
                subtitle: Text(item['desc']!),
                trailing: IconButton(
                  tooltip: _cart.contains(item['id']) ? 'カートから削除' : 'カートに追加',
                  icon: Icon(
                    _cart.contains(item['id']) ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                    color: CommandCenterTheme.accent,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_cart.contains(item['id'])) {
                        _cart.remove(item['id']);
                      } else {
                        _cart.add(item['id']!);
                      }
                    });
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          Semantics(
            label: 'デモ発注 ${_cart.length} 件',
            button: true,
            enabled: _cart.isNotEmpty,
            child: ElevatedButton(
              onPressed: _cart.isEmpty ? null : () => _submitOrder(demoMode),
              child: Text('デモ発注 (${_cart.length} 件)'),
            ),
          ),
          if (_lastOrderId != null) ...[
            const SizedBox(height: 12),
            Text('デモ注文 ID: $_lastOrderId', style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Future<void> _submitOrder(bool demoMode) async {
    if (!demoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DEMO_MODE が無効です')),
      );
      return;
    }
    final bff = TellusBffClient();
    var message = 'デモ発注を記録しました (dry-run)';
    if (bff.isConfigured) {
      try {
        final result = await bff.demoCartOrder(_cart);
        message = result['message']?.toString() ?? message;
      } catch (e) {
        message = 'BFF エラー: $e';
      }
    }
    if (!mounted) return;
    setState(() {
      _lastOrderId = 'DEMO-${DateTime.now().millisecondsSinceEpoch}';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static const _fallbackDatasets = [
    {'id': 'palsar-2', 'name': 'PALSAR-2 高分解能', 'desc': 'L-band SAR · 3m'},
    {'id': 'sentinel-1', 'name': 'Sentinel-1 GRD', 'desc': 'C-band SAR · 10m'},
    {'id': 'alos-2', 'name': 'ALOS-2 スポットライト', 'desc': 'L-band SAR · 1m'},
  ];
}
