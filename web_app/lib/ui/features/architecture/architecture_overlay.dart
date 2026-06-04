import 'package:flutter/material.dart';

import '../../core/theme/command_center_theme.dart';
import 'architecture_page.dart';
import 'widgets/architecture_explainer_panel.dart';

Future<void> showArchitectureExplainerOverlay(
  BuildContext context, {
  bool tutorial = false,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'architecture-explainer',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: _ArchitectureOverlayPanel(tutorial: tutorial),
        ),
      );
    },
  );
}

class _ArchitectureOverlayPanel extends StatelessWidget {
  const _ArchitectureOverlayPanel({required this.tutorial});

  final bool tutorial;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final panelWidth = size.width * 0.92;
    final panelHeight = size.height * 0.92;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: SizedBox(
          width: panelWidth,
          height: panelHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: CommandCenterTheme.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CommandCenterTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _OverlayHeader(tutorial: tutorial),
                  Expanded(
                    child: ArchitectureExplainerPanel(tutorialMode: tutorial),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayHeader extends StatelessWidget {
  const _OverlayHeader({required this.tutorial});

  final bool tutorial;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CommandCenterTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_tree, color: CommandCenterTheme.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tutorial ? 'システム解説（チュートリアル）' : 'システム構成の解説',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: CommandCenterTheme.textPrimary,
                  ),
                ),
                const Text(
                  'Tellus Infrastructure Monitor',
                  style: TextStyle(fontSize: 11, color: CommandCenterTheme.textMuted),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ArchitecturePage()),
              );
            },
            icon: const Icon(Icons.open_in_full, size: 16),
            label: const Text('全画面で見る'),
            style: TextButton.styleFrom(
              foregroundColor: CommandCenterTheme.accent,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
          IconButton(
            tooltip: '閉じる',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: CommandCenterTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
