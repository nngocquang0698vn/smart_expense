import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/core/utils/formatters/money.dart";
import "package:smart_expense/features/reports/application/report_controller.dart";
import "package:smart_expense/features/reports/application/report_view_model.dart";
import "package:smart_expense/features/reports/presentation/widgets/category_report_detail_body.dart";
import "package:smart_expense/features/reports/presentation/widgets/category_report_detail_panel.dart";
import "package:smart_expense/features/reports/presentation/widgets/report_breakdown_panel.dart";
import "package:smart_expense/features/reports/presentation/widgets/report_period_chips.dart";
import "package:smart_expense/shared/components/app_date_range_picker.dart";
import "package:smart_expense/shared/components/app_empty_state.dart";
import "package:smart_expense/shared/components/page_header_sliver.dart";
import "package:smart_expense/shared/components/summary_card.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final ValueNotifier<int> _touchedIndex = ValueNotifier<int>(-1);

  @override
  void dispose() {
    _touchedIndex.dispose();
    super.dispose();
  }

  void _resetTouchedIndex() {
    if (_touchedIndex.value != -1) {
      _touchedIndex.value = -1;
    }
  }

  bool _useMasterDetail(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

  Future<void> _pickCustomRange(ReportState state) async {
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
      _resetTouchedIndex();
      await ref.read(reportControllerProvider.notifier).selectCustomRange(r);
    }
  }

  void _onCategoryTap(ReportState state, ReportCategorySlice slice) {
    ref.read(reportControllerProvider.notifier).selectCategory(slice.id);
  }

  void _closeCategoryDetail() {
    ref.read(reportControllerProvider.notifier).clearSelectedCategory();
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(reportControllerProvider);
    return report.when(
      data: (state) => _useMasterDetail(context)
          ? _buildMasterDetail(state)
          : _buildMobileScroll(state),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          Center(child: AppEmptyState(message: context.l10n.genericError)),
    );
  }

  Widget _buildMasterDetail(ReportState state) {
    final detailArgs = state.detailArgsForSelectedSlice();

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
          child: Text(
            context.l10n.reportTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 7,
                child: _ReportMasterScroll(
                  state: state,
                  touchedIndex: _touchedIndex,
                  onResetTouch: _resetTouchedIndex,
                  onPickCustomRange: () => _pickCustomRange(state),
                  onCategoryTap: (slice) => _onCategoryTap(state, slice),
                  wideBreakdown: true,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 4,
                child: CategoryReportDetailPanel(
                  args: detailArgs,
                  onClose: _closeCategoryDetail,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileScroll(ReportState state) {
    final detailArgs = state.detailArgsForSelectedSlice();
    if (detailArgs != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _closeCategoryDetail();
        },
        child: CategoryReportDetailBody(
          args: detailArgs,
          showPeriodFilters: true,
          onClose: _closeCategoryDetail,
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        PageHeaderSliver(title: context.l10n.reportTitle),
        SliverFillRemaining(
          hasScrollBody: true,
          child: _ReportMasterScroll(
            state: state,
            touchedIndex: _touchedIndex,
            onResetTouch: _resetTouchedIndex,
            onPickCustomRange: () => _pickCustomRange(state),
            onCategoryTap: (slice) => _onCategoryTap(state, slice),
            wideBreakdown: false,
          ),
        ),
      ],
    );
  }
}

/// Nội dung chính báo cáo (filter, tổng, chart, danh sách hạng mục).
class _ReportMasterScroll extends ConsumerWidget {
  const _ReportMasterScroll({
    required this.state,
    required this.touchedIndex,
    required this.onResetTouch,
    required this.onPickCustomRange,
    required this.onCategoryTap,
    required this.wideBreakdown,
  });

  final ReportState state;
  final ValueNotifier<int> touchedIndex;
  final VoidCallback onResetTouch;
  final Future<void> Function() onPickCustomRange;
  final void Function(ReportCategorySlice slice) onCategoryTap;
  final bool wideBreakdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = state.viewModel;
    final loading = state.loading;
    final incomeSide = state.incomeSide;
    final l10n = context.l10n;
    final notifier = ref.read(reportControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppInsets.listBottom),
      children: [
        ReportPeriodChips(
          state: state,
          onPeriodSelected: (p) async {
            onResetTouch();
            await notifier.selectPeriod(p);
          },
          onCustomRangePick: onPickCustomRange,
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: loading
              ? const Center(
                  heightFactor: 2,
                  child: CircularProgressIndicator(),
                )
              : _SummaryRow(viewModel: viewModel),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _ToggleTab(
                  label: l10n.expense,
                  icon: Icons.arrow_downward_rounded,
                  selected: !incomeSide,
                  color: context.financeColors.expenseAmount,
                  onTap: () {
                    onResetTouch();
                    notifier.selectIncomeSide(false);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _ToggleTab(
                  label: l10n.income,
                  icon: Icons.arrow_upward_rounded,
                  selected: incomeSide,
                  color: context.financeColors.incomeAmount,
                  onTap: () {
                    onResetTouch();
                    notifier.selectIncomeSide(true);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!loading)
          ValueListenableBuilder<int>(
            valueListenable: touchedIndex,
            builder: (context, touched, _) {
              return ReportBreakdownPanel(
                slices: viewModel.slices,
                sumSlice: viewModel.sliceTotal,
                isIncome: incomeSide,
                touchedIndex: touched,
                selectedCategoryId: state.selectedCategoryId,
                onTouchIndexChanged: (i) => touchedIndex.value = i,
                onSliceTap: (_, slice) => onCategoryTap(slice),
                wideLayout: wideBreakdown,
              );
            },
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.viewModel});

  final ReportViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final net = viewModel.balance;
    final textStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            label: context.l10n.income,
            child: MoneyText(
              viewModel.income,
              isIncome: true,
              style: textStyle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SummaryCard(
            label: context.l10n.expense,
            child: MoneyText(
              viewModel.expense,
              isIncome: false,
              style: textStyle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SummaryCard(
            label: context.l10n.reportBalance,
            child: MoneyText(net.abs(), isIncome: net >= 0, style: textStyle),
          ),
        ),
      ],
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? color : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? color : cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? color : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
