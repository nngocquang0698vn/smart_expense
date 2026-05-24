import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/features/transactions/application/confirm_pending_flow.dart";
import "package:smart_expense/features/transactions/application/pending/pending_controller.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/presentation/date_filter_sheet.dart";
import "package:smart_expense/features/transactions/presentation/pending/widgets/pending_attachment_filter_chips.dart";
import "package:smart_expense/features/transactions/presentation/pending/widgets/pending_reconciliation_detail_panel.dart";
import "package:smart_expense/features/transactions/presentation/transaction_editor_body.dart";
import "package:smart_expense/shared/components/app_discard_dialog.dart";
import "package:smart_expense/shared/components/app_empty_state.dart";
import "package:smart_expense/shared/components/page_header_sliver.dart";
import "package:smart_expense/shared/components/tx_row.dart";
import "package:smart_expense/features/dashboard/utils/tx_grouping.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingControllerProvider);

    return pending.when(
      data: (state) => _PendingContent(state: state),
      error: (_, _) => CustomScrollView(
        slivers: [
          PageHeaderSliver(title: context.l10n.navPending),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: AppEmptyState(message: context.l10n.genericError),
            ),
          ),
        ],
      ),
      loading: () => CustomScrollView(
        slivers: [
          PageHeaderSliver(title: context.l10n.navPending),
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

class _PendingContent extends ConsumerStatefulWidget {
  const _PendingContent({required this.state});

  final PendingState state;

  @override
  ConsumerState<_PendingContent> createState() => _PendingContentState();
}

class _PendingContentState extends ConsumerState<_PendingContent> {
  final _detailEditorKey = GlobalKey<TransactionEditorBodyState>();

  bool _useMasterDetail(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

  PendingState get state => widget.state;

  Future<void> _pickDateFilter() async {
    final next = await showDateFilterSheet(context, state.filter);
    if (next != null && context.mounted) {
      await ref.read(pendingControllerProvider.notifier).updateFilter(next);
    }
  }

  Future<void> _confirmPending(LedgerTransaction transaction) async {
    await runConfirmPendingFlow(
      context: context,
      ref: ref,
      transactionId: transaction.id,
    );
    if (context.mounted) {
      ref.read(pendingControllerProvider.notifier).selectNext();
    }
  }

  Future<void> _onPrevious() async {
    ref.read(pendingControllerProvider.notifier).selectPrevious();
  }

  Future<void> _onNext() async {
    ref.read(pendingControllerProvider.notifier).selectNext();
  }

  Future<bool> _confirmDiscardIfDirty() async {
    final editor = _detailEditorKey.currentState;
    if (editor == null || !editor.isDirty) return true;
    final discard = await showDiscardEditDialog(context);
    if (discard) await editor.discardUnsavedImages();
    return discard;
  }

  Future<void> _selectTransaction(String id) async {
    if (state.selectedTransactionId == id) return;
    if (!await _confirmDiscardIfDirty()) return;
    ref.read(pendingControllerProvider.notifier).selectTransaction(id);
  }

  Future<void> _clearMobileDetail() async {
    if (!await _confirmDiscardIfDirty()) return;
    ref.read(pendingControllerProvider.notifier).clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = state.viewModel;
    if (viewModel.loading) {
      return CustomScrollView(
        slivers: [
          PageHeaderSliver(title: context.l10n.navPending),
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_useMasterDetail(context)) {
      return _buildMasterDetail(context);
    }

    final selected = state.selectedTransaction;
    if (selected != null) {
      return PendingReconciliationDetailPanel(
        transaction: selected,
        filteredTransactions: state.filteredTransactions,
        editorKey: _detailEditorKey,
        showBack: true,
        onBack: _clearMobileDetail,
        onPrevious: _onPrevious,
        onNext: _onNext,
      );
    }

    return _buildListOnly(context);
  }

  Widget _buildMasterDetail(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.navPending,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _pickDateFilter,
                icon: const Icon(Icons.filter_alt_outlined),
                label: Text(
                  localizedDateFilterLabel(context.l10n, state.filter),
                ),
              ),
            ],
          ),
        ),
        PendingAttachmentFilterChips(
          selected: state.attachmentFilter,
          onSelected: ref
              .read(pendingControllerProvider.notifier)
              .setAttachmentFilter,
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: _PendingListPane(
                  state: state,
                  selectedId: state.selectedTransactionId,
                  onSelect: _selectTransaction,
                  onConfirm: _confirmPending,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 6,
                child: PendingReconciliationDetailPanel(
                  transaction: state.selectedTransaction,
                  filteredTransactions: state.filteredTransactions,
                  editorKey: _detailEditorKey,
                  onPrevious: _onPrevious,
                  onNext: _onNext,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListOnly(BuildContext context) {
    final viewModel = state.viewModel;
    final filtered = state.filteredTransactions;

    return CustomScrollView(
      slivers: [
        PageHeaderSliver(
          title: context.l10n.navPending,
          actions: [
            TextButton.icon(
              onPressed: _pickDateFilter,
              icon: const Icon(Icons.filter_alt_outlined),
              label: Text(localizedDateFilterLabel(context.l10n, state.filter)),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: PendingAttachmentFilterChips(
            selected: state.attachmentFilter,
            onSelected: ref
                .read(pendingControllerProvider.notifier)
                .setAttachmentFilter,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),
        if (viewModel.transactions.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: AppEmptyState(message: context.l10n.noPending),
            ),
          )
        else if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: AppEmptyState(message: context.l10n.pendingFilterEmpty),
            ),
          )
        else
          _transactionSliver(
            context,
            filtered: filtered,
            categoryMap: viewModel.categoryMap,
            selectedId: null,
            onSelect: _selectTransaction,
            onConfirm: _confirmPending,
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppInsets.listBottom)),
      ],
    );
  }
}

class _PendingListPane extends StatelessWidget {
  const _PendingListPane({
    required this.state,
    required this.selectedId,
    required this.onSelect,
    required this.onConfirm,
  });

  final PendingState state;
  final String? selectedId;
  final Future<void> Function(String) onSelect;
  final Future<void> Function(LedgerTransaction) onConfirm;

  @override
  Widget build(BuildContext context) {
    final viewModel = state.viewModel;
    final filtered = state.filteredTransactions;

    if (viewModel.transactions.isEmpty) {
      return Center(child: AppEmptyState(message: context.l10n.noPending));
    }
    if (filtered.isEmpty) {
      return Center(
        child: AppEmptyState(message: context.l10n.pendingFilterEmpty),
      );
    }

    return CustomScrollView(
      slivers: [
        _transactionSliver(
          context,
          filtered: filtered,
          categoryMap: viewModel.categoryMap,
          selectedId: selectedId,
          onSelect: onSelect,
          onConfirm: onConfirm,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppInsets.listBottom)),
      ],
    );
  }
}

Widget _transactionSliver(
  BuildContext context, {
  required List<LedgerTransaction> filtered,
  required Map<String, LedgerCategory> categoryMap,
  required String? selectedId,
  required Future<void> Function(String) onSelect,
  required Future<void> Function(LedgerTransaction) onConfirm,
}) {
  final entries = _pendingListEntries(filtered);
  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) {
        final entry = entries[index];
        final transaction = entry.transaction;
        if (transaction == null) {
          return TxDayHeader(
            key: entry.key,
            day: entry.day!,
            totalVnd: entry.totalVnd,
            count: entry.count,
          );
        }

        return KeyedSubtree(
          key: entry.key,
          child: TxRow(
            key: ValueKey(transaction.id),
            transaction: transaction,
            category: categoryMap[transaction.categoryId],
            selected: selectedId == transaction.id,
            showInlineAudioPlayer: false,
            showReviewContext: true,
            trailing: buildPendingConfirmButton(
              context: context,
              transaction: transaction,
              onConfirm: () => onConfirm(transaction),
            ),
            onTap: () => onSelect(transaction.id),
          ),
        );
      },
      childCount: entries.length,
      findChildIndexCallback: (key) {
        for (var i = 0; i < entries.length; i++) {
          if (entries[i].key == key) return i;
        }
        return null;
      },
    ),
  );
}

List<_PendingListEntry> _pendingListEntries(List<LedgerTransaction> filtered) {
  final buckets = groupByDay(filtered);
  return [
    for (final bucket in buckets) ...[
      _PendingListEntry.header(
        day: bucket.day,
        totalVnd: bucket.items.fold(
          0,
          (sum, transaction) => sum + transaction.amountVnd,
        ),
        count: bucket.items.length,
      ),
      ...bucket.items.map(_PendingListEntry.transaction),
    ],
  ];
}

class _PendingListEntry {
  const _PendingListEntry.header({
    required this.day,
    required this.totalVnd,
    required this.count,
  }) : transaction = null;

  const _PendingListEntry.transaction(this.transaction)
    : day = null,
      totalVnd = 0,
      count = 0;

  final DateTime? day;
  final int totalVnd;
  final int count;
  final LedgerTransaction? transaction;

  Key get key {
    final tx = transaction;
    if (tx != null) return ValueKey("pending-${tx.id}");
    return ValueKey("pending-day-${day!.microsecondsSinceEpoch}");
  }
}
