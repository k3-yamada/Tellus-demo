import 'package:flutter/foundation.dart';

import '../../../../domain/models/asset_template.dart';
import '../../../../domain/repositories/template_catalog_repository.dart';

class TemplateSwitcherViewModel extends ChangeNotifier {
  TemplateSwitcherViewModel({required TemplateCatalogRepository repository})
      : _repository = repository;

  final TemplateCatalogRepository _repository;

  List<AssetTemplate> _templates = const [];
  bool _loading = true;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  List<AssetTemplate> get templates => _templates;

  AssetTemplate? get defaultTemplate {
    for (final t in _templates) {
      if (t.isDefault) return t;
    }
    return _templates.isNotEmpty ? _templates.first : null;
  }

  /// Dropdown の value は items 内の同一インスタンスである必要があるため id で解決する。
  AssetTemplate? resolveForSelection(AssetTemplate? selection) {
    if (selection == null) return defaultTemplate;
    for (final t in _templates) {
      if (t.id == selection.id) return t;
    }
    return defaultTemplate;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _templates = await _repository.loadTemplates();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
