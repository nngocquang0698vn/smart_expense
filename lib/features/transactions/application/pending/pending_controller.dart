import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/transactions/application/pending/pending_view_model.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/application/pending/pending_attachment_filter.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

final pendingControllerProvider =
    AsyncNotifierProvider.autoDispose<PendingController, PendingState>(
      PendingController.new,
    );

class PendingState {
  const PendingState({
    required this.filter,
    required this.viewModel,
    this.attachmentFilter = PendingAttachmentFilter.all,
    this.selectedTransactionId,
  });

  const PendingState.initial()
    : filter = const DateFilterSelection(preset: DateFilterPreset.thisMonth),
      viewModel = const PendingViewModel.initial(),
      attachmentFilter = PendingAttachmentFilter.all,
      selectedTransactionId = null;

  final DateFilterSelection filter;
  final PendingViewModel viewModel;
  final PendingAttachmentFilter attachmentFilter;
  final String? selectedTransactionId;

  List<LedgerTransaction> get filteredTransactions =>
      filterPendingByAttachment(viewModel.transactions, attachmentFilter);

  LedgerTransaction? get selectedTransaction {
    final id = selectedTransactionId;
    if (id == null) return null;
    for (final t in filteredTransactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  PendingState copyWith({
    DateFilterSelection? filter,
    PendingViewModel? viewModel,
    PendingAttachmentFilter? attachmentFilter,
    Object? selectedTransactionId = _unset,
  }) {
    return PendingState(
      filter: filter ?? this.filter,
      viewModel: viewModel ?? this.viewModel,
      attachmentFilter: attachmentFilter ?? this.attachmentFilter,
      selectedTransactionId: selectedTransactionId == _unset
          ? this.selectedTransactionId
          : selectedTransactionId as String?,
    );
  }

  static const _unset = Object();
}

class PendingController extends AsyncNotifier<PendingState> {
  late LedgerRepository _repo;
  StreamSubscription<void>? _repoSubscription;

  @override
  Future<PendingState> build() async {
    _repo = ref.watch(ledgerRepositoryProvider);
    final initial = await _load(const PendingState.initial());
    if (!ref.mounted) return initial;
    _repoSubscription?.cancel();
    _repoSubscription = _repo.changes.listen((_) => reload());
    ref.onDispose(() => _repoSubscription?.cancel());
    return initial;
  }

  Future<void> reload() async {
    final current = state.value ?? const PendingState.initial();
    state = AsyncData(
      current.copyWith(viewModel: current.viewModel.copyWith(loading: true)),
    );
    final next = await AsyncValue.guard(() => _load(current));
    if (ref.mounted) state = next;
  }

  Future<void> updateFilter(DateFilterSelection filter) async {
    final current = state.value ?? const PendingState.initial();
    final updated = current.copyWith(filter: filter);
    state = AsyncData(
      updated.copyWith(viewModel: updated.viewModel.copyWith(loading: true)),
    );
    final nextState = await AsyncValue.guard(() => _load(updated));
    if (ref.mounted) state = nextState;
    _syncSelectionAfterDataChange();
  }

  void setAttachmentFilter(PendingAttachmentFilter filter) {
    final current = state.value;
    if (current == null) return;
    final filtered = filterPendingByAttachment(
      current.viewModel.transactions,
      filter,
    );
    final nextId = reconcilePendingSelection(
      filtered: filtered,
      selectedId: current.selectedTransactionId,
    );
    state = AsyncData(
      current.copyWith(
        attachmentFilter: filter,
        selectedTransactionId: nextId,
      ),
    );
  }

  void selectTransaction(String? id) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedTransactionId: id));
  }

  void clearSelection() {
    selectTransaction(null);
  }

  /// Chọn giao dịch kế tiếp trong danh sách đã lọc.
  bool selectNext() {
    final current = state.value;
    if (current == null) return false;
    final nextId = nextPendingTransactionId(
      filtered: current.filteredTransactions,
      currentId: current.selectedTransactionId,
    );
    if (nextId == null) return false;
    state = AsyncData(current.copyWith(selectedTransactionId: nextId));
    return true;
  }

  /// Chọn giao dịch trước đó trong danh sách đã lọc.
  bool selectPrevious() {
    final current = state.value;
    if (current == null) return false;
    final prevId = previousPendingTransactionId(
      filtered: current.filteredTransactions,
      currentId: current.selectedTransactionId,
    );
    if (prevId == null) return false;
    state = AsyncData(current.copyWith(selectedTransactionId: prevId));
    return true;
  }

  void _syncSelectionAfterDataChange() {
    final current = state.value;
    if (current == null) return;
    final nextId = reconcilePendingSelection(
      filtered: current.filteredTransactions,
      selectedId: current.selectedTransactionId,
    );
    if (nextId != current.selectedTransactionId) {
      state = AsyncData(current.copyWith(selectedTransactionId: nextId));
    }
  }

  Future<PendingState> _load(PendingState current) async {
    final results = await Future.wait([
      _repo.pendingAll(current.filter),
      _repo.categories(),
    ]);

    final loaded = current.copyWith(
      viewModel: PendingViewModel(
        transactions: results[0] as List<LedgerTransaction>,
        categories: results[1] as List<LedgerCategory>,
        loading: false,
      ),
    );
    final nextId = reconcilePendingSelection(
      filtered: filterPendingByAttachment(
        loaded.viewModel.transactions,
        loaded.attachmentFilter,
      ),
      selectedId: loaded.selectedTransactionId,
    );
    return loaded.copyWith(selectedTransactionId: nextId);
  }
}
