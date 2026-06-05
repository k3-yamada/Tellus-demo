import '../../domain/models/asset_template.dart';
import '../../domain/repositories/template_catalog_repository.dart';
import '../services/asset_data_source.dart';
import '../services/template_index_data_source.dart';

const _defaultToyamaTemplate = AssetTemplate(
  id: 'toyama_default',
  displayName: '富山インフラ監視 (本データ)',
  icon: '🛰',
  pitch: '常願寺川 + 立山室堂の SAR 観測 1000+ 件',
  regionName: '富山県',
  sourceRef: AssetDataSource.defaultAssetPath,
  isDefault: true,
);

class TemplateCatalogRepositoryImpl implements TemplateCatalogRepository {
  TemplateCatalogRepositoryImpl({TemplateIndexDataSource? dataSource})
      : _dataSource = dataSource ?? TemplateIndexDataSource();

  final TemplateIndexDataSource _dataSource;

  @override
  Future<List<AssetTemplate>> loadTemplates() async {
    final json = await _dataSource.loadIndexJson();
    final raw = json['templates'] as List<dynamic>? ?? [];
    final industry =
        raw.map((e) => _parse(e as Map<String, dynamic>)).toList(growable: false);
    return [_defaultToyamaTemplate, ...industry];
  }

  AssetTemplate _parse(Map<String, dynamic> json) {
    return AssetTemplate(
      id: json['id'] as String? ?? '',
      displayName: json['industry'] as String? ?? '',
      icon: json['icon'] as String? ?? '🛰',
      pitch: json['pitch'] as String? ?? '',
      regionName: json['region_name'] as String? ?? '',
      sourceRef: json['asset_path'] as String? ?? '',
    );
  }
}
