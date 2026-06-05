/// 業界別テンプレート (ダム / 橋梁 / 空港 / 新幹線 / 港湾) の識別子。
///
/// `sourceRef` は data 層が解決する opaque な参照。
/// domain 層からは「どこから読むか」を知らない。
class AssetTemplate {
  const AssetTemplate({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.pitch,
    required this.regionName,
    required this.sourceRef,
    this.isDefault = false,
  });

  final String id;
  final String displayName;
  final String icon;
  final String pitch;
  final String regionName;
  final String sourceRef;
  final bool isDefault;
}
