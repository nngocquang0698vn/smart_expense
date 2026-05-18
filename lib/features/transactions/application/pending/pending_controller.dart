import "package:flutter/foundation.dart";

import "package:smart_expense/features/transactions/data/date_filter.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/data/models/category_model.dart";
import "package:smart_expense/features/transactions/data/models/transaction_model.dart";
import "package:smart_expense/features/transactions/application/pending/pending_view_model.dart";

class PendingController extends ChangeNotifier {
  PendingController(this._repo) {
    _repo.addListener(load);
  }

  final LedgerRepository _repo;

  DateFilterSelection filter = const DateFilterSelection(
    preset: DateFilterPreset.thisMonth,
  );
  PendingViewModel viewModel = const PendingViewModel.initial();

  bool _disposed = false;

  Future<void> load() async {
    viewModel = viewModel.copyWith(loading: true);
    _notifyIfActive();

    final results = await Future.wait([
      _repo.pendingAll(filter),
      _repo.categories(),
    ]);
    if (_disposed) return;

    viewModel = PendingViewModel(
      transactions: results[0] as List<TransactionModel>,
      categories: results[1] as List<CategoryModel>,
      loading: false,
    );
    notifyListeners();
  }

  Future<void> updateFilter(DateFilterSelection next) async {
    filter = next;
    await load();
  }

  @override
  void dispose() {
    _disposed = true;
    _repo.removeListener(load);
    super.dispose();
  }

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }
}
