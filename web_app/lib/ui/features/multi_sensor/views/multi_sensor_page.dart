import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/multi_sensor.dart';
import '../../../../domain/repositories/multi_sensor_repository.dart';
import '../../../core/theme/command_center_theme.dart';
import '../../../core/widgets/provenance_widgets.dart';
import '../widgets/multi_sensor_scene_preview.dart';
import '../view_models/multi_sensor_view_model.dart';

/// マルチセンサー (SAR + 光学) 比較ページ。
/// Tellus は SAR だけではない、を視覚的に証明する。
class MultiSensorPage extends StatelessWidget {
  const MultiSensorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MultiSensorViewModel>(
      create: (ctx) => MultiSensorViewModel(
        repository: ctx.read<MultiSensorRepository>(),
      )..load(),
      child: const _Scaffold(),
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MultiSensorViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('マルチセンサー比較'),
        backgroundColor: CommandCenterTheme.panel,
      ),
      body: _body(context, vm),
    );
  }

  Widget _body(BuildContext context, MultiSensorViewModel vm) {
    if (vm.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: CommandCenterTheme.accent));
    }
    if (vm.error != null) return Center(child: Text('エラー: ${vm.error}'));
    if (vm.sensors.isEmpty) return const Center(child: Text('センサー定義がありません'));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeroClaimBar(
            icon: Icons.compare,
            title: 'SAR と光学の違い',
            subtitle: '同じ場所でもセンサーによって見え方が変わります。Tellus は SAR だけでなく光学データも扱えます。',
          ),
          const SizedBox(height: 12),
          if (vm.disclaimer != null && vm.disclaimer!.isNotEmpty)
            DataProvenanceBanner(
              message: vm.disclaimer!,
              provenance: DataProvenance.demo,
            ),
          if (vm.disclaimer != null && vm.disclaimer!.isNotEmpty)
            const SizedBox(height: 12),
          _SiteSelector(vm: vm),
          const SizedBox(height: 12),
          _ModalityFilter(vm: vm),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _ScenesPanel(vm: vm)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _SensorsPanel(vm: vm)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SiteSelector extends StatelessWidget {
  const _SiteSelector({required this.vm});
  final MultiSensorViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final site in vm.sites)
          ChoiceChip(
            label: Text(site.name),
            selected: site.id == vm.selectedSite?.id,
            onSelected: (_) => vm.selectSite(site.id),
          ),
      ],
    );
  }
}

class _ModalityFilter extends StatelessWidget {
  const _ModalityFilter({required this.vm});
  final MultiSensorViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('モダリティ: ',
            style: TextStyle(
                fontSize: 12, color: CommandCenterTheme.textMuted)),
        FilterChip(
          label: const Text('SAR'),
          selected: vm.enabledModalities.contains(SensorModality.sar),
          onSelected: (_) => vm.toggleModality(SensorModality.sar),
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('光学'),
          selected: vm.enabledModalities.contains(SensorModality.optical),
          onSelected: (_) => vm.toggleModality(SensorModality.optical),
        ),
        const SizedBox(width: 16),
        if (vm.selectedSite != null)
          Expanded(
            child: Text(vm.selectedSite!.context,
                style: const TextStyle(
                    fontSize: 11, color: CommandCenterTheme.textMuted)),
          ),
      ],
    );
  }
}

class _ScenesPanel extends StatelessWidget {
  const _ScenesPanel({required this.vm});
  final MultiSensorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scenes = vm.visibleScenes;
    final selected = vm.selectedScene;
    final selectedSensor =
        selected != null ? vm.sensorFor(selected.sensorId) : null;
    return Card(
      color: CommandCenterTheme.panel,
      child: scenes.isEmpty
          ? const Center(child: Text('表示するシーンがありません'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: selected != null
                      ? MultiSensorScenePreview(
                          scene: selected,
                          modality: selectedSensor?.modality ?? SensorModality.sar,
                        )
                      : const Center(child: Text('シーンを選択してください')),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: scenes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final s = scenes[i];
                      final sensor = vm.sensorFor(s.sensorId);
                      final isSelected = s.sceneId == selected?.sceneId;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: CommandCenterTheme.accent
                            .withValues(alpha: 0.12),
                        leading: MultiSensorScenePreview(
                          scene: s,
                          modality: sensor?.modality ?? SensorModality.sar,
                          compact: true,
                        ),
                        title: Text(sensor?.name ?? s.sensorId,
                            style: const TextStyle(fontSize: 12)),
                        subtitle: Text(
                          '${s.acquisitionDate} · '
                          '${s.orbitDirection ?? "—"} · GSD ${sensor?.gsdMeters ?? 0}m',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: SelectableText(s.sceneId.substring(0, 8),
                            style: const TextStyle(fontSize: 10)),
                        onTap: () => vm.selectScene(s.sceneId),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _SensorsPanel extends StatelessWidget {
  const _SensorsPanel({required this.vm});
  final MultiSensorViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: CommandCenterTheme.panel,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('Tellus 上のセンサー特性',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          for (final sensor in vm.sensors)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _SensorCard(sensor: sensor),
            ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({required this.sensor});
  final SatelliteSensor sensor;

  @override
  Widget build(BuildContext context) {
    final isSar = sensor.modality == SensorModality.sar;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: CommandCenterTheme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(isSar ? Icons.radar : Icons.photo_camera,
                size: 16,
                color: isSar
                    ? CommandCenterTheme.accent
                    : CommandCenterTheme.accentWarm),
            const SizedBox(width: 6),
            Expanded(
              child: Text(sensor.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
            ),
            Text('${sensor.band} · ${sensor.gsdMeters}m',
                style: const TextStyle(
                    fontSize: 10, color: CommandCenterTheme.textMuted)),
          ]),
          const SizedBox(height: 4),
          for (final s in sensor.strengths)
            Text('+ $s',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF8FE3B0))),
          Text('− ${sensor.weakness}',
              style: const TextStyle(
                  fontSize: 11, color: CommandCenterTheme.accentWarm)),
        ],
      ),
    );
  }
}
