import 'package:flutter/material.dart';

import '../theme/command_center_theme.dart';

enum DataProvenance {
  real('実データ', CommandCenterTheme.dataReal, Icons.verified_outlined),
  demo('デモ値', CommandCenterTheme.dataDemo, Icons.auto_awesome),
  mock('モック', CommandCenterTheme.dataMock, Icons.construction_outlined),
  bundled('バンドル画像', CommandCenterTheme.accent, Icons.image_outlined);

  const DataProvenance(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

class ProvenanceBadge extends StatelessWidget {
  const ProvenanceBadge({
    super.key,
    required this.provenance,
    this.compact = false,
    this.tooltip,
  });

  final DataProvenance provenance;
  final bool compact;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: provenance.color.withValues(alpha: 0.14),
        border: Border.all(color: provenance.color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(provenance.icon, size: compact ? 11 : 12, color: provenance.color),
          const SizedBox(width: 4),
          Text(
            provenance.label,
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
              color: provenance.color,
            ),
          ),
        ],
      ),
    );
    if (tooltip == null) return badge;
    return Tooltip(message: tooltip!, child: badge);
  }
}

class DataProvenanceBanner extends StatelessWidget {
  const DataProvenanceBanner({
    super.key,
    required this.message,
    this.provenance = DataProvenance.demo,
    this.icon = Icons.info_outline,
  });

  final String message;
  final DataProvenance provenance;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: provenance.color.withValues(alpha: 0.08),
        border: Border.all(color: provenance.color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: provenance.color),
          const SizedBox(width: 8),
          ProvenanceBadge(provenance: provenance, compact: true),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class CoverageMeter extends StatelessWidget {
  const CoverageMeter({
    super.key,
    required this.label,
    required this.numerator,
    required this.denominator,
    this.caption,
    this.accentColor = CommandCenterTheme.accent,
  });

  final String label;
  final int numerator;
  final int denominator;
  final String? caption;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final ratio = denominator <= 0 ? 0.0 : (numerator / denominator).clamp(0.0, 1.0);
    final pct = (ratio * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$pct% ($numerator/$denominator)',
              style: TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: CommandCenterTheme.border,
            color: accentColor,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(
            caption!,
            style: const TextStyle(fontSize: 10, color: CommandCenterTheme.textMuted, height: 1.35),
          ),
        ],
      ],
    );
  }
}

class HeroClaimBar extends StatelessWidget {
  const HeroClaimBar({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CommandCenterTheme.accent.withValues(alpha: 0.12),
            CommandCenterTheme.panel,
          ],
        ),
        border: Border.all(color: CommandCenterTheme.accent.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: CommandCenterTheme.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: CommandCenterTheme.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class MarkerIndexLegend extends StatelessWidget {
  const MarkerIndexLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CommandCenterTheme.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CommandCenterTheme.border),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('監視指数（デモ）', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text(
              '色＝安定(青緑) → 変動大(橙)',
              style: TextStyle(fontSize: 9, color: CommandCenterTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
