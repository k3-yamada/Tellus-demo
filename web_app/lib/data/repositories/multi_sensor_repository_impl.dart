import '../../domain/models/multi_sensor.dart';
import '../../domain/repositories/multi_sensor_repository.dart';
import '../services/multi_sensor_data_source.dart';

class MultiSensorRepositoryImpl implements MultiSensorRepository {
  MultiSensorRepositoryImpl({MultiSensorDataSource? dataSource})
      : _dataSource = dataSource ?? MultiSensorDataSource();

  final MultiSensorDataSource _dataSource;

  @override
  Future<MultiSensorCatalog> loadCatalog() async {
    final json = await _dataSource.loadJson();
    final sensorsRaw = json['sensors'] as List<dynamic>? ?? [];
    final sitesRaw = json['sites'] as List<dynamic>? ?? [];
    final disclaimer = json['disclaimer'] as String?;
    return MultiSensorCatalog(
      sensors: sensorsRaw
          .map((e) => _parseSensor(e as Map<String, dynamic>))
          .toList(growable: false),
      sites: sitesRaw
          .map((e) => _parseSite(e as Map<String, dynamic>))
          .toList(growable: false),
      disclaimer: disclaimer,
    );
  }

  SatelliteSensor _parseSensor(Map<String, dynamic> json) {
    final modalityRaw = (json['modality'] as String? ?? '').toLowerCase();
    return SatelliteSensor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      datasetId: json['datasetId'] as String? ?? '',
      modality: modalityRaw == 'optical' ? SensorModality.optical : SensorModality.sar,
      band: json['band'] as String? ?? '',
      gsdMeters: (json['gsd_m'] as num?)?.toDouble() ?? 0,
      strengths: (json['strengths'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(growable: false),
      weakness: json['weakness'] as String? ?? '',
    );
  }

  ObservationSite _parseSite(Map<String, dynamic> json) {
    final scenesRaw = json['scenes'] as List<dynamic>? ?? [];
    return ObservationSite(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0,
      context: json['context'] as String? ?? '',
      scenes: scenesRaw
          .map((e) => _parseScene(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  SensorScene _parseScene(Map<String, dynamic> json) {
    return SensorScene(
      sensorId: json['sensorId'] as String? ?? '',
      sceneId: json['sceneId'] as String? ?? '',
      acquisitionDate: json['acquisitionDate'] as String? ?? '',
      acquisitionDatetime: json['acquisitionDatetime'] as String? ?? '',
      orbitDirection: json['orbitDirection'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}
