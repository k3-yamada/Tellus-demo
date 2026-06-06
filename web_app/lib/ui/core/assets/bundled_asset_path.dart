/// バンドル済み画像パスを [Image.asset] 用の asset key に正規化する。
///
/// JSON の `thumbnailUrl` は `assets/images/...`（推奨）または `images/...` を許容する。
/// `assets/` を二重に付与しない。
String resolveBundledAssetPath(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.startsWith('assets/')) return trimmed;
  if (trimmed.startsWith('images/')) return 'assets/$trimmed';
  return trimmed;
}

/// ローカルバンドル資産か（[Image.asset] 対象）。HTTP(S) URL は false。
bool isBundledAssetUrl(String? url) {
  if (url == null) return false;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return false;
  }
  return trimmed.startsWith('assets/') || trimmed.startsWith('images/');
}
