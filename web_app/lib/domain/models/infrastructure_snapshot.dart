import 'region.dart';
import 'sar_dataset.dart';

class DisplacementDemo {
  const DisplacementDemo({
    required this.regionId,
    required this.unit,
    required this.baselineDate,
    required this.values,
    this.disclaimer,
  });

  final String regionId;
  final String unit;
  final String baselineDate;
  final List<DisplacementPoint> values;
  final String? disclaimer;

  factory DisplacementDemo.fromJson(Map<String, dynamic> json) {
    final raw = json['values'] as List<dynamic>? ?? [];
    return DisplacementDemo(
      regionId: json['regionId'] as String? ?? '',
      unit: json['unit'] as String? ?? 'mm',
      baselineDate: json['baselineDate'] as String? ?? '',
      disclaimer: json['disclaimer'] as String?,
      values: raw
          .map((e) => DisplacementPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DisplacementPoint {
  const DisplacementPoint({required this.date, required this.displacementMm});

  final String date;
  final double displacementMm;

  factory DisplacementPoint.fromJson(Map<String, dynamic> json) {
    return DisplacementPoint(
      date: json['date'] as String? ?? '',
      displacementMm: (json['displacementMm'] as num?)?.toDouble() ?? 0,
    );
  }
}

class QualityReport {
  const QualityReport({
    required this.overallScore,
    required this.totalObservations,
    required this.regionsWithGeometry,
    required this.regionsWithThumbnails,
    required this.notes,
  });

  final double overallScore;
  final int totalObservations;
  final int regionsWithGeometry;
  final int regionsWithThumbnails;
  final List<String> notes;

  factory QualityReport.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const QualityReport(
        overallScore: 0,
        totalObservations: 0,
        regionsWithGeometry: 0,
        regionsWithThumbnails: 0,
        notes: [],
      );
    }
    return QualityReport(
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0,
      totalObservations: (json['totalObservations'] as num?)?.toInt() ?? 0,
      regionsWithGeometry: (json['regionsWithGeometry'] as num?)?.toInt() ?? 0,
      regionsWithThumbnails: (json['regionsWithThumbnails'] as num?)?.toInt() ?? 0,
      notes: (json['notes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class SummaryInsights {
  const SummaryInsights({
    required this.canUnderstand,
    required this.cannotUnderstand,
  });

  final List<String> canUnderstand;
  final List<String> cannotUnderstand;
}

class InfrastructureSnapshot {
  const InfrastructureSnapshot({
    required this.generatedAt,
    required this.regions,
    required this.timelineSteps,
    required this.sliderDates,
    this.schemaVersion = 1,
    this.qualityReport,
    this.coverageByYear = const {},
    this.displacementDemo,
    this.datasetsCatalog = const [],
    this.tellusPortalUrl,
  });

  final int schemaVersion;
  final String generatedAt;
  final List<Region> regions;
  final List<TimelineStep> timelineSteps;
  final List<String> sliderDates;
  final QualityReport? qualityReport;
  final Map<String, Map<String, int>> coverageByYear;
  final DisplacementDemo? displacementDemo;
  final List<SarDatasetEntry> datasetsCatalog;
  final String? tellusPortalUrl;
}

class TimelineStep {
  const TimelineStep({
    required this.regionId,
    required this.dataId,
    required this.acquisitionDate,
    required this.monitoringIndex,
    required this.sortKey,
  });

  final String regionId;
  final String dataId;
  final String acquisitionDate;
  final double monitoringIndex;
  final String sortKey;
}
