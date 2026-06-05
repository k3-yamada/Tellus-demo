import 'package:flutter/material.dart';

import '../view_models/dashboard_view_model.dart';
import '../../../core/theme/command_center_theme.dart';

class TimeSliderBar extends StatefulWidget {
  const TimeSliderBar({
    super.key,
    required this.viewModel,
    required this.onChanged,
  });

  final DashboardViewModel viewModel;
  final ValueChanged<double> onChanged;

  @override
  State<TimeSliderBar> createState() => _TimeSliderBarState();
}

class _TimeSliderBarState extends State<TimeSliderBar> {
  @override
  Widget build(BuildContext context) {
    final maxIndex = widget.viewModel.maxSliderIndex;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: CommandCenterTheme.accent, size: 18),
                const SizedBox(width: 8),
                Semantics(
                  label: '衛星観測タイムライン',
                  child: const Text(
                    '衛星観測タイムライン',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CommandCenterTheme.textPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    widget.viewModel.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: CommandCenterTheme.accentWarm,
                  ),
                  tooltip: widget.viewModel.isPlaying ? '一時停止' : '再生',
                  onPressed: maxIndex > 0 ? _togglePlay : null,
                ),
                Text(
                  key: const ValueKey('timeline_date_label'),
                  widget.viewModel.currentDateLabel,
                  style: const TextStyle(
                    color: CommandCenterTheme.accentWarm,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final tickIndices = widget.viewModel
                    .thumbnailSliderIndicesFor(widget.viewModel.selectedRegion);
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: CommandCenterTheme.accent,
                        inactiveTrackColor: CommandCenterTheme.border,
                        thumbColor: CommandCenterTheme.accentWarm,
                        overlayColor:
                            CommandCenterTheme.accent.withValues(alpha: 0.15),
                      ),
                      child: Semantics(
                        label: 'timeline-slider',
                        child: Slider(
                          key: const ValueKey('timeline_slider'),
                          value: widget.viewModel.sliderValue
                              .clamp(0, maxIndex.toDouble()),
                          min: 0,
                          max: maxIndex.toDouble(),
                          divisions: maxIndex > 0 ? maxIndex : 1,
                          onChanged: maxIndex > 0 ? widget.onChanged : null,
                        ),
                      ),
                    ),
                    if (maxIndex > 0 && tickIndices.isNotEmpty)
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 18,
                        height: 6,
                        child: IgnorePointer(
                          child: _ThumbnailTickOverlay(
                            width: constraints.maxWidth - 32,
                            maxIndex: maxIndex,
                            tickIndices: tickIndices,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (widget.viewModel.timelineYearStart != null &&
                widget.viewModel.timelineYearEnd != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.viewModel.timelineYearStart}年',
                    style: const TextStyle(fontSize: 10, color: CommandCenterTheme.textMuted),
                  ),
                  Text(
                    '${widget.viewModel.timelineYearEnd}年',
                    style: const TextStyle(fontSize: 10, color: CommandCenterTheme.textMuted),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _togglePlay() {
    if (widget.viewModel.isPlaying) {
      widget.viewModel.setPlaying(false);
      return;
    }
    widget.viewModel.setPlaying(true);
    _stepForward();
  }

  void _stepForward() {
    if (!widget.viewModel.isPlaying) return;
    final max = widget.viewModel.maxSliderIndex.toDouble();
    final next = (widget.viewModel.sliderValue + 1).clamp(0, max).toDouble();
    widget.onChanged(next);
    if (next >= max) {
      widget.viewModel.setPlaying(false);
      return;
    }
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && widget.viewModel.isPlaying) _stepForward();
    });
  }
}


class _ThumbnailTickOverlay extends StatelessWidget {
  const _ThumbnailTickOverlay({
    required this.width,
    required this.maxIndex,
    required this.tickIndices,
  });

  final double width;
  final int maxIndex;
  final List<int> tickIndices;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, 6),
      painter: _ThumbnailTickPainter(
        maxIndex: maxIndex,
        tickIndices: tickIndices,
      ),
    );
  }
}

class _ThumbnailTickPainter extends CustomPainter {
  _ThumbnailTickPainter({required this.maxIndex, required this.tickIndices});

  final int maxIndex;
  final List<int> tickIndices;

  @override
  void paint(Canvas canvas, Size size) {
    if (maxIndex <= 0) return;
    final paint = Paint()
      ..color = CommandCenterTheme.accent.withValues(alpha: 0.85)
      ..strokeWidth = 1;
    for (final index in tickIndices) {
      final t = index / maxIndex;
      final x = t * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThumbnailTickPainter oldDelegate) {
    return oldDelegate.maxIndex != maxIndex ||
        oldDelegate.tickIndices != tickIndices;
  }
}
