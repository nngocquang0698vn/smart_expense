import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/transactions/application/pending/pending_attachment_filter.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/presentation/pending/widgets/pending_editor_action_bar.dart";
import "package:smart_expense/features/transactions/presentation/pending/widgets/pending_transaction_nav_buttons.dart";
import "package:smart_expense/features/transactions/presentation/transaction_editor_body.dart";
import "package:smart_expense/shared/components/app_discard_dialog.dart";
import "package:smart_expense/shared/components/app_empty_state.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Panel chỉnh sửa giao dịch chờ (desktop master-detail / mobile full-width).
class PendingReconciliationDetailPanel extends ConsumerStatefulWidget {
  const PendingReconciliationDetailPanel({
    super.key,
    required this.transaction,
    required this.filteredTransactions,
    required this.onPrevious,
    required this.onNext,
    this.editorKey,
    this.showBack = false,
    this.onBack,
  });

  final LedgerTransaction? transaction;
  final List<LedgerTransaction> filteredTransactions;
  final Future<void> Function() onPrevious;
  final Future<void> Function() onNext;
  final GlobalKey<TransactionEditorBodyState>? editorKey;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  ConsumerState<PendingReconciliationDetailPanel> createState() =>
      _PendingReconciliationDetailPanelState();
}

class _PendingReconciliationDetailPanelState
    extends ConsumerState<PendingReconciliationDetailPanel> {
  final _fallbackEditorKey = GlobalKey<TransactionEditorBodyState>();

  GlobalKey<TransactionEditorBodyState> get _editorKey =>
      widget.editorKey ?? _fallbackEditorKey;

  Future<void> _navigate(Future<void> Function() action) async {
    final editor = _editorKey.currentState;
    if (editor != null && editor.isDirty) {
      final discard = await showDiscardEditDialog(context);
      if (!discard || !mounted) return;
      await editor.discardUnsavedImages();
    }
    await action();
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    if (tx == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppEmptyState(
            message: context.l10n.pendingSelectTransactionHint,
            icon: Icons.touch_app_outlined,
          ),
        ),
      );
    }

    final repo = ref.read(ledgerRepositoryProvider);
    final filtered = widget.filteredTransactions;
    final canPrev = canGoToPreviousPending(
      filtered: filtered,
      currentId: tx.id,
    );
    final canNext = canGoToNextPending(filtered: filtered, currentId: tx.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.showBack)
                IconButton(
                  tooltip: context.l10n.back,
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      context.l10n.editTransaction,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    PendingTransactionNavButtons(
                      canGoPrevious: canPrev,
                      canGoNext: canNext,
                      onPrevious: () => _navigate(widget.onPrevious),
                      onNext: () => _navigate(widget.onNext),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TransactionEditorBody(
            key: _editorKey,
            repo: repo,
            existing: tx,
            presentation: TransactionEditorPresentation.embedded,
            footerActions: PendingEditorActionBar(
              onSave: () => _editorKey.currentState?.saveTransaction(),
              onDelete: () => _editorKey.currentState?.deleteTransaction(),
            ),
          ),
        ),
      ],
    );
  }
}
