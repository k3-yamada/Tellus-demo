class ObservationGeometry {
  const ObservationGeometry({required this.type, required this.coordinates});

  final String type;
  final dynamic coordinates;

  bool get isValid => type.isNotEmpty && coordinates != null;
}

class Observation {
  const Observation({
    required this.dataId,
    required this.datasetId,
    required this.acquisitionDate,
    required this.startDatetime,
    required this.orbitDirection,
    required this.polarization,
    this.relativeOrbit,
    required this.offNadir,
    required this.monitoringIndex,
    this.geometry,
    this.thumbnailUrl,
    this.qualityScore,
  });

  final String dataId;
  final String datasetId;
  final String acquisitionDate;
  final String startDatetime;
  final String orbitDirection;
  final String polarization;
  final int? relativeOrbit;
  final double offNadir;
  final double monitoringIndex;
  final ObservationGeometry? geometry;
  final String? thumbnailUrl;
  final double? qualityScore;

  Observation copyWith({
    double? offNadir,
    double? monitoringIndex,
    ObservationGeometry? geometry,
    String? thumbnailUrl,
    double? qualityScore,
  }) {
    return Observation(
      dataId: dataId,
      datasetId: datasetId,
      acquisitionDate: acquisitionDate,
      startDatetime: startDatetime,
      orbitDirection: orbitDirection,
      polarization: polarization,
      relativeOrbit: relativeOrbit,
      offNadir: offNadir ?? this.offNadir,
      monitoringIndex: monitoringIndex ?? this.monitoringIndex,
      geometry: geometry ?? this.geometry,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      qualityScore: qualityScore ?? this.qualityScore,
    );
  }
}
