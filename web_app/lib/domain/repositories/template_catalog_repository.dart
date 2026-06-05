import '../models/asset_template.dart';

abstract class TemplateCatalogRepository {
  Future<List<AssetTemplate>> loadTemplates();
}
