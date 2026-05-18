import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/features/transactions/application/pending/pending_controller.dart";
import "package:smart_expense/features/transactions/data/models/transaction_model.dart";
import "package:smart_expense/features/transactions/presentation/date_filter_sheet.dart";
import "package:smart_expense/features/transactions/presentation/transaction_editor_sheet.dart";
import "package:smart_expense/shared/components/app_confirm_bottom_sheet.dart";
import "package:smart_expense/shared/components/app_empty_state.dart";
import "package:smart_expense/shared/components/page_header_sliver.dart";
import "package:smart_expense/shared/components/tx_row.dart";
import "package:smart_expense/features/dashboard/utils/tx_grouping.dart";

class PendingScreen extends ConsumerStatefulWidget {
  const PendingScreen({super.key});

  @override
  ConsumerState<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends ConsumerState<PendingScreen> {
  late final PendingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PendingController(ref.read(ledgerRepositoryProvider))..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFilter() async {
    final next = await showDateFilterSheet(context, _controller.filter);
    if (next != null && mounted) {
      await _controller.updateFilter(next);
    }
  }

  void _openEditor(TransactionModel transaction) {
    showTransactionEditor(
      context,
      ref.read(ledgerRepositoryProvider),
      existing: transaction,
    );
  }

  Future<void> _confirmPending(TransactionModel transaction) async {
    final ok = await AppConfirmBottomSheet.show(
      context,
      title: context.l10n.confirmPendingTitle,
      message: context.l10n.confirmPendingMessage,
    );
    if (!ok || !mounted) return;
    await ref.read(ledgerRepositoryProvider).confirmPending(transaction.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final viewModel = _controller.viewModel;
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
                  onPressed: _pickFilter,
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: Text(_controller.filter.label()),
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
                        onConfirm: () => _confirmPending(transaction),
                        onEdit: () => _openEditor(transaction),
                      ),
                      onTap: () => _openEditor(transaction),
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
      },
    );
  }
}
