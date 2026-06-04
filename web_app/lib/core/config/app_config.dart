import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({
    this.bffUrl = '',
    this.demoMode = true,
  });

  final String bffUrl;
  final bool demoMode;

  static AppConfig fromEnvironment() {
    const bffUrl = String.fromEnvironment('BFF_URL', defaultValue: '');
    const demoModeStr = String.fromEnvironment('DEMO_MODE', defaultValue: 'true');
    return AppConfig(
      bffUrl: bffUrl,
      demoMode: demoModeStr.toLowerCase() != 'false',
    );
  }

  static final AppConfig instance = fromEnvironment();

  bool get useBff => bffUrl.isNotEmpty && !kDebugMode;
}
