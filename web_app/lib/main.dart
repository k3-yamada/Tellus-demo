import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'data/repositories/disaster_archive_repository_impl.dart';
import 'data/repositories/infrastructure_repository_impl.dart';
import 'data/repositories/multi_sensor_repository_impl.dart';
import 'data/repositories/tellusar_repository_impl.dart';
import 'data/repositories/template_catalog_repository_impl.dart';
import 'domain/repositories/disaster_archive_repository.dart';
import 'domain/repositories/infrastructure_repository.dart';
import 'domain/repositories/multi_sensor_repository.dart';
import 'domain/repositories/tellusar_repository.dart';
import 'domain/repositories/template_catalog_repository.dart';
import 'ui/core/theme/command_center_theme.dart';
import 'ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'ui/features/dashboard/views/dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
  runApp(const TellusDemoApp());
}

/// Composition root.
/// データ層の具象実装をここで生成し、Provider 経由で UI 層に注入する。
/// UI 層は domain interface だけを参照し、具象に依存しない (Clean Arch)。
class TellusDemoApp extends StatelessWidget {
  const TellusDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _providers(),
      child: MaterialApp(
        title: 'Tellus Infrastructure Monitor',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ja'),
        supportedLocales: const [Locale('ja'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: CommandCenterTheme.dark(),
        home: const DashboardPage(),
      ),
    );
  }

  List<SingleChildWidget> _providers() => [
        Provider<InfrastructureRepository>(
          create: (_) => InfrastructureRepositoryImpl(),
        ),
        Provider<TemplateCatalogRepository>(
          create: (_) => TemplateCatalogRepositoryImpl(),
        ),
        Provider<DisasterArchiveRepository>(
          create: (_) => DisasterArchiveRepositoryImpl(),
        ),
        Provider<MultiSensorRepository>(
          create: (_) => MultiSensorRepositoryImpl(),
        ),
        Provider<TellusarRepository>(
          create: (_) => TellusarRepositoryImpl(),
        ),
        ChangeNotifierProvider<DashboardViewModel>(
          create: (ctx) => DashboardViewModel(
            repository: ctx.read<InfrastructureRepository>(),
          ),
        ),
      ];
}
