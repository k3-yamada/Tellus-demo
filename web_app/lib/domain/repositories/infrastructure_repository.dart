import '../models/asset_template.dart';
import '../models/infrastructure_snapshot.dart';

abstract class InfrastructureRepository {
  /// `template` が null の場合はデフォルト (Toyama 本データ) を読み込む。
  /// data 層は template.sourceRef を opaque に解釈する。
  Future<InfrastructureSnapshot> load({AssetTemplate? template});
}
