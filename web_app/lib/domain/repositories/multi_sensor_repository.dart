import '../models/multi_sensor.dart';

abstract class MultiSensorRepository {
  Future<MultiSensorCatalog> loadCatalog();
}
