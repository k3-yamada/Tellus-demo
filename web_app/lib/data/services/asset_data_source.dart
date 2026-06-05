import 'dart:convert';
import 'package:flutter/services.dart';

class AssetDataSource {
  AssetDataSource({this.assetPath = defaultAssetPath});

  static const defaultAssetPath = 'assets/data/infrastructure_data.json';

  final String assetPath;

  Future<Map<String, dynamic>> loadInfrastructureJson() async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
