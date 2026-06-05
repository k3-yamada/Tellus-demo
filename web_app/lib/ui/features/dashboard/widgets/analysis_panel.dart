import 'package:flutter/material.dart';

import '../view_models/dashboard_view_model.dart';
import '../../../core/theme/command_center_theme.dart';
import 'displacement_chart.dart';
import '../../../core/widgets/provenance_widgets.dart';

class AnalysisPanel extends StatelessWidget {
  const AnalysisPanel({super.key, required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final demo = viewModel.displacementDemo;
    final region = viewModel.selectedRegion;
    final currentDate = viewModel.currentDateLabel;
    final sliderIso = viewModel.currentSliderIso ?? '';
    final displacement = region != null && demo != null
        ? viewModel.displacementAtDate(sliderIso.length >= 10 ? sliderIso.substring(0, 10) : sliderIso)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 16, color: CommandCenterTheme.accentWarm),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('解析パネル (Analyst)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                const ProvenanceBadge(
                  provenance: DataProvenance.demo,
                  compact: true,
                  tooltip: '変位・チャートはデモ用の仮データです。TelluSAR実解析ではありません。',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (demo?.disclaimer != null)
              Text(
                _jaDisclaimer(demo!.disclaimer!),
                style: const TextStyle(fontSize: 10, color: CommandCenterTheme.dataDemo),
              ),
            const SizedBox(height: 8),
            _row('選択日時', currentDate),
            if (displacement != null)
              _row('変位 (デモ)', '${displacement.toStringAsFixed(1)} ${demo?.unit ?? "mm"}'),
            if (viewModel.tellusarSuggestedPair != null) ...[
              const SizedBox(height: 6),
              _row(
                'TelluSAR候補',
                (viewModel.tellusarSuggestedPair!['dataIds'] as List?)?.join(', ') ?? '—',
              ),
            ],

            if (demo != null && region?.id == demo.regionId) ...[
              const SizedBox(height: 8),
              const Text('累積変位トレンド (デモ)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              DisplacementChart(
                demo: demo,
                highlightDate: sliderIso.length >= 10 ? sliderIso.substring(0, 10) : null,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('軌道: 全て'),
                  selected: viewModel.orbitFilter == null,
                  onSelected: (_) => viewModel.setOrbitFilter(null),
                ),
                FilterChip(
                  label: const Text('ascending'),
                  selected: viewModel.orbitFilter == 'ascending',
                  onSelected: (_) => viewModel.setOrbitFilter('ascending'),
                ),
                FilterChip(
                  label: const Text('descending'),
                  selected: viewModel.orbitFilter == 'descending',
                  onSelected: (_) => viewModel.setOrbitFilter('descending'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('偏波: 全て'),
                  selected: viewModel.polarizationFilter == null,
                  onSelected: (_) => viewModel.setPolarizationFilter(null),
                ),
                FilterChip(
                  label: const Text('HH'),
                  selected: viewModel.polarizationFilter == 'HH',
                  onSelected: (_) => viewModel.setPolarizationFilter('HH'),
                ),
                FilterChip(
                  label: const Text('HV'),
                  selected: viewModel.polarizationFilter == 'HV',
                  onSelected: (_) => viewModel.setPolarizationFilter('HV'),
                ),
                FilterChip(
                  label: const Text('VV'),
                  selected: viewModel.polarizationFilter == 'VV',
                  onSelected: (_) => viewModel.setPolarizationFilter('VV'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 11, color: CommandCenterTheme.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

String _jaDisclaimer(String raw) {
  if (raw.contains('Demo values only')) {
    return '※ 表示中の変位はデモ用の仮データです（TelluSAR 実解析ではありません）';
  }
  return raw;
}
