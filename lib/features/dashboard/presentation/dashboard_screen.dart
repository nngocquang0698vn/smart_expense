import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/core/utils/formatters/money.dart";
import "package:smart_expense/shared/components/page_header_sliver.dart";
import "package:smart_expense/shared/components/summary_card.dart";
import "package:smart_expense/shared/components/tx_row.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/application/confirm_pending_flow.dart";
import "package:smart_expense/shared/components/app_empty_state.dart";
import "package:smart_expense/features/transactions/presentation/date_filter_sheet.dart";
import "package:smart_expense/features/transactions/presentation/transaction_editor_sheet.dart";
import "package:smart_expense/features/dashboard/application/dashboard_controller.dart";
import "package:smart_expense/features/dashboard/application/dashboard_view_model.dart";
import "package:smart_expense/features/dashboard/utils/tx_grouping.dart";

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, required this.onOpenPendingTab});

  final VoidCallback onOpenPendingTab;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _scroll = ScrollController();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  void _onScroll() {
    final viewModel = _viewModel;
    if (viewModel.allLoaded || viewModel.loadingMore) return;
    if (_scroll.position.pixels >
        _scroll.position.maxScrollExtent - AppPageSizes.scrollLoadThreshold) {
      ref.read(dashboardControllerProvider.notifier).loadMore();
    }
  }

  DashboardViewModel get _viewModel =>
      ref.read(dashboardControllerProvider).value?.viewModel ??
      const DashboardViewModel.initial();

  DateFilterSelection get _filter =>
      ref.read(dashboardControllerProvider).value?.filter ??
      const DateFilterSelection(preset: DateFilterPreset.thisMonth);

  Future<void> _pickFilter() async {
    final next = await showDateFilterSheet(context, _filter);
    if (next != null && mounted) {
      await ref.read(dashboardControllerProvider.notifier).updateFilter(next);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Formats the loaded history count; appends "+" when more pages exist.
  String _fmtCount(int n, {required bool hasMore}) {
    if (!hasMore) return "$n";
    for (final cap in [1000, 100, 50]) {
      if (n >= cap) return "$cap+";
    }
    return "$n+";
  }

  void _openEditor(LedgerTransaction t) => showTransactionEditor(
    context,
    ref.read(ledgerRepositoryProvider),
    existing: t,
  );

  Future<void> _confirmPending(LedgerTransaction t) => runConfirmPendingFlow(
    context: context,
    ref: ref,
    transactionId: t.id,
  );

  Widget? _pendingTrailing(LedgerTransaction t) => buildPendingConfirmButton(
    context: context,
    transaction: t,
    onConfirm: () => _confirmPending(t),
  );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardControllerProvider);
    return dashboard.when(
      data: (state) {
        final viewModel = state.viewModel;
        if (viewModel.initialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final isDesktop =
            MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
        final l10n = context.l10n;
        return isDesktop
            ? _buildDesktop(
                context,
                l10n: l10n,
                income: viewModel.summary.income,
                expense: viewModel.summary.expense,
                pendingAll: viewModel.pending,
                catMap: viewModel.categoryMap,
                filter: state.filter,
              )
            : _buildMobile(
                context,
                l10n: l10n,
                income: viewModel.summary.income,
                expense: viewModel.summary.expense,
                pendingAll: viewModel.pending,
                catMap: viewModel.categoryMap,
                filter: state.filter,
              );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(context.l10n.genericError)),
    );
  }

  // ── Desktop layout ────────────────────────────────────────────────────────

  Widget _buildDesktop(
    BuildContext context, {
    required AppLocalizations l10n,
    required int income,
    required int expense,
    required List<LedgerTransaction> pendingAll,
    required Map<String, LedgerCategory> catMap,
    required DateFilterSelection filter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DesktopHeader(
          filter: filter,
          l10n: l10n,
          income: income,
          expense: expense,
          onFilterTap: _pickFilter,
        ),
        const Divider(height: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column — pending (4 parts)
              Expanded(
                flex: 4,
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(dashboardControllerProvider.notifier).refresh(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      8,
                      0,
                      AppInsets.listBottom,
                    ),
                    children: [
                      _SectionHeader(
                        child: Row(
                          children: [
                            Text(
                              l10n.pending,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (pendingAll.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              PendingCountBadge(count: pendingAll.length),
                            ],
                            const Spacer(),
                            if (pendingAll.isNotEmpty)
                              TextButton(
                                onPressed: widget.onOpenPendingTab,
                                child: Text(l10n.seeAll),
                              ),
                          ],
                        ),
                      ),
                      if (pendingAll.isEmpty)
                        AppEmptyState(message: context.l10n.noPendingShort)
                      else ...[
                        _PendingSubheader(items: pendingAll),
                        ...pendingAll.map(
                          (t) => TxRow(
                            transaction: t,
                            category: catMap[t.categoryId],
                            showInlineAudioPlayer: true,
                            trailing: _pendingTrailing(t),
                            onTap: () => _openEditor(t),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              // Right column — history (6 parts)
              Expanded(
                flex: 6,
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    8,
                    0,
                    AppInsets.listBottom,
                  ),
                  children: [
                    _SectionHeader(
                      child: Row(
                        children: [
                          Text(
                            l10n.historyTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_viewModel.history.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            HistoryCountBadge(
                              label: _fmtCount(
                                _viewModel.history.length,
                                hasMore: !_viewModel.allLoaded,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ..._historyWidgets(catMap),
                    if (_viewModel.loadingMore)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile layout ─────────────────────────────────────────────────────────

  Widget _buildMobile(
    BuildContext context, {
    required AppLocalizations l10n,
    required int income,
    required int expense,
    required List<LedgerTransaction> pendingAll,
    required Map<String, LedgerCategory> catMap,
    required DateFilterSelection filter,
  }) {
    final pendingPreview = pendingAll.take(3).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dashboardControllerProvider.notifier).refresh();
      },
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          PageHeaderSliver(
            title: l10n.homeTitle,
            actions: [
              TextButton.icon(
                onPressed: _pickFilter,
                icon: const Icon(Icons.filter_alt_outlined),
                label: Text(localizedDateFilterLabel(context.l10n, filter)),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppInsets.screenH),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: context.l10n.income,
                      child: MoneyText(
                        income,
                        isIncome: true,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      label: context.l10n.expense,
                      child: MoneyText(
                        expense,
                        isIncome: false,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (pendingAll.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                child: Row(
                  children: [
                    Text(
                      l10n.pending,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    PendingCountBadge(count: pendingAll.length),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onOpenPendingTab,
                      child: Text(l10n.seeAll),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _PendingSubheader(items: pendingAll)),
            ...pendingPreview.map(
              (t) => SliverToBoxAdapter(
                child: TxRow(
                  transaction: t,
                  category: catMap[t.categoryId],
                  showInlineAudioPlayer: true,
                  trailing: _pendingTrailing(t),
                  onTap: () => _openEditor(t),
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: _SectionHeader(
              child: Row(
                children: [
                  Text(
                    l10n.historyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_viewModel.history.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    HistoryCountBadge(
                      label: _fmtCount(
                        _viewModel.history.length,
                        hasMore: !_viewModel.allLoaded,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ..._historySlivers(catMap),
          if (_viewModel.loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppInsets.listBottom),
          ),
        ],
      ),
    );
  }

  // ── History renderers ─────────────────────────────────────────────────────

  Iterable<Widget> _historyWidgets(Map<String, LedgerCategory> catMap) {
    final viewModel = _viewModel;
    final buckets = groupByDay(viewModel.history);
    if (buckets.isEmpty && !viewModel.loadingMore) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppInsets.screenH),
          child: Text(context.l10n.noDataForFilter),
        ),
      ];
    }
    return [
      for (final b in buckets) ...[
        TxDayHeader(
          day: b.day,
          totalVnd: b.items.fold(0, (s, t) => s + t.amountVnd),
          count: b.items.length,
        ),
        ...b.items.map(
          (t) => TxRow(
            transaction: t,
            category: catMap[t.categoryId],
            onTap: () => _openEditor(t),
          ),
        ),
      ],
    ];
  }

  Iterable<Widget> _historySlivers(Map<String, LedgerCategory> catMap) {
    final viewModel = _viewModel;
    final buckets = groupByDay(viewModel.history);
    if (buckets.isEmpty && !viewModel.loadingMore) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppInsets.screenH),
            child: Text(context.l10n.noDataForFilter),
          ),
        ),
      ];
    }
    return [
      for (final b in buckets) ...[
        SliverToBoxAdapter(
          child: TxDayHeader(
            day: b.day,
            totalVnd: b.items.fold(0, (s, t) => s + t.amountVnd),
            count: b.items.length,
          ),
        ),
        ...b.items.map(
          (t) => SliverToBoxAdapter(
            child: TxRow(
              transaction: t,
              category: catMap[t.categoryId],
              onTap: () => _openEditor(t),
            ),
          ),
        ),
      ],
    ];
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

/// Fixed top bar for the desktop layout: title, filter button, summary cards.
class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.filter,
    required this.l10n,
    required this.income,
    required this.expense,
    required this.onFilterTap,
  });

  final DateFilterSelection filter;
  final AppLocalizations l10n;
  final int income;
  final int expense;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.homeTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onFilterTap,
                icon: const Icon(Icons.filter_alt_outlined),
                label: Text(localizedDateFilterLabel(context.l10n, filter)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: context.l10n.income,
                  child: MoneyText(
                    income,
                    isIncome: true,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: context.l10n.expense,
                  child: MoneyText(
                    expense,
                    isIncome: false,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact summary line above the pending list.
class _PendingSubheader extends StatelessWidget {
  const _PendingSubheader({required this.items});

  final List<LedgerTransaction> items;

  @override
  Widget build(BuildContext context) {
    var inc = 0;
    var exp = 0;
    for (final t in items) {
      if (t.isIncome) {
        inc += t.amountVnd;
      } else {
        exp += t.amountVnd;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Text(
        "${context.l10n.income} ${formatMoneyVi(inc)} · "
        "${context.l10n.expense} ${formatMoneyVi(exp)} · "
        "${items.length} ${context.l10n.transactionNoun} ${context.l10n.pending.toLowerCase()}",
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// Padded row that gives section titles consistent horizontal alignment.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: AppInsets.sectionHeader, child: child);
  }
}
