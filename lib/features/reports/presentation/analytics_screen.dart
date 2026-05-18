import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/utils/date_format.dart";
import "package:smart_expense/shared/components/app_date_range_picker.dart";
import "package:smart_expense/core/utils/formatters/money.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/page_header_sliver.dart";
import "package:smart_expense/shared/components/summary_card.dart";
import "package:smart_expense/features/transactions/data/date_filter.dart";
import "package:smart_expense/features/transactions/data/models/category_model.dart";
import "package:smart_expense/shared/components/app_empty_state.dart";
import "package:smart_expense/shared/design_system/theme/app_finance_colors.dart";
import "package:smart_expense/features/reports/application/report_controller.dart";
import "package:smart_expense/features/reports/application/report_view_model.dart";

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  late final ReportController _controller;
  int _touchedIndex = -1;

  AnalyticsPeriod get _period => _controller.period;

  DateTimeRange? get _custom => _controller.customRange;

  @override
  void initState() {
    super.initState();
    _controller = ReportController(ref.read(ledgerRepositoryProvider))..load();
    _controller.addListener(_resetTouchedSlice);
  }

  @override
  void dispose() {
    _controller.removeListener(_resetTouchedSlice);
    _controller.dispose();
    super.dispose();
  }

  void _resetTouchedSlice() {
    if (!mounted) return;
    setState(() => _touchedIndex = -1);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final r = await showAppDateRangePicker(
      context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialRange:
          _controller.customRange ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    if (r != null) {
      await _controller.selectCustomRange(r);
    }
  }

  String _periodLabel() {
    if (_period == AnalyticsPeriod.custom && _custom != null) {
      return "${formatReportAxis(_custom!.start)} – ${formatReportAxis(_custom!.end)}";
    }
    return _period.labelVi;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final viewModel = _controller.viewModel;
    final income = viewModel.income;
    final expense = viewModel.expense;
    final net = viewModel.balance;
    final slices = viewModel.slices;
    final sumSlice = viewModel.sliceTotal;
    final loading = _controller.loading;
    final incomeSide = _controller.incomeSide;

    return CustomScrollView(
      slivers: [
        PageHeaderSliver(title: context.l10n.reportTitle),

        // ── Period chips ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final p in AnalyticsPeriod.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        p == AnalyticsPeriod.custom
                            ? (_period == p ? _periodLabel() : p.labelVi)
                            : p.labelVi,
                      ),
                      selected: _period == p,
                      onSelected: (v) async {
                        if (!v) return;
                        if (p == AnalyticsPeriod.custom) {
                          await _pickCustomRange();
                        } else {
                          await _controller.selectPeriod(p);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Summary cards ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: loading
                ? const Center(
                    heightFactor: 2,
                    child: CircularProgressIndicator(),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          label: context.l10n.income,
                          child: MoneyText(
                            income,
                            isIncome: true,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          label: context.l10n.expense,
                          child: MoneyText(
                            expense,
                            isIncome: false,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          label: context.l10n.reportBalance,
                          child: MoneyText(
                            net.abs(),
                            isIncome: net >= 0,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Income / Expense toggle ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _ToggleTab(
                    label: context.l10n.expense,
                    icon: Icons.arrow_downward_rounded,
                    selected: !incomeSide,
                    color: context.financeColors.expenseAmount,
                    onTap: () {
                      _controller.selectIncomeSide(false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ToggleTab(
                    label: context.l10n.income,
                    icon: Icons.arrow_upward_rounded,
                    selected: incomeSide,
                    color: context.financeColors.incomeAmount,
                    onTap: () {
                      _controller.selectIncomeSide(true);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Donut chart ───────────────────────────────────────────────────
        if (!loading && slices.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    size: 56,
                    color: cs.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.noDataForPeriod,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (!loading) ...[
          SliverToBoxAdapter(
            child: Center(
              child: SizedBox(
                // Extra space around the donut so badges don't get clipped.
                width: 300,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 72,
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                final idx =
                                    pieTouchResponse
                                        ?.touchedSection
                                        ?.touchedSectionIndex ??
                                    -1;
                                if (event is FlLongPressEnd ||
                                    event is FlPanEndEvent ||
                                    event is FlTapUpEvent) {
                                  setState(() => _touchedIndex = -1);
                                } else {
                                  setState(() => _touchedIndex = idx);
                                }
                              },
                        ),
                        sections: _buildSections(slices, sumSlice),
                      ),
                      duration: const Duration(milliseconds: 400),
                    ),
                    // Center label
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _touchedIndex >= 0 && _touchedIndex < slices.length
                          ? _DonutCenter(
                              key: ValueKey(_touchedIndex),
                              cat: slices[_touchedIndex].category,
                              pct: sumSlice > 0
                                  ? 100 *
                                        slices[_touchedIndex].amount /
                                        sumSlice
                                  : 0,
                              amount: slices[_touchedIndex].amount,
                              isIncome: incomeSide,
                            )
                          : _DonutCenterIdle(
                              key: const ValueKey("idle"),
                              label: incomeSide
                                  ? context.l10n.income
                                  : context.l10n.expense,
                              total: sumSlice,
                              count: slices.length,
                              isIncome: incomeSide,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Category list header ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                "${context.l10n.reportByCategory} · ${incomeSide ? context.l10n.income : context.l10n.expense}",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // ── Category rows ────────────────────────────────────────────────
          for (var i = 0; i < slices.length; i++)
            SliverToBoxAdapter(
              child: _CategoryRow(
                slice: slices[i],
                sumSlice: sumSlice,
                isIncome: incomeSide,
                highlighted: _touchedIndex == i,
                onTap: () => _openCategoryDrillDown(
                  slices[i].id,
                  slices[i].category.name,
                ),
              ),
            ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(
    List<ReportCategorySlice> slices,
    int sumSlice,
  ) {
    double cumPct = 0;
    return List.generate(slices.length, (i) {
      final pct = sumSlice > 0 ? 100.0 * slices[i].amount / sumSlice : 0.0;
      cumPct += pct;
      final isTouched = _touchedIndex == i;
      // Hide badge for very small segments unless touched.
      final showBadge = pct >= 5 || isTouched;
      return PieChartSectionData(
        color: slices[i].category.color,
        value: slices[i].amount.toDouble(),
        title: "",
        radius: isTouched ? 46 : 38,
        badgeWidget: showBadge
            ? _PieBadge(
                cat: slices[i].category,
                pct: pct,
                isTouched: isTouched,
                labelAbove: cumPct - pct / 2 < 50,
              )
            : null,
        badgePositionPercentageOffset: 1.15,
      );
    });
  }

  Future<void> _openCategoryDrillDown(String categoryId, String name) async {
    final list = await ref
        .read(ledgerRepositoryProvider)
        .transactionsForCategory(
          categoryId: categoryId,
          period: _period,
          custom: _custom,
        );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: AppEmptyState(
                            message: context.l10n.noTransactions,
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final t = list[i];
                            return ListTile(
                              title: Text(t.title),
                              subtitle: Text(
                                formatTransactionDate(t.occurredAt),
                              ),
                              trailing: MoneyText(
                                t.amountVnd,
                                isIncome: t.isIncome,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

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
          borderRadius: BorderRadius.circular(12),
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

class _DonutCenterIdle extends StatelessWidget {
  const _DonutCenterIdle({
    super.key,
    required this.label,
    required this.total,
    required this.count,
    required this.isIncome,
  });

  final String label;
  final int total;
  final int count;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        MoneyText(
          total,
          isIncome: isIncome,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          "$count ${context.l10n.categoryNoun}",
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _DonutCenter extends StatelessWidget {
  const _DonutCenter({
    super.key,
    required this.cat,
    required this.pct,
    required this.amount,
    required this.isIncome,
  });

  final CategoryModel cat;
  final double pct;
  final int amount;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: cat.color.withValues(alpha: 0.15),
          child: Icon(cat.icon, size: 14, color: cat.color),
        ),
        const SizedBox(height: 4),
        Text(
          "${pct.toStringAsFixed(0)}%",
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        FittedBox(
          child: MoneyText(
            amount,
            isIncome: isIncome,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.slice,
    required this.sumSlice,
    required this.isIncome,
    required this.highlighted,
    required this.onTap,
  });

  final ReportCategorySlice slice;
  final int sumSlice;
  final bool isIncome;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = sumSlice > 0 ? slice.amount / sumSlice : 0.0;
    final cat = slice.category;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: highlighted
            ? cat.color.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: highlighted
                    ? Border.all(color: cat.color, width: 2)
                    : null,
              ),
              child: Icon(cat.icon, color: cat.color, size: 22),
            ),
            const SizedBox(width: 12),
            // Name + progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct.toDouble(),
                            minHeight: 5,
                            backgroundColor: cat.color.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cat.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${(pct * 100).toStringAsFixed(1)}%",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount
            MoneyText(
              slice.amount,
              isIncome: isIncome,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pie badge (icon circle + percentage label)
// ─────────────────────────────────────────────────────────────────────────────

class _PieBadge extends StatelessWidget {
  const _PieBadge({
    required this.cat,
    required this.pct,
    required this.isTouched,
    required this.labelAbove,
  });

  final CategoryModel cat;
  final double pct;
  final bool isTouched;

  /// Whether the percentage label floats above the icon (vs. below).
  final bool labelAbove;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    final color = cat.color;
    final label = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "${pct.toStringAsFixed(0)}%",
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );

    return AnimatedScale(
      scale: isTouched ? 1.25 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (labelAbove) ...[label, const SizedBox(height: 2)],
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(color: color, width: 2.5),
            ),
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(cat.icon, color: color, size: 16),
              ),
            ),
          ),
          if (!labelAbove) ...[const SizedBox(height: 2), label],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────
