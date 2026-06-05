import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/disaster_event.dart';
import '../../../../domain/repositories/disaster_archive_repository.dart';
import '../../../core/theme/command_center_theme.dart';
import '../view_models/disaster_archive_view_model.dart';
import '../widgets/disaster_phase_preview.dart';

/// 災害アーカイブページ。
/// before/during/after の Tellus 観測を並べ、SAR の雲・夜間貫通性を訴求する。
class DisasterArchivePage extends StatelessWidget {
  const DisasterArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DisasterArchiveViewModel>(
      create: (ctx) => DisasterArchiveViewModel(
        repository: ctx.read<DisasterArchiveRepository>(),
      )..load(),
      child: const _DisasterArchiveScaffold(),
    );
  }
}

class _DisasterArchiveScaffold extends StatelessWidget {
  const _DisasterArchiveScaffold();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DisasterArchiveViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('災害アーカイブ — Tellus でこう見えた'),
        backgroundColor: CommandCenterTheme.panel,
      ),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, DisasterArchiveViewModel vm) {
    if (vm.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: CommandCenterTheme.accent));
    }
    if (vm.error != null) {
      return Center(child: Text('エラー: ${vm.error}'));
    }
    if (vm.events.isEmpty) {
      return const Center(child: Text('災害イベントがありません'));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 260,
            child:
                _EventList(events: vm.events, selectedId: vm.selectedEvent?.id),
          ),
          const SizedBox(width: 16),
          Expanded(child: _EventDetail(vm: vm)),
        ],
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({required this.events, required this.selectedId});

  final List<DisasterEvent> events;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<DisasterArchiveViewModel>();
    return Card(
      color: CommandCenterTheme.panel,
      child: ListView.separated(
        itemCount: events.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final e = events[i];
          final selected = e.id == selectedId;
          return ListTile(
            key: ValueKey('disaster_item_${e.id}'),
            selected: selected,
            selectedTileColor:
                CommandCenterTheme.accent.withValues(alpha: 0.12),
            title: Text(e.name,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(e.demoFocus,
                style: const TextStyle(
                    fontSize: 11, color: CommandCenterTheme.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            onTap: () => vm.selectEvent(e.id),
          );
        },
      ),
    );
  }
}

class _EventDetail extends StatelessWidget {
  const _EventDetail({required this.vm});

  final DisasterArchiveViewModel vm;

  @override
  Widget build(BuildContext context) {
    final event = vm.selectedEvent;
    if (event == null) return const SizedBox.shrink();
    return Card(
      color: CommandCenterTheme.panel,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber,
                    color: CommandCenterTheme.accentWarm),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  event.eventDatetime.split('T').first,
                  style: const TextStyle(
                      fontSize: 12, color: CommandCenterTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(event.summary,
                style: const TextStyle(fontSize: 12, height: 1.5)),
            const SizedBox(height: 4),
            Text(
                '観測中心: ${event.lat.toStringAsFixed(3)}°N, ${event.lon.toStringAsFixed(3)}°E',
                style: const TextStyle(
                    fontSize: 11, color: CommandCenterTheme.textMuted)),
            const SizedBox(height: 16),
            _PhaseSelector(vm: vm),
            const SizedBox(height: 12),
            Expanded(child: _PhasePanel(phase: vm.selectedPhaseData)),
          ],
        ),
      ),
    );
  }
}

class _PhaseSelector extends StatelessWidget {
  const _PhaseSelector({required this.vm});
  final DisasterArchiveViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DisasterPhaseLabel>(
      segments: const [
        ButtonSegment(value: DisasterPhaseLabel.before, label: Text('事前 (Before)')),
        ButtonSegment(value: DisasterPhaseLabel.during, label: Text('当日 (During)')),
        ButtonSegment(value: DisasterPhaseLabel.after, label: Text('事後 (After)')),
      ],
      selected: {vm.selectedPhase},
      onSelectionChanged: (s) => vm.selectPhase(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _PhasePanel extends StatelessWidget {
  const _PhasePanel({required this.phase});
  final DisasterPhase? phase;

  @override
  Widget build(BuildContext context) {
    final current = phase;
    if (current == null) {
      return const Center(child: Text('このフェーズのデータはありません'));
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: CommandCenterTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.satellite_alt,
                size: 18, color: CommandCenterTheme.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(current.note,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: DisasterPhasePreview(phase: current),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetaRow(label: 'シーン ID', value: current.sceneId),
                        _MetaRow(label: 'データセット', value: current.datasetId),
                        _MetaRow(label: '取得日時', value: current.acquisitionDatetime),
                        _MetaRow(label: '軌道', value: current.orbitDirection),
                        _MetaRow(label: '偏波', value: current.polarization),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CommandCenterTheme.accent.withValues(alpha: 0.06),
              border: Border.all(
                  color: CommandCenterTheme.accent.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '※ サムネイルはデモ用合成 PNG。シーン ID・取得時刻も合成データです。'
              'Tellus dataset ID は実在。本番ラスタは BFF 経由で取得します。',
              style: TextStyle(
                  fontSize: 11, color: CommandCenterTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: CommandCenterTheme.textMuted)),
          ),
          Expanded(
            child: SelectableText(value,
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
