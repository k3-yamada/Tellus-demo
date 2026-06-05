import '../../domain/models/disaster_event.dart';
import '../../domain/repositories/disaster_archive_repository.dart';
import '../services/disaster_archive_data_source.dart';

class DisasterArchiveRepositoryImpl implements DisasterArchiveRepository {
  DisasterArchiveRepositoryImpl({DisasterArchiveDataSource? dataSource})
      : _dataSource = dataSource ?? DisasterArchiveDataSource();

  final DisasterArchiveDataSource _dataSource;

  @override
  Future<List<DisasterEvent>> loadEvents() async {
    final json = await _dataSource.loadJson();
    final events = json['events'] as List<dynamic>? ?? [];
    return events
        .map((e) => _parseEvent(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  DisasterEvent _parseEvent(Map<String, dynamic> json) {
    final phasesRaw = json['phases'] as List<dynamic>? ?? [];
    return DisasterEvent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0,
      eventDatetime: json['eventDatetime'] as String? ?? '',
      demoFocus: json['demoFocus'] as String? ?? '',
      phases: phasesRaw
          .map((p) => _parsePhase(p as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  DisasterPhase _parsePhase(Map<String, dynamic> json) {
    return DisasterPhase(
      label: _labelFromString(json['phase'] as String? ?? ''),
      datasetId: json['datasetId'] as String? ?? '',
      sceneId: json['sceneId'] as String? ?? '',
      acquisitionDate: json['acquisitionDate'] as String? ?? '',
      acquisitionDatetime: json['acquisitionDatetime'] as String? ?? '',
      orbitDirection: json['orbitDirection'] as String? ?? '',
      polarization: json['polarization'] as String? ?? '',
      note: json['note'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  DisasterPhaseLabel _labelFromString(String raw) {
    switch (raw) {
      case 'before':
        return DisasterPhaseLabel.before;
      case 'during':
        return DisasterPhaseLabel.during;
      case 'after':
        return DisasterPhaseLabel.after;
      default:
        return DisasterPhaseLabel.before;
    }
  }
}
