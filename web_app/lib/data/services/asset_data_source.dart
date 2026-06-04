import 'dart:convert';
import 'package:flutter/services.dart';

class AssetDataSource {
  static const assetPath = 'assets/data/infrastructure_data.json';

  Future<Map<String, dynamic>> loadInfrastructureJson() async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
