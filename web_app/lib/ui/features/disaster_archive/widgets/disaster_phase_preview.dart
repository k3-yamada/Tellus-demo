import 'package:flutter/material.dart';

import '../../../../domain/models/disaster_event.dart';
import '../../../core/theme/command_center_theme.dart';

/// 災害フェーズの SAR サムネイル表示。
/// `assets/` パスは [Image.asset]、HTTP(S) は [Image.network]、未設定時はプレースホルダ。
class DisasterPhasePreview extends StatelessWidget {
  const DisasterPhasePreview({super.key, required this.phase});

  final DisasterPhase phase;

  @override
  Widget build(BuildContext context) {
    final url = phase.thumbnailUrl;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: CommandCenterTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CommandCenterTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Icon(Icons.image, size: 16, color: CommandCenterTheme.accent),
                SizedBox(width: 6),
                Text(
                  'SAR サムネイル',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: url != null && url.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: _buildImage(url),
                    )
                  : _placeholder('サムネ未取得'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _placeholder('読込失敗'),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _placeholder('読込失敗'),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );
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
}
