import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/asset_template.dart';
import '../../../../domain/repositories/template_catalog_repository.dart';
import '../../../core/theme/command_center_theme.dart';
import '../../dashboard/view_models/dashboard_view_model.dart';
import '../view_models/template_switcher_view_model.dart';

/// 業界別テンプレ切替 UI。
/// ViewModel が repository から index を読み、選択時に DashboardViewModel に通知。
class TemplateSwitcher extends StatelessWidget {
  const TemplateSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TemplateSwitcherViewModel>(
      create: (ctx) => TemplateSwitcherViewModel(
        repository: ctx.read<TemplateCatalogRepository>(),
      )..load(),
      child: const _SwitcherBody(),
    );
  }
}

class _SwitcherBody extends StatelessWidget {
  const _SwitcherBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TemplateSwitcherViewModel>();
    final dashboard = context.watch<DashboardViewModel>();
    if (vm.isLoading || vm.templates.isEmpty) {
      return const SizedBox(width: 180);
    }
    final current = dashboard.currentTemplate ?? vm.defaultTemplate;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: DropdownButton<AssetTemplate>(
        key: const ValueKey('template_switcher'),
        value: current,
        isDense: true,
        underline: const SizedBox.shrink(),
        items: [
          for (final t in vm.templates)
            DropdownMenuItem<AssetTemplate>(
              value: t,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      t.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: (template) {
          if (template == null) return;
          dashboard.switchTemplate(template);
        },
        style: const TextStyle(
            fontSize: 12, color: CommandCenterTheme.textPrimary),
      ),
    );
  }
}
