import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/infrastructure_snapshot.dart';
import '../../../../domain/models/observation.dart';
import '../../../../domain/models/region.dart';
import '../../../../domain/repositories/infrastructure_repository.dart';

enum ViewMode { explorer, analyst }

enum DemoScenario { embankment, slope, rainySeason, longTerm }

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({required InfrastructureRepository repository})
      : _repository = repository;

  final InfrastructureRepository _repository;
  static final _dateFormat = DateFormat('yyyy年M月d日', 'ja');
  static final _dateTimeFormat = DateFormat('yyyy年M月d日 HH:mm', 'ja');

  InfrastructureSnapshot? _snapshot;
  bool _loading = true;
  String? _error;
  String _selectedRegionId = 'joganji';
  double _sliderValue = 0;
  double _animatedProgress = 0;
  ViewMode _viewMode = ViewMode.explorer;
  DemoScenario _scenario = DemoScenario.embankment;
  String? _orbitFilter;
  String? _polarizationFilter;
  bool _isPlaying = false;

  bool get isLoading => _loading;
  String? get error => _error;
  InfrastructureSnapshot? get snapshot => _snapshot;
  String get selectedRegionId => _selectedRegionId;
  double get sliderValue => _sliderValue;
  double get animatedProgress => _animatedProgress;
  ViewMode get viewMode => _viewMode;
  DemoScenario get scenario => _scenario;
  String? get orbitFilter => _orbitFilter;
  String? get polarizationFilter => _polarizationFilter;
  bool get isPlaying => _isPlaying;
  QualityReport? get qualityReport => _snapshot?.qualityReport;
  DisplacementDemo? get displacementDemo => _snapshot?.displacementDemo;

  List<Region> get regions => _snapshot?.regions ?? [];
  Region? get selectedRegion {
    for (final r in regions) {
      if (r.id == _selectedRegionId) return r;
    }
    return regions.isNotEmpty ? regions.first : null;
  }

  int get maxSliderIndex {
    final dates = _snapshot?.sliderDates ?? [];
    return dates.isEmpty ? 0 : dates.length - 1;
  }

  String get currentDateLabel {
    final dates = _snapshot?.sliderDates ?? [];
    if (dates.isEmpty) return '—';
    final idx = _sliderValue.round().clamp(0, dates.length - 1);
    return formatDateLabel(dates[idx]);
  }

  String formatDateLabel(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate);
      return isoDate.contains('T') ? _dateTimeFormat.format(dt) : _dateFormat.format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  Map<String, int> coverageForRegion(String regionId) {
    return _snapshot?.coverageByYear[regionId] ?? {};
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _snapshot = await _repository.load();
      if (_snapshot!.regions.isNotEmpty) {
        _selectedRegionId = _snapshot!.regions.first.id;
      }
      _sliderValue = maxSliderIndex.toDouble();
      _animatedProgress = _sliderValue;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectRegion(String id) {
    if (_selectedRegionId == id) return;
    _selectedRegionId = id;
    notifyListeners();
  }

  void setViewMode(ViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    notifyListeners();
  }

  void setScenario(DemoScenario s) {
    if (_scenario == s) return;
    _scenario = s;
    switch (s) {
      case DemoScenario.embankment:
        _selectedRegionId = 'joganji';
      case DemoScenario.slope:
        _selectedRegionId = 'tateyama';
      case DemoScenario.rainySeason:
      case DemoScenario.longTerm:
        break;
    }
    notifyListeners();
  }

  void setOrbitFilter(String? value) {
    _orbitFilter = value;
    notifyListeners();
  }

  void setPolarizationFilter(String? value) {
    _polarizationFilter = value;
    notifyListeners();
  }

  void setPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  void setSliderValue(double value) {
    _sliderValue = value;
    notifyListeners();
  }

  void setAnimatedProgress(double value) {
    _animatedProgress = value;
    notifyListeners();
  }

  List<Observation> filteredObservations(Region region) {
    return region.observations.where((obs) {
      if (_orbitFilter != null && obs.orbitDirection != _orbitFilter) return false;
      if (_polarizationFilter != null && !obs.polarization.contains(_polarizationFilter!)) {
        return false;
      }
      if (_scenario == DemoScenario.rainySeason) {
        final month = _monthFromObs(obs);
        if (month != null && month < 5 || (month != null && month > 9)) return false;
      }
      return true;
    }).toList();
  }

  int? _monthFromObs(Observation obs) {
    final src = obs.startDatetime.isNotEmpty ? obs.startDatetime : obs.acquisitionDate;
    if (src.length < 7) return null;
    return int.tryParse(src.substring(5, 7));
  }

  Observation? observationAtProgress(Region region, double progress) {
    final dates = _snapshot?.sliderDates ?? [];
    if (dates.isEmpty || region.observations.isEmpty) return null;

    final low = progress.floor().clamp(0, dates.length - 1);
    final high = progress.ceil().clamp(0, dates.length - 1);
    final tLow = dates[low];
    final tHigh = dates[high];
    final frac = progress - low;

    final obsLow = _latestAtOrBefore(region, tLow);
    final obsHigh = _latestAtOrBefore(region, tHigh);
    if (obsLow == null && obsHigh == null) return null;
    if (obsLow == null) return obsHigh;
    if (obsHigh == null) return obsLow;
    if (low == high) return obsLow;

    return obsLow.copyWith(
      offNadir: _lerp(obsLow.offNadir, obsHigh.offNadir, frac),
      monitoringIndex: _lerp(obsLow.monitoringIndex, obsHigh.monitoringIndex, frac),
      geometry: frac < 0.5 ? obsLow.geometry : obsHigh.geometry,
      thumbnailUrl: frac < 0.5 ? obsLow.thumbnailUrl : obsHigh.thumbnailUrl,
      qualityScore: obsLow.qualityScore != null && obsHigh.qualityScore != null
          ? _lerp(obsLow.qualityScore!, obsHigh.qualityScore!, frac)
          : obsLow.qualityScore ?? obsHigh.qualityScore,
    );
  }

  Observation? _latestAtOrBefore(Region region, String cutoff) {
    Observation? latest;
    for (final obs in filteredObservations(region)) {
      final key = obs.startDatetime.isNotEmpty ? obs.startDatetime : obs.acquisitionDate;
      if (key.compareTo(cutoff) <= 0) {
        if (latest == null ||
            key.compareTo(
                  latest.startDatetime.isNotEmpty ? latest.startDatetime : latest.acquisitionDate,
                ) >
                0) {
          latest = obs;
        }
      }
    }
    return latest;
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  List<ChartPoint> chartPointsFor(Region region) {
    return filteredObservations(region)
        .map(
          (o) => ChartPoint(
            label: o.acquisitionDate,
            sortKey: o.startDatetime.isNotEmpty ? o.startDatetime : o.acquisitionDate,
            value: o.monitoringIndex,
          ),
        )
        .toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }

  int chartHighlightIndex(Region region) {
    final points = chartPointsFor(region);
    if (points.isEmpty) return -1;
    final current = observationAtProgress(region, _animatedProgress);
    if (current == null) return points.length - 1;
    for (var i = points.length - 1; i >= 0; i--) {
      if (points[i].sortKey.compareTo(
            current.startDatetime.isNotEmpty ? current.startDatetime : current.acquisitionDate,
          ) <=
          0) {
        return i;
      }
    }
    return 0;
  }

  ColorComponents markerColorFor(Region region) {
    final obs = observationAtProgress(region, _animatedProgress);
    final index = obs?.monitoringIndex ?? 0;
    return ColorComponents.fromMonitoringIndex(index);
  }

  double? displacementAtDate(String date) {
    final demo = displacementDemo;
    if (demo == null) return null;
    DisplacementPoint? closest;
    for (final pt in demo.values) {
      if (pt.date.compareTo(date) <= 0) {
        if (closest == null || pt.date.compareTo(closest.date) > 0) {
          closest = pt;
        }
      }
    }
    return closest?.displacementMm;
  }
}

class ChartPoint {
  const ChartPoint({required this.label, required this.sortKey, required this.value});

  final String label;
  final String sortKey;
  final double value;
}

class ColorComponents {
  const ColorComponents(this.hue, this.saturation, this.lightness);

  final double hue;
  final double saturation;
  final double lightness;

  factory ColorComponents.fromMonitoringIndex(double index) {
    final hue = 190 - (index.clamp(0.0, 1.0) * 140);
    return ColorComponents(hue, 0.75, 0.55);
  }
}
