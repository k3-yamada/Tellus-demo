import 'package:flutter/material.dart';

import '../../../../domain/models/observation.dart';
import '../../../core/assets/bundled_asset_path.dart';
import '../../../core/theme/command_center_theme.dart';
import '../../../core/widgets/provenance_widgets.dart';

class ThumbnailPreview extends StatelessWidget {
  const ThumbnailPreview({
    super.key,
    this.observation,
    this.imageUrl,
    this.title = 'SAR サムネイル',
    this.fallbackAsset = 'assets/images/demo/sar_fallback.png',
  });

  final Observation? observation;
  final String? imageUrl;
  final String title;
  final String? fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl ?? observation?.thumbnailUrl;
    final hasUrl = url != null && url.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image, size: 16, color: CommandCenterTheme.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                _thumbnailSourceBadge(url),
              ],
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 8 / 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: CommandCenterTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CommandCenterTheme.border),
                ),
                child: hasUrl
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: _buildImage(url),
                      )
                    : _fallbackOrPlaceholder('サムネ未取得'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (isBundledAssetUrl(url)) {
      return SizedBox.expand(
        child: Image.asset(
          resolveBundledAssetPath(url),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _fallbackOrPlaceholder('読込失敗'),
        ),
      );
    }
    return SizedBox.expand(
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackOrPlaceholder('読込失敗'),
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
      ),
    );
  }

  Widget _fallbackOrPlaceholder(String text) {
    final asset = fallbackAsset;
    if (asset != null && asset.isNotEmpty) {
      return SizedBox.expand(
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholder(text),
        ),
      );
    }
    return _placeholder(text);
  }

  Widget _placeholder(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.satellite_alt, color: CommandCenterTheme.textMuted, size: 32),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: CommandCenterTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _thumbnailSourceBadge(String? url) {
    if (isBundledAssetUrl(url)) {
      return const ProvenanceBadge(
        provenance: DataProvenance.bundled,
        compact: true,
        tooltip: 'オフライン同梱の代表 SAR 画像です',
      );
    }
    if (url != null && url.isNotEmpty) {
      return const ProvenanceBadge(
        provenance: DataProvenance.real,
        compact: true,
        tooltip: 'Tellus から取得したサムネイルです',
      );
    }
    final hasFallback = fallbackAsset != null && fallbackAsset!.isNotEmpty;
    return _inlineSourceBadge(
      hasFallback ? '代表表示' : '未取得',
      hasFallback ? CommandCenterTheme.textMuted : CommandCenterTheme.accentWarm,
      tooltip: hasFallback
          ? '観測日の画像がないため、同梱の代表画像を表示しています'
          : 'この日付のサムネイルはまだありません',
    );
  }

  Widget _inlineSourceBadge(String label, Color color, {String? tooltip}) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
    if (tooltip == null) return badge;
    return Tooltip(message: tooltip, child: badge);
  }
}
