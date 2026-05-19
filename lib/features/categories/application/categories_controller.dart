import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/categories/application/categories_view_model.dart";
import "package:smart_expense/features/categories/application/category_editor_policy.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

final categoriesControllerProvider =
    AsyncNotifierProvider.autoDispose<CategoriesController, CategoriesState>(
      CategoriesController.new,
    );

class CategoriesState {
  const CategoriesState({required this.viewModel, required this.loading});

  CategoriesState.initial()
    : viewModel = CategoriesViewModel.empty(),
      loading = true;

  final CategoriesViewModel viewModel;
  final bool loading;
}

class CategoriesController extends AsyncNotifier<CategoriesState> {
  final CategoryEditorPolicy _policy = const CategoryEditorPolicy();
  StreamSubscription<void>? _repoSubscription;

  LedgerRepository get _repo => ref.read(ledgerRepositoryProvider);

  @override
  Future<CategoriesState> build() async {
    final initial = await _load();
    if (!ref.mounted) return initial;
    _repoSubscription?.cancel();
    _repoSubscription = _repo.changes.listen((_) => reload());
    ref.onDispose(() => _repoSubscription?.cancel());
    return initial;
  }

  Future<void> reload() async {
    state = AsyncData(CategoriesState.initial());
    final next = await AsyncValue.guard(_load);
    if (ref.mounted) state = next;
  }

  Future<void> toggleEnabled(LedgerCategory category) {
    return _repo.upsertCategory(category.copyWith(enabled: !category.enabled));
  }

  Future<CategoryValidationResult> saveDraft({
    required CategoryDraft draft,
    LedgerCategory? existing,
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

  Future<CategoryDeleteDecision> canDelete(LedgerCategory category) async {
    final inUse = await _repo.categoryInUse(category.id);
    return _policy.validateDelete(category, inUse: inUse);
  }

  Future<void> delete(LedgerCategory category) {
    return _repo.deleteCategory(category.id);
  }

  Future<CategoriesState> _load() async {
    final categories = await _repo.categories();
    return CategoriesState(
      viewModel: CategoriesViewModel.fromCategories(categories),
      loading: false,
    );
  }
}
