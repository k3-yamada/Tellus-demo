import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

class TellusBffClient {
  TellusBffClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? AppConfig.instance.bffUrl).replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  bool get isConfigured => _baseUrl.isNotEmpty;

  Future<Map<String, dynamic>> demoCartOrder(List<String> datasetIds) async {
    final uri = Uri.parse('$_baseUrl/api/cart-items');
    final resp = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Demo-Dry-Run': 'true',
      },
      body: jsonEncode({'dataset_ids': datasetIds}),
    );
    if (resp.statusCode >= 400) {
      throw Exception('BFF cart demo failed: ${resp.statusCode}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> demoDatasetOrder(Map<String, dynamic> order) async {
    final uri = Uri.parse('$_baseUrl/api/dataset-orders');
    final resp = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Demo-Dry-Run': 'true',
      },
      body: jsonEncode(order),
    );
    if (resp.statusCode >= 400) {
      throw Exception('BFF order demo failed: ${resp.statusCode}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<bool> healthCheck() async {
    final uri = Uri.parse('$_baseUrl/health');
    final resp = await _client.get(uri);
    return resp.statusCode == 200;
  }
}
