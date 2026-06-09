import 'package:flutter/material.dart';

import '../../../../domain/models/disaster_event.dart';
import '../../../core/theme/command_center_theme.dart';
import 'disaster_phase_thumbnail.dart';

/// 災害イベントの before / during / after を並列比較、またはスライダー比較で表示。
class DisasterPhaseComparison extends StatelessWidget {
  const DisasterPhaseComparison({
    super.key,
    required this.event,
    required this.selectedPhase,
    required this.comparisonMode,
    required this.onPhaseSelected,
    required this.onComparisonModeChanged,
  });

  final DisasterEvent event;
  final DisasterPhaseLabel selectedPhase;
  final DisasterComparisonMode comparisonMode;
  final ValueChanged<DisasterPhaseLabel> onPhaseSelected;
  final ValueChanged<DisasterComparisonMode> onComparisonModeChanged;

  static const _phaseOrder = [
    DisasterPhaseLabel.before,
    DisasterPhaseLabel.during,
    DisasterPhaseLabel.after,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SarValueBanner(event: event),
        if (event.spatiallyAligned) ...[
          const SizedBox(height: 8),
          const _SpatialAlignmentBadge(),
        ],
        const SizedBox(height: 12),
        _ComparisonModeToggle(
          mode: comparisonMode,
          onChanged: onComparisonModeChanged,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: comparisonMode == DisasterComparisonMode.grid
              ? _ThreeColumnGrid(
                  event: event,
                  selectedPhase: selectedPhase,
                  onPhaseSelected: onPhaseSelected,
                )
              : _SliderComparison(event: event),
        ),
        const SizedBox(height: 8),
        const _DemoHighlightDisclaimer(),
      ],
    );
  }
}

/// 並列表示 / スライダー比較の切替モード。
enum DisasterComparisonMode { grid, slider }

class _SpatialAlignmentBadge extends StatelessWidget {
  const _SpatialAlignmentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CommandCenterTheme.accent.withValues(alpha: 0.1),
        border: Border.all(
          color: CommandCenterTheme.accent.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.my_location, size: 14, color: CommandCenterTheme.accent),
          SizedBox(width: 6),
          Text(
            '同一地点の 3 フェーズ比較',
            style: TextStyle(fontSize: 10, color: CommandCenterTheme.accent),
          ),
        ],
      ),
    );
  }
}

class _SarValueBanner extends StatelessWidget {
  const _SarValueBanner({required this.event});

  final DisasterEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CommandCenterTheme.accent.withValues(alpha: 0.12),
            CommandCenterTheme.accentWarm.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
            color: CommandCenterTheme.accent.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar, size: 20, color: CommandCenterTheme.accent),
              SizedBox(width: 8),
              Text(
                'SARの強み',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            event.demoFocus,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CommandCenterTheme.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.summary,
            style: const TextStyle(fontSize: 11, height: 1.45),
          ),
          const SizedBox(height: 10),
          const _OpticalVsSarHint(),
        ],
      ),
    );
  }
}

class _OpticalVsSarHint extends StatelessWidget {
  const _OpticalVsSarHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _hintChip(
          icon: Icons.cloud_off,
          label: '光学',
          detail: '雲・夜間で見えない',
          color: CommandCenterTheme.textMuted,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward, size: 14, color: CommandCenterTheme.textMuted),
        ),
        _hintChip(
          icon: Icons.satellite_alt,
          label: 'SAR',
          detail: '全天候・昼夜観測',
          color: CommandCenterTheme.accent,
        ),
      ],
    );
  }

  Widget _hintChip({
    required IconData icon,
    required String label,
    required String detail,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: CommandCenterTheme.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: CommandCenterTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color)),
                  Text(detail,
                      style: const TextStyle(
                          fontSize: 10, color: CommandCenterTheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonModeToggle extends StatelessWidget {
  const _ComparisonModeToggle({
    required this.mode,
    required this.onChanged,
  });

  final DisasterComparisonMode mode;
  final ValueChanged<DisasterComparisonMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DisasterComparisonMode>(
      segments: const [
        ButtonSegment(
          value: DisasterComparisonMode.grid,
          label: Text('3フェーズ比較'),
          icon: Icon(Icons.view_column, size: 16),
        ),
        ButtonSegment(
          value: DisasterComparisonMode.slider,
          label: Text('比較モード'),
          icon: Icon(Icons.compare, size: 16),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11)),
      ),
    );
  }
}

class _ThreeColumnGrid extends StatelessWidget {
  const _ThreeColumnGrid({
    required this.event,
    required this.selectedPhase,
    required this.onPhaseSelected,
  });

  final DisasterEvent event;
  final DisasterPhaseLabel selectedPhase;
  final ValueChanged<DisasterPhaseLabel> onPhaseSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: DisasterPhaseComparison._phaseOrder.map((label) {
        final phase = event.phaseFor(label);
        final isDuring = label == DisasterPhaseLabel.during;
        final isSelected = label == selectedPhase;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: label != DisasterPhaseLabel.after ? 8 : 0,
            ),
            child: _PhaseColumn(
              label: label,
              phase: phase,
              eventId: event.id,
              highlighted: isDuring,
              selected: isSelected,
              showDemoOverlay: isDuring ||
                  label == DisasterPhaseLabel.after,
              onTap: () => onPhaseSelected(label),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PhaseColumn extends StatelessWidget {
  const _PhaseColumn({
    required this.label,
    required this.phase,
    required this.eventId,
    required this.highlighted,
    required this.selected,
    required this.showDemoOverlay,
    required this.onTap,
  });

  final DisasterPhaseLabel label;
  final DisasterPhase? phase;
  final String eventId;
  final bool highlighted;
  final bool selected;
  final bool showDemoOverlay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = _phaseBadgeStyle(label);
    final borderColor = highlighted
        ? CommandCenterTheme.accentWarm
        : selected
            ? CommandCenterTheme.accent
            : CommandCenterTheme.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: CommandCenterTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: highlighted ? 2 : 1,
            ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: CommandCenterTheme.accentWarm
                          .withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badge.bg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge.title,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badge.fg,
                        ),
                      ),
                    ),
                    if (highlighted) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.emergency,
                          size: 12, color: CommandCenterTheme.accentWarm),
                    ],
                  ],
                ),
              ),
              if (phase != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Text(
                    phase!.acquisitionDate,
                    style: const TextStyle(
                        fontSize: 10, color: CommandCenterTheme.textMuted),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: phase != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              buildDisasterPhaseThumbnail(phase!.thumbnailUrl),
                              if (showDemoOverlay)
                                _DemoChangeOverlayFixed(eventId: eventId),
                            ],
                          ),
                        )
                      : const Center(
                          child: Text('データなし',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: CommandCenterTheme.textMuted)),
                        ),
                ),
              ),
              if (phase != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(
                    phase!.note,
                    style: const TextStyle(fontSize: 10, height: 1.35),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseBadgeStyle {
  const _PhaseBadgeStyle(this.title, this.bg, this.fg);
  final String title;
  final Color bg;
  final Color fg;
}

_PhaseBadgeStyle _phaseBadgeStyle(DisasterPhaseLabel label) {
  switch (label) {
    case DisasterPhaseLabel.before:
      return _PhaseBadgeStyle(
        '事前',
        const Color(0xFF1E3A5F).withValues(alpha: 0.8),
        const Color(0xFF7EB8DA),
      );
    case DisasterPhaseLabel.during:
      return _PhaseBadgeStyle(
        '当日',
        CommandCenterTheme.accentWarm.withValues(alpha: 0.25),
        CommandCenterTheme.accentWarm,
      );
    case DisasterPhaseLabel.after:
      return _PhaseBadgeStyle(
        '事後',
        const Color(0xFF14532D).withValues(alpha: 0.5),
        const Color(0xFF4ADE80),
      );
  }
}

/// イベント別のデモ用変化ハイライト領域（正規化座標 0–1）。
List<Rect> _demoHighlightRegions(String eventId) {
  switch (eventId) {
    case 'noto_2024':
      return [
        const Rect.fromLTWH(0.15, 0.35, 0.55, 0.35),
        const Rect.fromLTWH(0.55, 0.55, 0.30, 0.25),
      ];
    case 'nishinihon_2018':
      return [
        const Rect.fromLTWH(0.20, 0.40, 0.50, 0.40),
      ];
    case 'atami_2021':
      return [
        const Rect.fromLTWH(0.25, 0.30, 0.45, 0.45),
      ];
    default:
      return [const Rect.fromLTWH(0.30, 0.35, 0.40, 0.30)];
  }
}

class _DemoChangeOverlayFixed extends StatelessWidget {
  const _DemoChangeOverlayFixed({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    final regions = _demoHighlightRegions(eventId);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            ...regions.map(
              (r) => Positioned(
                left: r.left * w,
                top: r.top * h,
                width: r.width * w,
                height: r.height * h,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          CommandCenterTheme.dataDemo.withValues(alpha: 0.75),
                      width: 2,
                    ),
                    color:
                        CommandCenterTheme.dataDemo.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '変化',
                  style: TextStyle(
                      fontSize: 9, color: CommandCenterTheme.dataDemo),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DemoHighlightDisclaimer extends StatelessWidget {
  const _DemoHighlightDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CommandCenterTheme.dataDemo.withValues(alpha: 0.06),
        border: Border.all(
            color: CommandCenterTheme.dataDemo.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline,
              size: 14, color: CommandCenterTheme.dataDemo),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'デモ用 変化ハイライト（実解析ではありません）',
              style: TextStyle(
                  fontSize: 10, color: CommandCenterTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderComparison extends StatefulWidget {
  const _SliderComparison({required this.event});

  final DisasterEvent event;

  @override
  State<_SliderComparison> createState() => _SliderComparisonState();
}

class _SliderComparisonState extends State<_SliderComparison> {
  double _split = 0.5;

  @override
  Widget build(BuildContext context) {
    final before = widget.event.phaseFor(DisasterPhaseLabel.before);
    final during = widget.event.phaseFor(DisasterPhaseLabel.during);

    if (before == null || during == null) {
      return const Center(child: Text('比較に必要なフェーズデータがありません'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _sliderLabel('事前', before.acquisitionDate, const Color(0xFF7EB8DA)),
            const Spacer(),
            const Text('← スライドで比較 →',
                style: TextStyle(
                    fontSize: 10, color: CommandCenterTheme.textMuted)),
            const Spacer(),
            _sliderLabel('当日', during.acquisitionDate,
                CommandCenterTheme.accentWarm),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final splitPx = constraints.maxWidth * _split;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    buildDisasterPhaseThumbnail(during.thumbnailUrl),
                    ClipRect(
                      clipper: _LeftClipper(splitPx),
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: buildDisasterPhaseThumbnail(before.thumbnailUrl),
                      ),
                    ),
                    _DemoChangeOverlayFixed(eventId: widget.event.id),
                    Positioned(
                      left: splitPx - 1,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 3,
                        color: CommandCenterTheme.accentWarm,
                      ),
                    ),
                    Positioned(
                      left: splitPx - 14,
                      top: constraints.maxHeight / 2 - 14,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: CommandCenterTheme.accentWarm,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.compare_arrows,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Slider(
          value: _split,
          onChanged: (v) => setState(() => _split = v),
          activeColor: CommandCenterTheme.accentWarm,
        ),
        Row(
          children: [
            Expanded(
              child: Text(before.note,
                  style: const TextStyle(fontSize: 10), maxLines: 2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(during.note,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 10), maxLines: 2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sliderLabel(String title, String date, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        Text(date,
            style: const TextStyle(
                fontSize: 10, color: CommandCenterTheme.textMuted)),
      ],
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper(this.width);
  final double width;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, width, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => old.width != width;
}
