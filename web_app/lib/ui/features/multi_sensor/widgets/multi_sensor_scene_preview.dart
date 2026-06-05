import 'package:flutter/material.dart';

import '../../../../domain/models/multi_sensor.dart';
import '../../../core/theme/command_center_theme.dart';

/// マルチセンサーシーンのサムネイル表示。
/// `assets/` は [Image.asset]、HTTP(S) は [Image.network]、未設定時はプレースホルダ。
class MultiSensorScenePreview extends StatelessWidget {
  const MultiSensorScenePreview({
    super.key,
    required this.scene,
    this.modality = SensorModality.sar,
    this.compact = false,
  });

  final SensorScene scene;
  final SensorModality modality;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final url = scene.thumbnailUrl;
    final title = modality == SensorModality.sar ? 'SAR サムネイル' : '光学サムネイル';

    if (compact) {
      return _buildImageOrPlaceholder(url, size: 48);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: CommandCenterTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CommandCenterTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Icon(
                  modality == SensorModality.sar ? Icons.radar : Icons.photo_camera,
                  size: 16,
                  color: modality == SensorModality.sar
                      ? CommandCenterTheme.accent
                      : CommandCenterTheme.accentWarm,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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

  Widget _buildImageOrPlaceholder(String? url, {required double size}) {
    if (url == null || url.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: _placeholder('—', iconSize: 20),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildImage(url, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildImage(String url, {BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
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

  Widget _placeholder(String text, {double iconSize = 32}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.satellite_alt,
              color: CommandCenterTheme.textMuted, size: iconSize),
          if (text != '—') ...[
            const SizedBox(height: 8),
            Text(text,
                style: const TextStyle(
                    color: CommandCenterTheme.textMuted, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
