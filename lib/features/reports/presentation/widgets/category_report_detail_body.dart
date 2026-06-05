import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/dashboard/utils/tx_grouping.dart";
import "package:smart_expense/features/reports/application/category_report_transactions_provider.dart";
import "package:smart_expense/features/reports/application/report_category_detail_args.dart";
import "package:smart_expense/features/reports/application/report_controller.dart";
import "package:smart_expense/features/reports/presentation/widgets/category_report_summary_card.dart";
import "package:smart_expense/features/reports/presentation/widgets/report_period_chips.dart";
import "package:smart_expense/features/transactions/presentation/transaction_editor_sheet.dart";
import "package:smart_expense/shared/components/app_date_range_picker.dart";
import "package:smart_expense/shared/components/app_empty_state.dart";
import "package:smart_expense/shared/components/tx_row.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Nội dung báo cáo chi tiết một hạng mục (panel hoặc full-screen).
class CategoryReportDetailBody extends ConsumerWidget {
  const CategoryReportDetailBody({
    super.key,
    required this.args,
    required this.onClose,
    this.showPeriodFilters = false,
    this.embeddedInPanel = false,
  });

  final ReportCategoryDetailArgs args;
  final VoidCallback onClose;

  /// Hiện chip kỳ khi mở full-screen mobile (desktop dùng filter bên trái).
  final bool showPeriodFilters;
  final bool embeddedInPanel;

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final state = ref.read(reportControllerProvider).value;
    if (state == null) return;
    final now = DateTime.now();
    final r = await showAppDateRangePicker(
      context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialRange:
          state.customRange ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    if (r != null) {
      await ref.read(reportControllerProvider.notifier).selectCustomRange(r);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(reportControllerProvider).value;
    final resolved = embeddedInPanel
        ? (reportState?.detailArgsForSelectedSlice() ?? args)
        : (showPeriodFilters && reportState != null
              ? _liveArgs(reportState)
              : args);

    final detail = ref.watch(categoryReportDetailProvider(resolved));
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailHeader(
          title: resolved.category.name,
          subtitle: l10n.reportCategoryDetailSubtitle,
          onClose: onClose,
          embeddedInPanel: embeddedInPanel,
        ),
        if (showPeriodFilters && reportState != null) ...[
          ReportPeriodChips(
            state: reportState,
            onPeriodSelected: (p) =>
                ref.read(reportControllerProvider.notifier).selectPeriod(p),
            onCustomRangePick: () => _pickCustomRange(context, ref),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Expanded(
          child: detail.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                Center(child: AppEmptyState(message: l10n.genericError)),
            data: (data) {
              final buckets = groupByDay(data.transactions);

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppInsets.listBottom,
                ),
                children: [
                  CategoryReportSummaryCard(
                    category: resolved.category,
                    totalAmountVnd: resolved.totalAmountVnd,
                    isIncome: resolved.isIncomeSide,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (buckets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
                      child: AppEmptyState(
                        message: l10n.noDataForPeriod,
                        icon: Icons.receipt_long_outlined,
                      ),
                    )
                  else
                    for (final bucket in buckets) ...[
                      TxDayHeader(
                        day: bucket.day,
                        totalVnd: bucket.items.fold(
                          0,
                          (sum, t) => sum + t.amountVnd,
                        ),
                        count: bucket.items.length,
                      ),
                      ...bucket.items.map(
                        (t) => TxRow(
                          key: ValueKey("cat-detail-${t.id}"),
                          transaction: t,
                          category: data.categoriesById[t.categoryId],
                          onTap: () => showTransactionEditor(
                            context,
                            ref.read(ledgerRepositoryProvider),
                            existing: t,
                          ),
                        ),
                      ),
                    ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  ReportCategoryDetailArgs _liveArgs(ReportState state) {
    for (final slice in state.viewModel.slices) {
      if (slice.id == args.categoryId) {
        return ReportCategoryDetailArgs(
          category: slice.category,
          isIncomeSide: state.incomeSide,
          period: state.period,
          customRange: state.customRange,
          totalAmountVnd: slice.amount,
        );
      }
    }
    return ReportCategoryDetailArgs(
      category: args.category,
      isIncomeSide: state.incomeSide,
      period: state.period,
      customRange: state.customRange,
      totalAmountVnd: args.totalAmountVnd,
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.embeddedInPanel,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final bool embeddedInPanel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        embeddedInPanel ? AppSpacing.sm : AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              embeddedInPanel ? Icons.close_rounded : Icons.arrow_back_rounded,
            ),
            tooltip: embeddedInPanel ? context.l10n.close : context.l10n.back,
            onPressed: onClose,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
