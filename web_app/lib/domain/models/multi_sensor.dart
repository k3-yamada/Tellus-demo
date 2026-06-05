/// Tellus 上の複数センサー (SAR / 光学) を横並びで比較するためのモデル。
enum SensorModality { sar, optical }

class SatelliteSensor {
  const SatelliteSensor({
    required this.id,
    required this.name,
    required this.datasetId,
    required this.modality,
    required this.band,
    required this.gsdMeters,
    required this.strengths,
    required this.weakness,
  });

  final String id;
  final String name;
  final String datasetId;
  final SensorModality modality;
  final String band;
  final double gsdMeters;
  final List<String> strengths;
  final String weakness;
}

class ObservationSite {
  const ObservationSite({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.context,
    required this.scenes,
  });

  final String id;
  final String name;
  final double lat;
  final double lon;
  final String context;
  final List<SensorScene> scenes;
}

class SensorScene {
  const SensorScene({
    required this.sensorId,
    required this.sceneId,
    required this.acquisitionDate,
    required this.acquisitionDatetime,
    this.orbitDirection,
    this.thumbnailUrl,
  });

  final String sensorId;
  final String sceneId;
  final String acquisitionDate;
  final String acquisitionDatetime;
  final String? orbitDirection;
  final String? thumbnailUrl;
}

class MultiSensorCatalog {
  const MultiSensorCatalog({required this.sensors, required this.sites});

  final List<SatelliteSensor> sensors;
  final List<ObservationSite> sites;
}
