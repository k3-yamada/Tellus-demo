import 'package:flutter/foundation.dart';

import '../../../../domain/models/multi_sensor.dart';
import '../../../../domain/repositories/multi_sensor_repository.dart';

class MultiSensorViewModel extends ChangeNotifier {
  MultiSensorViewModel({required MultiSensorRepository repository})
      : _repository = repository;

  final MultiSensorRepository _repository;

  MultiSensorCatalog? _catalog;
  String? _selectedSiteId;
  final Set<SensorModality> _enabledModalities = {
    SensorModality.sar,
    SensorModality.optical,
  };
  bool _loading = true;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  List<SatelliteSensor> get sensors => _catalog?.sensors ?? const [];
  List<ObservationSite> get sites => _catalog?.sites ?? const [];
  Set<SensorModality> get enabledModalities => _enabledModalities;

  ObservationSite? get selectedSite {
    final all = sites;
    if (all.isEmpty) return null;
    for (final s in all) {
      if (s.id == _selectedSiteId) return s;
    }
    return all.first;
  }

  SatelliteSensor? sensorFor(String id) {
    for (final s in sensors) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<SensorScene> get visibleScenes {
    final site = selectedSite;
    if (site == null) return const [];
    return site.scenes.where((scene) {
      final sensor = sensorFor(scene.sensorId);
      if (sensor == null) return false;
      return _enabledModalities.contains(sensor.modality);
    }).toList()
      ..sort((a, b) => a.acquisitionDate.compareTo(b.acquisitionDate));
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _catalog = await _repository.loadCatalog();
      _selectedSiteId ??=
          _catalog!.sites.isNotEmpty ? _catalog!.sites.first.id : null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectSite(String siteId) {
    if (_selectedSiteId == siteId) return;
    _selectedSiteId = siteId;
    notifyListeners();
  }

  void toggleModality(SensorModality modality) {
    if (_enabledModalities.contains(modality)) {
      if (_enabledModalities.length == 1) return;
      _enabledModalities.remove(modality);
    } else {
      _enabledModalities.add(modality);
    }
    notifyListeners();
  }
}
