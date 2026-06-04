import 'package:flutter/material.dart';

import '../view_models/dashboard_view_model.dart';
import '../widgets/analysis_panel.dart';
import '../widgets/coverage_bar_chart.dart';
import '../widgets/thumbnail_preview.dart';
import 'monitoring_chart_painter.dart';
import '../../../core/theme/command_center_theme.dart';

class SidePanel extends StatelessWidget {
  const SidePanel({super.key, required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final region = viewModel.selectedRegion;
    if (region == null) {
      return const Center(child: Text('地域データがありません'));
    }

    final obs = viewModel.observationAtProgress(region, viewModel.animatedProgress);
    final chartPoints = viewModel.chartPointsFor(region);
    final highlight = viewModel.chartHighlightIndex(region);
    final isAnalyst = viewModel.viewMode == ViewMode.analyst;
    final infraLabel = region.type == 'embankment' ? '堤防インフラ監視' : '斜面・地盤監視';

    return Card(
      key: const ValueKey('side_panel'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.satellite_alt, color: CommandCenterTheme.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    region.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              label: infraLabel,
              child: Text(
                infraLabel,
                style: const TextStyle(color: CommandCenterTheme.textMuted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final r in viewModel.regions)
                  ChoiceChip(
                    key: ValueKey('region_chip_${r.id}'),
                    label: Text(r.name),
                    selected: r.id == viewModel.selectedRegionId,
                    onSelected: (_) => viewModel.selectRegion(r.id),
                    selectedColor: CommandCenterTheme.accent.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      color: r.id == viewModel.selectedRegionId
                          ? CommandCenterTheme.accent
                          : CommandCenterTheme.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (isAnalyst) ...[
              AnalysisPanel(viewModel: viewModel),
              const SizedBox(height: 12),
            ] else ...[
              ThumbnailPreview(observation: obs),
              const SizedBox(height: 12),
              const Text(
                '年別観測回数',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(height: 4),
              CoverageBarChart(coverageByYear: viewModel.coverageForRegion(region.id)),
              const SizedBox(height: 12),
            ],
            if (obs != null) ...[
              _infoRow('撮影日時', viewModel.formatDateLabel(
                obs.startDatetime.isNotEmpty ? obs.startDatetime : obs.acquisitionDate,
              )),
              if (isAnalyst) ...[
                _infoRow('データID', obs.dataId),
                _infoRow('軌道方向', obs.orbitDirection),
                _infoRow('偏波', obs.polarization),
                if (obs.relativeOrbit != null) _infoRow('相対軌道', '${obs.relativeOrbit}'),
                _infoRow('オフナディア角', obs.offNadir.toStringAsFixed(1)),
                _infoRow('監視指数', obs.monitoringIndex.toStringAsFixed(3)),
                if (obs.qualityScore != null) _infoRow('品質スコア', obs.qualityScore!.toStringAsFixed(2)),
              ] else ...[
                _infoRow('衛星の向き', obs.orbitDirection == 'ascending' ? '北向き（昇交）' : '南向き（降交）'),
                if (obs.thumbnailUrl != null) _infoRow('プレビュー', '利用可能'),
              ],
            ],
            const SizedBox(height: 8),
            Text(
              isAnalyst ? '時系列監視指数 (レガシーデモ)' : '観測の変化（デモ指数）',
              style: const TextStyle(fontWeight: FontWeight.w600, color: CommandCenterTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CustomPaint(
                painter: MonitoringChartPainter(
                  points: chartPoints,
                  highlightIndex: highlight,
                  progress: viewModel.animatedProgress,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: const TextStyle(color: CommandCenterTheme.textMuted, fontSize: 11)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: CommandCenterTheme.textPrimary, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
