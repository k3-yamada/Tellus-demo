import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/models/tellusar_job.dart';
import '../../../../domain/repositories/tellusar_repository.dart';

/// TelluSAR ジョブ送信 → ポーリング → 結果表示を司る ViewModel。
/// 投入対象ペアは外部から注入する (dashboard 由来 / 任意で固定)。
class TellusarViewModel extends ChangeNotifier {
  TellusarViewModel({
    required TellusarRepository repository,
    required TellusarPairRequest defaultPair,
  })  : _repository = repository,
        _pair = defaultPair;

  final TellusarRepository _repository;
  TellusarPairRequest _pair;
  TellusarJob? _job;
  bool _busy = false;
  String? _error;
  Timer? _pollTimer;

  TellusarPairRequest get pair => _pair;
  TellusarJob? get job => _job;
  bool get isBusy => _busy;
  String? get error => _error;

  void setPair(TellusarPairRequest pair) {
    _pair = pair;
    _job = null;
    _error = null;
    notifyListeners();
  }

  Future<void> submit() async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _job = await _repository.submitJob(_pair);
      _schedulePoll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    final job = _job;
    if (job == null || job.isTerminal) return;
    _pollTimer = Timer(const Duration(milliseconds: 800), _poll);
  }

  Future<void> _poll() async {
    final current = _job;
    if (current == null) return;
    try {
      final updated = await _repository.fetchStatus(current.jobId);
      _job = updated;
      notifyListeners();
      if (!updated.isTerminal) _schedulePoll();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
