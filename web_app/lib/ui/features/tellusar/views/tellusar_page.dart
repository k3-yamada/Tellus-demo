import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/tellusar_job.dart';
import '../../../../domain/repositories/tellusar_repository.dart';
import '../../../core/theme/command_center_theme.dart';
import '../../../core/widgets/provenance_widgets.dart';
import '../view_models/tellusar_view_model.dart';

/// TelluSAR ジョブを「実投入 → ポーリング → 結果サマリー」まで一画面で見せる。
/// BFF が未設定 / 失敗時はリポジトリが擬似結果を返すため、デモは常に完走する。
class TellusarPage extends StatelessWidget {
  const TellusarPage({super.key, required this.defaultPair});

  final TellusarPairRequest defaultPair;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TellusarViewModel>(
      create: (ctx) => TellusarViewModel(
        repository: ctx.read<TellusarRepository>(),
        defaultPair: defaultPair,
      ),
      child: const _TellusarScaffold(),
    );
  }
}

class _TellusarScaffold extends StatelessWidget {
  const _TellusarScaffold();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TellusarViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('TelluSAR InSAR デモ'),
        backgroundColor: CommandCenterTheme.panel,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeroClaimBar(
              icon: Icons.science,
              title: 'InSAR 干渉解析デモ',
              subtitle: '2時期の SAR 画像から地盤変位を推定する流れを体験できます。結果は dry-run または擬似値の場合があります。',
            ),
            const SizedBox(height: 12),
            _PairCard(pair: vm.pair),
            const SizedBox(height: 16),
            _SubmitRow(vm: vm),
            const SizedBox(height: 20),
            _JobPanel(job: vm.job, error: vm.error),
          ],
        ),
      ),
    );
  }
}

class _PairCard extends StatelessWidget {
  const _PairCard({required this.pair});
  final TellusarPairRequest pair;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: CommandCenterTheme.panel,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('InSAR ペア (推奨候補)',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            _row('対象地域', pair.regionId),
            _row('ペア種別', pair.label),
            _row('参照シーン', pair.referenceSceneId),
            _row('副シーン', pair.secondarySceneId),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: CommandCenterTheme.textMuted)),
            ),
            Expanded(
                child: SelectableText(value,
                    style: const TextStyle(fontSize: 12))),
          ],
        ),
      );
}

class _SubmitRow extends StatelessWidget {
  const _SubmitRow({required this.vm});
  final TellusarViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.icon(
          key: const ValueKey('tellusar_submit_btn'),
          onPressed: vm.isBusy ? null : () => vm.submit(),
          icon: const Icon(Icons.play_arrow),
          label: Text(vm.isBusy ? '送信中…' : 'TelluSAR ジョブ投入 (dry-run)'),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'BFF 経由で TelluSAR /jobs に X-Demo-Dry-Run で送信。未設定 / 失敗時は擬似結果にフォールバック。',
            style:
                TextStyle(fontSize: 11, color: CommandCenterTheme.textMuted),
          ),
        ),
      ],
    );
  }
}

class _JobPanel extends StatelessWidget {
  const _JobPanel({required this.job, required this.error});
  final TellusarJob? job;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CommandCenterTheme.accentWarm.withValues(alpha: 0.12),
          border: Border.all(color: CommandCenterTheme.accentWarm),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('エラー: $error'),
      );
    }
    if (job == null) {
      return const Text(
        'ボタンを押すと dry-run で TelluSAR ジョブを投入します。',
        style:
            TextStyle(fontSize: 12, color: CommandCenterTheme.textMuted),
      );
    }
    return Card(
      color: CommandCenterTheme.panel,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science,
                    color: CommandCenterTheme.accent),
                const SizedBox(width: 8),
                Text('ジョブ ${job!.jobId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                _StatusChip(status: job!.status),
              ],
            ),
            if (job!.statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(job!.statusMessage!,
                  style: const TextStyle(
                      fontSize: 11,
                      color: CommandCenterTheme.textMuted)),
            ],
            const SizedBox(height: 12),
            if (job!.result != null)
              _InterferogramSummary(result: job!.result!, synthetic: job!.isSyntheticResult),
            if (job!.status == TellusarJobStatus.queued ||
                job!.status == TellusarJobStatus.running)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(
                    color: CommandCenterTheme.accent),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final TellusarJobStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TellusarJobStatus.queued => ('QUEUED', CommandCenterTheme.accent),
      TellusarJobStatus.running => ('RUNNING', CommandCenterTheme.accent),
      TellusarJobStatus.succeeded => ('SUCCEEDED', Colors.greenAccent),
      TellusarJobStatus.failed => ('FAILED', CommandCenterTheme.accentWarm),
      _ => ('IDLE', CommandCenterTheme.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _InterferogramSummary extends StatelessWidget {
  const _InterferogramSummary({required this.result, required this.synthetic});
  final TellusarInterferogram result;
  final bool synthetic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CommandCenterTheme.accent.withValues(alpha: 0.06),
        border: Border.all(
            color: CommandCenterTheme.accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('干渉解析サマリー',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              ProvenanceBadge(
                provenance: synthetic ? DataProvenance.demo : DataProvenance.real,
                compact: true,
                tooltip: synthetic
                    ? 'BFF 未設定またはフォールバック時の擬似サマリーです'
                    : 'BFF 経由のジョブ結果です',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _kv('平均コヒーレンス', result.coherenceMean.toStringAsFixed(3)),
          _kv('最大変位',
              '${result.maxDisplacementMm.toStringAsFixed(2)} mm'),
          _kv('最小変位',
              '${result.minDisplacementMm.toStringAsFixed(2)} mm'),
          _kv('Perpendicular Baseline',
              '${result.perpendicularBaselineM.toStringAsFixed(1)} m'),
          _kv('Temporal Baseline', '${result.temporalBaselineDays} 日'),
          const SizedBox(height: 8),
          for (final n in result.notes)
            Text('・ $n',
                style: const TextStyle(
                    fontSize: 11,
                    color: CommandCenterTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
                width: 200,
                child: Text(k,
                    style: const TextStyle(
                        fontSize: 11,
                        color: CommandCenterTheme.textMuted))),
            Text(v,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
