import '../models/disaster_event.dart';

abstract class DisasterArchiveRepository {
  Future<List<DisasterEvent>> loadEvents();
}
