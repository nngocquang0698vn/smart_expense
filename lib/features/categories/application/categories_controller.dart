import "package:flutter/foundation.dart";

import "../../../data/ledger_repository.dart";
import "../../../data/models/category_model.dart";
import "categories_view_model.dart";
import "category_editor_policy.dart";

class CategoriesController extends ChangeNotifier {
  CategoriesController({
    required LedgerRepository repo,
    CategoryEditorPolicy policy = const CategoryEditorPolicy(),
  }) : _repo = repo,
       _policy = policy {
    _repo.addListener(load);
  }

  final LedgerRepository _repo;
  final CategoryEditorPolicy _policy;

  bool _loading = true;
  bool _disposed = false;
  CategoriesViewModel _viewModel = CategoriesViewModel.empty();

  bool get loading => _loading;
  CategoriesViewModel get viewModel => _viewModel;

  Future<void> load() async {
    final categories = await _repo.categories();
    if (_disposed) return;
    _viewModel = CategoriesViewModel.fromCategories(categories);
    _loading = false;
    notifyListeners();
  }

  Future<void> toggleEnabled(CategoryModel category) {
    return _repo.upsertCategory(category.copyWith(enabled: !category.enabled));
  }

  Future<CategoryValidationResult> saveDraft({
    required CategoryDraft draft,
    CategoryModel? existing,
  }) async {
    final result = _policy.validate(draft);
    if (!result.isValid) return result;

    final normalized = result.draft;
    if (existing == null) {
      await _repo.createCategory(
        name: normalized.name,
        isIncome: normalized.isIncome,
        iconKey: normalized.iconKey,
        colorValue: normalized.colorValue,
      );
    } else {
      await _repo.upsertCategory(
        existing.copyWith(
          name: normalized.name,
          iconKey: normalized.iconKey,
          colorValue: normalized.colorValue,
          isIncome: normalized.isIncome,
        ),
      );
    }
    return result;
  }

  Future<CategoryDeleteDecision> canDelete(CategoryModel category) async {
    final inUse = await _repo.categoryInUse(category.id);
    return _policy.validateDelete(category, inUse: inUse);
  }

  Future<void> delete(CategoryModel category) {
    return _repo.deleteCategory(category.id);
  }

  @override
  void dispose() {
    _disposed = true;
    _repo.removeListener(load);
    super.dispose();
  }
}
