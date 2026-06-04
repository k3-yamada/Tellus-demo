import 'package:flutter/material.dart';

import '../../../core/theme/command_center_theme.dart';
import 'architecture_data_flow.dart';
import 'architecture_design_benefits.dart';
import 'architecture_flow_diagram.dart';

class ArchitectureExplainerPanel extends StatefulWidget {
  const ArchitectureExplainerPanel({
    super.key,
    this.tutorialMode = false,
    this.initialTabIndex = 0,
  });

  final bool tutorialMode;
  final int initialTabIndex;

  @override
  State<ArchitectureExplainerPanel> createState() => _ArchitectureExplainerPanelState();
}

class _ArchitectureExplainerPanelState extends State<ArchitectureExplainerPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _tutorialStep = 0;

  static const _tabLabels = ['構成図', 'データフロー', '設計の強み'];

  @override
  void initState() {
    super.initState();
    final index = widget.initialTabIndex.clamp(0, _tabLabels.length - 1);
    _tabController = TabController(length: _tabLabels.length, vsync: this, initialIndex: index);
    _pageController = PageController(initialPage: index);
    _tutorialStep = index;
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (widget.tutorialMode && _pageController.hasClients) {
      _pageController.animateToPage(
        _tabController.index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    setState(() => _tutorialStep = _tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTutorialPageChanged(int index) {
    setState(() => _tutorialStep = index);
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabController,
          labelColor: CommandCenterTheme.accent,
          unselectedLabelColor: CommandCenterTheme.textMuted,
          indicatorColor: CommandCenterTheme.accent,
          dividerColor: CommandCenterTheme.border,
          tabs: [for (final l in _tabLabels) Tab(text: l)],
        ),
        Expanded(
          child: widget.tutorialMode ? _buildTutorialBody() : _buildTabBody(),
        ),
        if (widget.tutorialMode) _TutorialStepIndicator(step: _tutorialStep, total: _tabLabels.length),
      ],
    );
  }

  Widget _buildTabBody() {
    return TabBarView(
      controller: _tabController,
      children: const [
        _ScrollableTab(child: ArchitectureFlowDiagram()),
        _ScrollableTab(child: ArchitectureDataFlow()),
        _ScrollableTab(child: ArchitectureDesignBenefits()),
      ],
    );
  }

  Widget _buildTutorialBody() {
    return PageView(
      controller: _pageController,
      onPageChanged: _onTutorialPageChanged,
      children: const [
        _ScrollableTab(child: ArchitectureFlowDiagram()),
        _ScrollableTab(child: ArchitectureDataFlow()),
        _ScrollableTab(child: ArchitectureDesignBenefits()),
      ],
    );
  }
}

class _ScrollableTab extends StatelessWidget {
  const _ScrollableTab({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _TutorialStepIndicator extends StatelessWidget {
  const _TutorialStepIndicator({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CommandCenterTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ステップ ${step + 1} / $total',
            style: const TextStyle(fontSize: 12, color: CommandCenterTheme.textMuted),
          ),
          const SizedBox(width: 12),
          for (var i = 0; i < total; i++)
            Container(
              width: i == step ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i == step ? CommandCenterTheme.accent : CommandCenterTheme.border,
              ),
            ),
        ],
      ),
    );
  }
}
