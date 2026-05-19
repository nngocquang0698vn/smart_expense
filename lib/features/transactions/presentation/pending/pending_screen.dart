import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/features/transactions/application/pending/pending_controller.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/presentation/date_filter_sheet.dart";
import "package:smart_expense/features/transactions/presentation/transaction_editor_sheet.dart";
import "package:smart_expense/shared/components/app_confirm_bottom_sheet.dart";
import "package:smart_expense/shared/components/app_empty_state.dart";
import "package:smart_expense/shared/components/page_header_sliver.dart";
import "package:smart_expense/shared/components/tx_row.dart";
import "package:smart_expense/features/dashboard/utils/tx_grouping.dart";

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

class _PendingContent extends ConsumerWidget {
  const _PendingContent({required this.state});

  final PendingState state;

  Future<void> _pickFilter(BuildContext context, WidgetRef ref) async {
    final next = await showDateFilterSheet(context, state.filter);
    if (next != null && context.mounted) {
      await ref.read(pendingControllerProvider.notifier).updateFilter(next);
    }
  }

  void _openEditor(
    BuildContext context,
    WidgetRef ref,
    LedgerTransaction transaction,
  ) {
    showTransactionEditor(
      context,
      ref.read(ledgerRepositoryProvider),
      existing: transaction,
    );
  }

  Future<void> _confirmPending(
    BuildContext context,
    WidgetRef ref,
    LedgerTransaction transaction,
  ) async {
    final ok = await AppConfirmBottomSheet.show(
      context,
      title: context.l10n.confirmPendingTitle,
      message: context.l10n.confirmPendingMessage,
    );
    if (!ok || !context.mounted) return;
    await ref.read(ledgerRepositoryProvider).confirmPending(transaction.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final categoryMap = viewModel.categoryMap;
    final buckets = groupByDay(viewModel.transactions);

    return CustomScrollView(
      slivers: [
        PageHeaderSliver(
          title: context.l10n.navPending,
          actions: [
            TextButton.icon(
              onPressed: () => _pickFilter(context, ref),
              icon: const Icon(Icons.filter_alt_outlined),
              label: Text(localizedDateFilterLabel(context.l10n, state.filter)),
            ),
          ],
        ),
        if (viewModel.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: AppEmptyState(message: context.l10n.noPending),
            ),
          )
        else ...[
          for (final bucket in buckets) ...[
            SliverToBoxAdapter(
              child: TxDayHeader(
                day: bucket.day,
                totalVnd: bucket.items.fold(
                  0,
                  (sum, transaction) => sum + transaction.amountVnd,
                ),
                count: bucket.items.length,
              ),
            ),
            ...bucket.items.map(
              (transaction) => SliverToBoxAdapter(
                child: TxRow(
                  transaction: transaction,
                  category: categoryMap[transaction.categoryId],
                  trailing: buildPendingActions(
                    context: context,
                    transaction: transaction,
                    onConfirm: () => _confirmPending(context, ref, transaction),
                    onEdit: () => _openEditor(context, ref, transaction),
                  ),
                  onTap: () => _openEditor(context, ref, transaction),
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(
            child: SizedBox(height: AppInsets.listBottom),
          ),
        ],
      ],
    );
  }
}
