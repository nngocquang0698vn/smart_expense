import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/transactions/application/pending/pending_view_model.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

final pendingControllerProvider =
    AsyncNotifierProvider.autoDispose<PendingController, PendingState>(
      PendingController.new,
    );

class PendingState {
  const PendingState({required this.filter, required this.viewModel});

  const PendingState.initial()
    : filter = const DateFilterSelection(preset: DateFilterPreset.thisMonth),
      viewModel = const PendingViewModel.initial();

  final DateFilterSelection filter;
  final PendingViewModel viewModel;

  PendingState copyWith({
    DateFilterSelection? filter,
    PendingViewModel? viewModel,
  }) {
    return PendingState(
      filter: filter ?? this.filter,
      viewModel: viewModel ?? this.viewModel,
    );
  }
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
  }

  Future<PendingState> _load(PendingState current) async {
    final results = await Future.wait([
      _repo.pendingAll(current.filter),
      _repo.categories(),
    ]);

    return current.copyWith(
      viewModel: PendingViewModel(
        transactions: results[0] as List<LedgerTransaction>,
        categories: results[1] as List<LedgerCategory>,
        loading: false,
      ),
    );
  }
}
