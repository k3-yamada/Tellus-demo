import '../models/infrastructure_snapshot.dart';

abstract class InfrastructureRepository {
  Future<InfrastructureSnapshot> load();
}
