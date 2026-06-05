import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/tellusar_job.dart';
import '../../architecture/architecture_overlay.dart';
import '../../catalog/catalog_page.dart';
import '../../disaster_archive/views/disaster_archive_page.dart';
import '../../multi_sensor/views/multi_sensor_page.dart';
import '../../procurement/procurement_page.dart';
import '../../tellusar/views/tellusar_page.dart';
import '../../template_switcher/widgets/template_switcher.dart';
import '../view_models/dashboard_view_model.dart';
import '../widgets/summary_card.dart';
import 'map_panel.dart';
import 'side_panel.dart';
import 'time_slider_bar.dart';
import '../../../core/theme/command_center_theme.dart';
import '../../../core/widgets/provenance_widgets.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _sliderAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().load();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    final vm = context.read<DashboardViewModel>();
    vm.setSliderValue(value);
    _sliderAnim?.removeListener(_onAnimTick);
    _sliderAnim = Tween<double>(
      begin: vm.animatedProgress,
      end: value,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _sliderAnim!.addListener(_onAnimTick);
    _animController.forward(from: 0);
  }

  void _onAnimTick() {
    if (_sliderAnim == null) return;
    context.read<DashboardViewModel>().setAnimatedProgress(_sliderAnim!.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('dashboard_scaffold'),
      body: ListenableBuilder(
        listenable: context.watch<DashboardViewModel>(),
        builder: (context, _) {
          final vm = context.read<DashboardViewModel>();

          if (vm.isLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: CommandCenterTheme.accent),
                  SizedBox(height: 16),
                  Text('衛星データを読み込み中...', style: TextStyle(color: CommandCenterTheme.textMuted)),
                ],
              ),
            );
          }

          if (vm.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: CommandCenterTheme.accentWarm, size: 48),
                    const SizedBox(height: 12),
                    Text(vm.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text(
                      '先に scripts/fetch_tellus_data.py を実行してください。',
                      style: TextStyle(color: CommandCenterTheme.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          if (vm.regions.isEmpty) {
            return const Center(child: Text('観測データがありません'));
          }

          final totalObs = vm.regions.fold<int>(
            0,
            (sum, r) => sum + (r.observationCount ?? r.observations.length),
          );

          return Column(
            children: [
              _Header(generatedAt: vm.snapshot?.generatedAt ?? ''),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: const HeroClaimBar(
                  icon: Icons.satellite_alt,
                  title: 'SARの強み',
                  subtitle: '雲や夜間でも「いつ・どこを撮影したか」を記録。インフラの変化を時系列でたどれます。',
                  trailing: ProvenanceBadge(provenance: DataProvenance.demo, compact: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SummaryCard(
                  qualityReport: vm.qualityReport,
                  insights: vm.summaryInsights,
                  regionCount: vm.regions.length,
                  totalObservations: totalObs,
                ),
              ),
              if (vm.snapshot?.dataDisclaimer != null &&
                  vm.snapshot!.dataDisclaimer!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: DataProvenanceBanner(
                    message: vm.snapshot!.dataDisclaimer!,
                    provenance: DataProvenance.demo,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _ControlBar(viewModel: vm),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: MapPanel(regions: vm.regions, viewModel: vm),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SidePanel(viewModel: vm),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TimeSliderBar(viewModel: vm, onChanged: _onSliderChanged),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1180;
        return Row(
          children: [
            SegmentedButton<ViewMode>(
              segments: const [
                ButtonSegment(value: ViewMode.explorer, label: Text('Explorer'), icon: Icon(Icons.explore, size: 16)),
                ButtonSegment(value: ViewMode.analyst, label: Text('Analyst'), icon: Icon(Icons.analytics, size: 16)),
              ],
              selected: {viewModel.viewMode},
              onSelectionChanged: (s) => viewModel.setViewMode(s.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final s in DemoScenario.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(_scenarioLabel(s, viewModel)),
                          selected: viewModel.scenario == s,
                          onSelected: (_) => viewModel.setScenario(s),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            const TemplateSwitcher(),
            if (compact)
              PopupMenuButton<String>(
                tooltip: 'その他の画面',
                icon: const Icon(Icons.more_horiz, size: 20),
                onSelected: (value) => _navigate(context, value, viewModel),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'catalog', child: Text('データカタログ')),
                  PopupMenuItem(value: 'disaster', child: Text('災害アーカイブ')),
                  PopupMenuItem(value: 'multi', child: Text('マルチセンサー')),
                  PopupMenuItem(value: 'tellusar', child: Text('TelluSAR InSAR')),
                  PopupMenuItem(value: 'architecture', child: Text('システム解説')),
                  PopupMenuItem(value: 'procurement', child: Text('調達デモ')),
                ],
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.list_alt, size: 20),
                tooltip: 'カタログ',
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const CatalogPage())),
              ),
              IconButton(
                key: const ValueKey('nav_disaster_archive'),
                icon: const Icon(Icons.warning_amber, size: 20),
                tooltip: '災害アーカイブ',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DisasterArchivePage())),
              ),
              IconButton(
                key: const ValueKey('nav_multi_sensor'),
                icon: const Icon(Icons.compare, size: 20),
                tooltip: 'マルチセンサー比較',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MultiSensorPage())),
              ),
              IconButton(
                key: const ValueKey('nav_tellusar'),
                icon: const Icon(Icons.science, size: 20),
                tooltip: 'TelluSAR InSAR デモ',
                onPressed: () => _openTellusar(context, viewModel),
              ),
              IconButton(
                icon: const Icon(Icons.account_tree, size: 20),
                tooltip: 'アーキテクチャ',
                onPressed: () => showArchitectureExplainerOverlay(context),
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                tooltip: '調達デモ',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProcurementPage())),
              ),
            ],
          ],
        );
      },
    );
  }

  void _navigate(BuildContext context, String value, DashboardViewModel vm) {
    switch (value) {
      case 'catalog':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogPage()));
      case 'disaster':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DisasterArchivePage()));
      case 'multi':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MultiSensorPage()));
      case 'tellusar':
        _openTellusar(context, vm);
      case 'architecture':
        showArchitectureExplainerOverlay(context);
      case 'procurement':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProcurementPage()));
    }
  }

  void _openTellusar(BuildContext context, DashboardViewModel vm) {
    final pair = _pairFromSnapshot(vm);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TellusarPage(defaultPair: pair),
      ),
    );
  }

  TellusarPairRequest _pairFromSnapshot(DashboardViewModel vm) {
    final suggested = vm.tellusarSuggestedPair;
    if (suggested != null) {
      return TellusarPairRequest(
        referenceSceneId: suggested['referenceSceneId']?.toString() ??
            suggested['reference']?.toString() ?? 'DEMO-REFERENCE',
        secondarySceneId: suggested['secondarySceneId']?.toString() ??
            suggested['secondary']?.toString() ?? 'DEMO-SECONDARY',
        regionId: suggested['regionId']?.toString() ??
            vm.selectedRegionId,
        label: suggested['label']?.toString() ?? 'InSAR ペア',
      );
    }
    final region = vm.selectedRegion;
    if (region != null && region.observations.length >= 2) {
      final ref = region.observations.first;
      final sec = region.observations[1];
      return TellusarPairRequest(
        referenceSceneId: ref.dataId,
        secondarySceneId: sec.dataId,
        regionId: region.id,
        label: '${region.name} 観測ペア',
      );
    }
    return const TellusarPairRequest(
      referenceSceneId: 'DEMO-REFERENCE',
      secondarySceneId: 'DEMO-SECONDARY',
      regionId: 'demo',
      label: 'デモペア',
    );
  }

  String _scenarioLabel(DemoScenario s, DashboardViewModel vm) {
    final base = switch (s) {
      DemoScenario.embankment => '堤防',
      DemoScenario.slope => '斜面',
      DemoScenario.rainySeason => '梅雨',
      DemoScenario.longTerm => '長期(90日)',
    };
    if (s == DemoScenario.embankment || s == DemoScenario.slope) return base;
    final count = vm.filteredCountFor(vm.selectedRegion);
    return '$base ($count)';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.generatedAt});

  final String generatedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CommandCenterTheme.border)),
        gradient: LinearGradient(colors: [Color(0xFF0F1A2B), Color(0xFF0B1220)]),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: CommandCenterTheme.accent.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.radar, color: CommandCenterTheme.accent),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'dashboard-header',
                child: const Text(
                  key: ValueKey('dashboard_header'),
                  'TELLUS INFRASTRUCTURE MONITOR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: CommandCenterTheme.textPrimary,
                  ),
                ),
              ),
              const Text(
                '富山県インフラ SAR 衛星監視デモ',
                style: TextStyle(fontSize: 12, color: CommandCenterTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: 'システム構成・データフロー・設計の強みを解説',
            child: FilledButton.tonalIcon(
            onPressed: () => showArchitectureExplainerOverlay(context, tutorial: true),
            icon: const Icon(Icons.layers, size: 18),
            label: const Text('システム解説'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: CommandCenterTheme.accent,
              backgroundColor: CommandCenterTheme.accent.withValues(alpha: 0.12),
            ),
          ),
          ),
          const Spacer(),
          const ProvenanceBadge(provenance: DataProvenance.demo, compact: true),
          const SizedBox(width: 8),
          if (generatedAt.isNotEmpty)
            Text(
              '更新: ${_formatGeneratedAt(generatedAt)}',
              style: const TextStyle(fontSize: 10, color: CommandCenterTheme.textMuted),
            ),
        ],
      ),
    );
  }
}


String _formatGeneratedAt(String raw) {
  try {
    final dt = DateTime.parse(raw).toLocal();
    return DateFormat('yyyy/MM/dd HH:mm').format(dt);
  } catch (_) {
    return raw.length > 19 ? raw.substring(0, 19) : raw;
  }
}
