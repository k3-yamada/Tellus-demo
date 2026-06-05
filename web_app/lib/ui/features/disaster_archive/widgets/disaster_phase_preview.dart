import 'package:flutter/material.dart';

import '../../../../domain/models/disaster_event.dart';
import '../../../core/theme/command_center_theme.dart';
import 'disaster_phase_thumbnail.dart';

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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: buildDisasterPhaseThumbnail(url),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
