import 'package:flutter/material.dart';

import '../../../../domain/models/observation.dart';
import '../../../core/theme/command_center_theme.dart';

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
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
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
                child: url != null && url.isNotEmpty
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
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackOrPlaceholder('読込失敗'),
      );
    }
    return Image.network(
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
    );
  }

  Widget _fallbackOrPlaceholder(String text) {
    final asset = fallbackAsset;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(text),
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
}
