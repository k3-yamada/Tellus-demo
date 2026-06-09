import 'package:flutter/foundation.dart';

import '../../../../domain/models/disaster_event.dart';
import '../../../../domain/repositories/disaster_archive_repository.dart';
import '../widgets/disaster_phase_comparison.dart';

class DisasterArchiveViewModel extends ChangeNotifier {
  DisasterArchiveViewModel({required DisasterArchiveRepository repository})
      : _repository = repository;

  final DisasterArchiveRepository _repository;

  List<DisasterEvent> _events = const [];
  String? _selectedEventId;
  DisasterPhaseLabel _selectedPhase = DisasterPhaseLabel.during;
  DisasterComparisonMode _comparisonMode = DisasterComparisonMode.grid;
  bool _loading = true;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  List<DisasterEvent> get events => _events;
  DisasterPhaseLabel get selectedPhase => _selectedPhase;
  DisasterComparisonMode get comparisonMode => _comparisonMode;

  DisasterEvent? get selectedEvent {
    if (_events.isEmpty) return null;
    for (final e in _events) {
      if (e.id == _selectedEventId) return e;
    }
    return _events.first;
  }

  DisasterPhase? get selectedPhaseData => selectedEvent?.phaseFor(_selectedPhase);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _events = await _repository.loadEvents();
      _selectedEventId ??= _events.isNotEmpty ? _events.first.id : null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectEvent(String eventId) {
    if (_selectedEventId == eventId) return;
    _selectedEventId = eventId;
    notifyListeners();
  }

  void selectPhase(DisasterPhaseLabel label) {
    if (_selectedPhase == label) return;
    _selectedPhase = label;
    notifyListeners();
  }

  void setComparisonMode(DisasterComparisonMode mode) {
    if (_comparisonMode == mode) return;
    _comparisonMode = mode;
    notifyListeners();
  }
}
