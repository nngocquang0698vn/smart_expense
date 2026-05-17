import "package:flutter/material.dart";

import "../core/constants.dart";
import "../core/strings.dart";
import "../data/date_filter.dart";
import "../data/ledger_repository.dart";
import "../data/models/category_model.dart";
import "../data/models/transaction_model.dart";
import "../utils/tx_grouping.dart";
import "../shared/widgets/app_confirm_bottom_sheet.dart";
import "../widgets/date_filter_sheet.dart";
import "../widgets/empty_state.dart";
import "../widgets/money.dart";
import "../widgets/page_header_sliver.dart";
import "../widgets/summary_card.dart";
import "../widgets/transaction_editor_sheet.dart";
import "../widgets/tx_row.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repo,
    required this.onOpenPendingTab,
  });

  final LedgerRepository repo;
  final VoidCallback onOpenPendingTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateFilterSelection _filter = const DateFilterSelection(
    preset: DateFilterPreset.thisMonth,
  );

  final _scroll = ScrollController();
  final List<TransactionModel> _historyLoaded = [];
  int _historyOffset = 0;
  bool _loadingMore = false;
  bool _allLoaded = false;

  Map<String, int>? _summary;
  List<TransactionModel>? _pendingAll;
  List<CategoryModel>? _categories;
  bool _topLoading = true;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    widget.repo.addListener(_onRepo);
    _scroll.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    widget.repo.removeListener(_onRepo);
    _scroll.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _bootstrap() =>
      Future.wait([_refreshTop(), _reloadHistory(reset: true)]);

  void _onRepo() {
    _refreshTop();
    _reloadHistory(reset: true);
  }

  Future<void> _refreshTop() async {
    setState(() => _topLoading = true);
    final results = await Future.wait([
      widget.repo.homeSummary(_filter),
      widget.repo.pendingAll(_filter),
      widget.repo.categories(),
    ]);
    if (!mounted) return;
    setState(() {
      _summary = results[0] as Map<String, int>;
      _pendingAll = results[1] as List<TransactionModel>;
      _categories = results[2] as List<CategoryModel>;
      _topLoading = false;
    });
  }

  Future<void> _reloadHistory({required bool reset}) async {
    if (reset) {
      setState(() {
        _historyOffset = 0;
        _historyLoaded.clear();
        _allLoaded = false;
      });
    }
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _allLoaded) return;
    setState(() => _loadingMore = true);
    final batch = await widget.repo.historyPage(
      filter: _filter,
      offset: _historyOffset,
      limit: AppPageSizes.historyPage,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (batch.isEmpty) {
        _allLoaded = true;
      } else {
        _historyLoaded.addAll(batch);
        _historyOffset += batch.length;
        if (batch.length < AppPageSizes.historyPage) _allLoaded = true;
      }
    });
  }

  void _onScroll() {
    if (_allLoaded || _loadingMore) return;
    if (_scroll.position.pixels >
        _scroll.position.maxScrollExtent - AppPageSizes.scrollLoadThreshold) {
      _loadMore();
    }
  }

  Future<void> _pickFilter() async {
    final next = await showDateFilterSheet(context, _filter);
    if (next != null && mounted) {
      setState(() => _filter = next);
      await _refreshTop();
      await _reloadHistory(reset: true);
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

  void _openEditor(TransactionModel t) =>
      showTransactionEditor(context, widget.repo, existing: t);

  Future<void> _confirmPending(TransactionModel t) async {
    final ok = await AppConfirmBottomSheet.show(
      context,
      title: AppStrings.confirmPendingTitle,
      message: AppStrings.confirmPendingMessage,
    );
    if (!ok || !mounted) return;
    await widget.repo.confirmPending(t.id);
  }

  Widget _pendingTrailing(TransactionModel t) => buildPendingActions(
    transaction: t,
    onConfirm: () => _confirmPending(t),
    onEdit: () => _openEditor(t),
  );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_topLoading && _summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = _summary ?? const {"income": 0, "expense": 0};
    final pendingAll = _pendingAll ?? const [];
    final cats = _categories ?? const [];
    final catMap = {for (final c in cats) c.id: c};
    final income = summary["income"] ?? 0;
    final expense = summary["expense"] ?? 0;
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

    return isDesktop
        ? _buildDesktop(
            context,
            income: income,
            expense: expense,
            pendingAll: pendingAll,
            catMap: catMap,
          )
        : _buildMobile(
            context,
            income: income,
            expense: expense,
            pendingAll: pendingAll,
            catMap: catMap,
          );
  }

  // ── Desktop layout ────────────────────────────────────────────────────────

  Widget _buildDesktop(
    BuildContext context, {
    required int income,
    required int expense,
    required List<TransactionModel> pendingAll,
    required Map<String, CategoryModel> catMap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DesktopHeader(
          filter: _filter,
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
                  onRefresh: _refreshTop,
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
                              AppStrings.pending,
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
                                child: const Text(AppStrings.seeAll),
                              ),
                          ],
                        ),
                      ),
                      if (pendingAll.isEmpty)
                        EmptyState(message: AppStrings.noPendingShort)
                      else ...[
                        _PendingSubheader(items: pendingAll),
                        ...pendingAll.map(
                          (t) => TxRow(
                            transaction: t,
                            category: catMap[t.categoryId],
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
                            AppStrings.historyTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_historyLoaded.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            HistoryCountBadge(
                              label: _fmtCount(
                                _historyLoaded.length,
                                hasMore: !_allLoaded,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ..._historyWidgets(catMap),
                    if (_loadingMore)
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
    required int income,
    required int expense,
    required List<TransactionModel> pendingAll,
    required Map<String, CategoryModel> catMap,
  }) {
    final pendingPreview = pendingAll.take(3).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await _refreshTop();
        await _reloadHistory(reset: true);
      },
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          PageHeaderSliver(
            title: "Trang chủ",
            actions: [
              TextButton.icon(
                onPressed: _pickFilter,
                icon: const Icon(Icons.filter_alt_outlined),
                label: Text(_filter.label()),
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
                      label: AppStrings.income,
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
                      label: AppStrings.expense,
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
                      AppStrings.pending,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    PendingCountBadge(count: pendingAll.length),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onOpenPendingTab,
                      child: const Text(AppStrings.seeAll),
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
                    AppStrings.historyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_historyLoaded.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    HistoryCountBadge(
                      label: _fmtCount(
                        _historyLoaded.length,
                        hasMore: !_allLoaded,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ..._historySlivers(catMap),
          if (_loadingMore)
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

  Iterable<Widget> _historyWidgets(Map<String, CategoryModel> catMap) {
    final buckets = groupByDay(_historyLoaded);
    if (buckets.isEmpty && !_loadingMore) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppInsets.screenH),
          child: Text(AppStrings.noDataForFilter),
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

  Iterable<Widget> _historySlivers(Map<String, CategoryModel> catMap) {
    final buckets = groupByDay(_historyLoaded);
    if (buckets.isEmpty && !_loadingMore) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppInsets.screenH),
            child: Text(AppStrings.noDataForFilter),
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
    required this.income,
    required this.expense,
    required this.onFilterTap,
  });

  final DateFilterSelection filter;
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
                "Trang chủ",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onFilterTap,
                icon: const Icon(Icons.filter_alt_outlined),
                label: Text(filter.label()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: AppStrings.income,
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
                  label: AppStrings.expense,
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

/// Compact summary line above the pending list: "Thu X · Chi Y · N giao dịch chờ".
class _PendingSubheader extends StatelessWidget {
  const _PendingSubheader({required this.items});

  final List<TransactionModel> items;

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
        "Thu ${formatMoneyVi(inc)} · Chi ${formatMoneyVi(exp)} · "
        "${items.length} giao dịch chờ",
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
