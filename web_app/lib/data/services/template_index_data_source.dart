import 'dart:convert';
import 'package:flutter/services.dart';

class TemplateIndexDataSource {
  TemplateIndexDataSource({this.assetPath = defaultAssetPath});

  static const defaultAssetPath = 'assets/data/templates/index.json';

  final String assetPath;

  Future<Map<String, dynamic>> loadIndexJson() async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
