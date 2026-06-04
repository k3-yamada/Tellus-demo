import 'package:flutter/material.dart';

import '../../../../domain/models/observation.dart';
import '../../../core/theme/command_center_theme.dart';

class ThumbnailPreview extends StatelessWidget {
  const ThumbnailPreview({super.key, this.observation});

  final Observation? observation;

  @override
  Widget build(BuildContext context) {
    final url = observation?.thumbnailUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.image, size: 16, color: CommandCenterTheme.accent),
                SizedBox(width: 6),
                Text(
                  'SAR サムネイル',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: CommandCenterTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CommandCenterTheme.border),
                ),
                child: url != null && url.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _placeholder('読込失敗'),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                        ),
                      )
                    : _placeholder('サムネ未取得'),
              ),
            ),
          ],
        ),
      ),
    );
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
