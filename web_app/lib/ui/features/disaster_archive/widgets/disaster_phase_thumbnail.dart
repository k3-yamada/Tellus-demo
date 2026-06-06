import 'package:flutter/material.dart';

import '../../../core/assets/bundled_asset_path.dart';
import '../../../core/theme/command_center_theme.dart';

/// 災害フェーズ SAR サムネイルの共有画像ビルダー。
Widget buildDisasterPhaseThumbnail(
  String? url, {
  BoxFit fit = BoxFit.cover,
}) {
  if (url == null || url.isEmpty) {
    return _placeholder('サムネ未取得');
  }
  if (isBundledAssetUrl(url)) {
    return Image.asset(
      resolveBundledAssetPath(url),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _placeholder('読込失敗'),
    );
  }
  return Image.network(
    url,
    fit: fit,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (context, error, stackTrace) => _placeholder('読込失敗'),
    loadingBuilder: (ctx, child, progress) {
      if (progress == null) return child;
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    },
  );
}

Widget _placeholder(String text) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.satellite_alt,
            color: CommandCenterTheme.textMuted, size: 32),
        const SizedBox(height: 8),
        Text(text,
            style: const TextStyle(
                color: CommandCenterTheme.textMuted, fontSize: 11)),
      ],
    ),
  );
}
