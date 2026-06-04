import 'observation.dart';

class Region {
  const Region({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.observations,
    this.description,
    this.observationCount,
  });

  final String id;
  final String name;
  final String type;
  final double lat;
  final double lng;
  final List<Observation> observations;
  final String? description;
  final int? observationCount;
}
