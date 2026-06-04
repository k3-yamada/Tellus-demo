import '../../domain/models/infrastructure_snapshot.dart';
import '../../domain/models/observation.dart';
import '../../domain/models/region.dart';
import '../../domain/repositories/infrastructure_repository.dart';
import '../services/asset_data_source.dart';

class InfrastructureRepositoryImpl implements InfrastructureRepository {
  InfrastructureRepositoryImpl({AssetDataSource? dataSource})
      : _dataSource = dataSource ?? AssetDataSource();

  final AssetDataSource _dataSource;

  @override
  Future<InfrastructureSnapshot> load() async {
    final json = await _dataSource.loadInfrastructureJson();
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final regionsMap = json['regions'] as Map<String, dynamic>? ?? {};
    final timelineRaw = json['timeline'] as List<dynamic>? ?? [];
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 1;

    final qualityReport = QualityReport.fromJson(
      json['qualityReport'] as Map<String, dynamic>?,
    );

    final coverageRaw = json['coverageByYear'] as Map<String, dynamic>? ?? {};
    final coverageByYear = <String, Map<String, int>>{};
    for (final entry in coverageRaw.entries) {
      final yearMap = entry.value as Map<String, dynamic>? ?? {};
      coverageByYear[entry.key] = yearMap.map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      );
    }

    DisplacementDemo? displacementDemo;
    final dispRaw = meta['displacementDemo'] as Map<String, dynamic>?;
    if (dispRaw != null) {
      displacementDemo = DisplacementDemo.fromJson(dispRaw);
    }

    final regions = <Region>[];
    const regionOrder = ['joganji', 'tateyama'];

    for (final key in regionOrder) {
      final entry = regionsMap[key];
      if (entry == null) continue;
      regions.add(_parseRegion(entry as Map<String, dynamic>));
    }

    for (final entry in regionsMap.values) {
      final map = entry as Map<String, dynamic>;
      final id = map['id'] as String? ?? '';
      if (regionOrder.contains(id)) continue;
      regions.add(_parseRegion(map));
    }

    final timelineSteps = timelineRaw.map((e) {
      final m = e as Map<String, dynamic>;
      final date = m['acquisitionDate'] as String? ?? '';
      return TimelineStep(
        regionId: m['regionId'] as String? ?? '',
        dataId: m['dataId'] as String? ?? '',
        acquisitionDate: date,
        monitoringIndex: (m['monitoringIndex'] as num?)?.toDouble() ?? 0,
        sortKey: date,
      );
    }).toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

    final sliderDates = <String>{};
    for (final region in regions) {
      for (final obs in region.observations) {
        sliderDates.add(
          obs.startDatetime.isNotEmpty ? obs.startDatetime : obs.acquisitionDate,
        );
      }
    }
    final sortedDates = sliderDates.toList()..sort();

    return InfrastructureSnapshot(
      schemaVersion: schemaVersion,
      generatedAt: meta['generatedAt'] as String? ?? '',
      regions: regions,
      timelineSteps: timelineSteps,
      sliderDates: sortedDates,
      qualityReport: qualityReport,
      coverageByYear: coverageByYear,
      displacementDemo: displacementDemo,
    );
  }

  Region _parseRegion(Map<String, dynamic> map) {
    final observationsRaw = map['observations'] as List<dynamic>? ?? [];
    final observations = observationsRaw.map((item) {
      final o = item as Map<String, dynamic>;
      ObservationGeometry? geometry;
      final geomRaw = o['geometry'] as Map<String, dynamic>?;
      if (geomRaw != null) {
        geometry = ObservationGeometry(
          type: geomRaw['type'] as String? ?? '',
          coordinates: geomRaw['coordinates'],
        );
      }
      return Observation(
        dataId: o['dataId'] as String? ?? '',
        datasetId: o['datasetId'] as String? ?? '',
        acquisitionDate: o['acquisitionDate'] as String? ?? '',
        startDatetime:
            o['start_datetime'] as String? ?? o['acquisitionDate'] as String? ?? '',
        orbitDirection: o['orbitDirection'] as String? ?? '',
        polarization: o['polarization'] as String? ?? '',
        relativeOrbit: (o['relativeOrbit'] as num?)?.toInt(),
        offNadir: (o['offNadir'] as num?)?.toDouble() ?? 0,
        monitoringIndex: (o['monitoringIndex'] as num?)?.toDouble() ?? 0,
        geometry: geometry,
        thumbnailUrl: o['thumbnailUrl'] as String?,
        qualityScore: (o['qualityScore'] as num?)?.toDouble(),
      );
    }).toList();

    return Region(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['infrastructureType'] as String? ?? map['type'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lon'] as num?)?.toDouble() ?? (map['lng'] as num?)?.toDouble() ?? 0,
      observations: observations,
      description: map['description'] as String?,
      observationCount: (map['observationCount'] as num?)?.toInt(),
    );
  }
}
