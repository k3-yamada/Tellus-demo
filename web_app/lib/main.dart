import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'data/repositories/infrastructure_repository_impl.dart';
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

class TellusDemoApp extends StatelessWidget {
  const TellusDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel(
        repository: InfrastructureRepositoryImpl(),
      ),
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
}
