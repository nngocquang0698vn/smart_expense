import "package:flutter/material.dart";

import "../core/constants.dart";
import "../core/strings.dart";
import "../data/ledger_repository.dart";
import "../data/models/transaction_model.dart";
import "../features/pending/application/pending_controller.dart";
import "../shared/widgets/app_confirm_bottom_sheet.dart";
import "../utils/tx_grouping.dart";
import "../widgets/date_filter_sheet.dart";
import "../widgets/page_header_sliver.dart";
import "../widgets/transaction_editor_sheet.dart";
import "../widgets/tx_row.dart";

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key, required this.repo});

  final LedgerRepository repo;

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  late final PendingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PendingController(widget.repo)..load();
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
    showTransactionEditor(context, widget.repo, existing: transaction);
  }

  Future<void> _confirmPending(TransactionModel transaction) async {
    final ok = await AppConfirmBottomSheet.show(
      context,
      title: AppStrings.confirmPendingTitle,
      message: AppStrings.confirmPendingMessage,
    );
    if (!ok || !mounted) return;
    await widget.repo.confirmPending(transaction.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final viewModel = _controller.viewModel;
        if (viewModel.loading) {
          return const CustomScrollView(
            slivers: [
              PageHeaderSliver(title: AppStrings.navPending),
              SliverFillRemaining(
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
              title: AppStrings.navPending,
              actions: [
                TextButton.icon(
                  onPressed: _pickFilter,
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: Text(_controller.filter.label()),
                ),
              ],
            ),
            if (viewModel.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(AppStrings.noPending)),
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
