import 'dart:convert';
import 'package:flutter/services.dart';

class MultiSensorDataSource {
  MultiSensorDataSource({this.assetPath = defaultAssetPath});

  static const defaultAssetPath = 'assets/data/multi_sensor.json';

  final String assetPath;

  Future<Map<String, dynamic>> loadJson() async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
