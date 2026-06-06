import 'package:flutter_test/flutter_test.dart';
import 'package:tellus_demo/domain/models/asset_template.dart';
import 'package:tellus_demo/domain/repositories/template_catalog_repository.dart';
import 'package:tellus_demo/ui/features/template_switcher/view_models/template_switcher_view_model.dart';

const _toyama = AssetTemplate(
  id: 'toyama_default',
  displayName: '富山',
  icon: '🛰',
  pitch: 'p',
  regionName: '富山県',
  sourceRef: 'assets/data/infrastructure_data.json',
  isDefault: true,
);

const _dam = AssetTemplate(
  id: 'dam',
  displayName: 'ダム',
  icon: '🏗',
  pitch: 'p',
  regionName: '全国',
  sourceRef: 'assets/data/industry/dam.json',
);

class _FakeCatalogRepo implements TemplateCatalogRepository {
  @override
  Future<List<AssetTemplate>> loadTemplates() async => [_toyama, _dam];
}

void main() {
  test('resolveForSelection maps by id to catalog instance', () async {
    final vm = TemplateSwitcherViewModel(repository: _FakeCatalogRepo());
    await vm.load();

    final foreign = const AssetTemplate(
      id: 'dam',
      displayName: '別インスタンス',
      icon: 'x',
      pitch: 'x',
      regionName: 'x',
      sourceRef: 'assets/data/industry/dam.json',
    );

    final resolved = vm.resolveForSelection(foreign);
    expect(resolved, same(_dam));
    expect(resolved?.displayName, 'ダム');
  });

  test('resolveForSelection falls back to default for unknown id', () async {
    final vm = TemplateSwitcherViewModel(repository: _FakeCatalogRepo());
    await vm.load();

    const unknown = AssetTemplate(
      id: 'missing',
      displayName: '不明',
      icon: '?',
      pitch: '',
      regionName: '',
      sourceRef: '',
    );

    expect(vm.resolveForSelection(unknown), same(_toyama));
  });
}
