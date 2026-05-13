import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../data/date_filter.dart";
import "../data/ledger_repository.dart";
import "../data/models/category_model.dart";
import "../data/models/transaction_model.dart";
import "../widgets/date_filter_sheet.dart";
import "../widgets/money.dart";
import "../widgets/transaction_editor_sheet.dart";

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
  bool _end = false;
  static const _pageSize = 20;

  Map<String, int>? _summary;
  List<TransactionModel>? _pendingAll;
  List<CategoryModel>? _categories;
  bool _topLoading = true;

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

  Future<void> _bootstrap() async {
    await Future.wait([_refreshTop(), _reloadHistory(reset: true)]);
  }

  void _onRepo() {
    _refreshTop();
    _reloadHistory(reset: true);
  }

  Future<void> _refreshTop() async {
    setState(() => _topLoading = true);
    final summary = await widget.repo.homeSummary(_filter);
    final pending = await widget.repo.pendingAll(_filter);
    final cats = await widget.repo.categories();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _pendingAll = pending;
      _categories = cats;
      _topLoading = false;
    });
  }

  void _onScroll() {
    if (_end || _loadingMore) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _reloadHistory({required bool reset}) async {
    if (reset) {
      setState(() {
        _historyOffset = 0;
        _historyLoaded.clear();
        _end = false;
      });
    }
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _end) return;
    setState(() => _loadingMore = true);
    final batch = await widget.repo.historyPage(
      filter: _filter,
      offset: _historyOffset,
      limit: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (batch.isEmpty) {
        _end = true;
      } else {
        _historyLoaded.addAll(batch);
        _historyOffset += batch.length;
        if (batch.length < _pageSize) _end = true;
      }
    });
  }

  Future<void> _pickFilter() async {
    final next = await showDateFilterSheet(context, _filter);
    if (next != null) {
      setState(() => _filter = next);
      await _refreshTop();
      await _reloadHistory(reset: true);
    }
  }

  List<_DayBucket> _bucketHistory() {
    final map = <DateTime, List<TransactionModel>>{};
    for (final t in _historyLoaded) {
      final d = DateTime(t.occurredAt.year, t.occurredAt.month, t.occurredAt.day);
      map.putIfAbsent(d, () => []).add(t);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return keys
        .map(
          (d) => _DayBucket(
            day: d,
            items: map[d]!..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_topLoading && _summary == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final summary = _summary ?? {"income": 0, "expense": 0};
    final pendingAll = _pendingAll ?? [];
    final pendingShow = pendingAll.take(3).toList();
    final cats = _categories ?? [];
    final catMap = {for (final c in cats) c.id: c};
    final income = summary["income"] ?? 0;
    final expense = summary["expense"] ?? 0;
    final desktop = MediaQuery.sizeOf(context).width >= 1000;

    if (desktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Fixed header: title + filter + summary cards ───────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      "Trang chủ",
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _pickFilter,
                      icon: const Icon(Icons.filter_alt_outlined),
                      label: Text(_filter.label(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: "Thu nhập",
                        child: MoneyText(
                          income,
                          isIncome: true,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: "Chi tiêu",
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
          ),
          const Divider(height: 1),
          // ── Two-column scrollable area ──────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Pending section (4 parts)
                Expanded(
                  flex: 4,
                  child: RefreshIndicator(
                    onRefresh: () async => _refreshTop(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      children: [
                        _SectionHeader(
                          child: Row(
                            children: [
                              Text(
                                "Chờ đối soát",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (pendingAll.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                _PendingBadge(count: pendingAll.length),
                              ],
                              const Spacer(),
                              if (pendingAll.isNotEmpty)
                                TextButton(
                                  onPressed: widget.onOpenPendingTab,
                                  child: const Text("Xem tất cả"),
                                ),
                            ],
                          ),
                        ),
                        if (pendingAll.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                "Không có giao dịch chờ",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline,
                                    ),
                              ),
                            ),
                          )
                        else ...[
                          _PendingSubheader(items: pendingAll),
                          ...pendingAll.map(
                            (t) => _TxRow(
                              t: t,
                              cat: catMap[t.categoryId],
                              trailing: _pendingActions(context, t),
                              onTap: () => showTransactionEditor(
                                context,
                                widget.repo,
                                existing: t,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                // Right: History section (6 parts)
                Expanded(
                  flex: 6,
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      _SectionHeader(
                        child: Row(
                          children: [
                            Text(
                              "Lịch sử giao dịch",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (_historyLoaded.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _HistoryCountBadge(
                                label: _fmtCount(
                                  _historyLoaded.length,
                                  hasMore: !_end,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ..._buildHistoryWidgets(catMap),
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

    return RefreshIndicator(
      onRefresh: () async {
        await _refreshTop();
        await _reloadHistory(reset: true);
      },
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text("Trang chủ"),
            actions: [
              TextButton.icon(
                onPressed: _pickFilter,
                icon: const Icon(Icons.filter_alt_outlined),
                label: Text(_filter.label(context)),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: "Thu nhập",
                      child: MoneyText(
                        income,
                        isIncome: true,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: "Chi tiêu",
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
                      "Chờ đối soát",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    _PendingBadge(count: pendingAll.length),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onOpenPendingTab,
                      child: const Text("Xem tất cả"),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _PendingSubheader(items: pendingAll)),
            ...pendingShow.map(
              (t) => SliverToBoxAdapter(
                child: _TxRow(
                  t: t,
                  cat: catMap[t.categoryId],
                  trailing: _pendingActions(context, t),
                  onTap: () => showTransactionEditor(
                    context,
                    widget.repo,
                    existing: t,
                  ),
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: _SectionHeader(
              child: Row(
                children: [
                  Text(
                    "Lịch sử giao dịch",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_historyLoaded.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _HistoryCountBadge(
                      label: _fmtCount(
                        _historyLoaded.length,
                        hasMore: !_end,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ..._buildHistorySlivers(catMap),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  List<Widget> _buildHistorySlivers(Map<String, CategoryModel> catMap) {
    final buckets = _bucketHistory();
    if (buckets.isEmpty && !_loadingMore) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Chưa có giao dịch trong khoảng lọc."),
          ),
        ),
      ];
    }
    final out = <Widget>[];
    for (final b in buckets) {
      final sum = b.items.fold<int>(0, (s, t) => s + t.amountVnd);
      out.add(
        SliverToBoxAdapter(
          child: _DayHeader(
            day: b.day,
            totalVnd: sum,
            count: b.items.length,
          ),
        ),
      );
      for (final t in b.items) {
        out.add(
          SliverToBoxAdapter(
            child: _TxRow(
              t: t,
              cat: catMap[t.categoryId],
              onTap: () => showTransactionEditor(
                context,
                widget.repo,
                existing: t,
              ),
            ),
          ),
        );
      }
    }
    return out;
  }

  List<Widget> _buildHistoryWidgets(Map<String, CategoryModel> catMap) {
    final buckets = _bucketHistory();
    if (buckets.isEmpty && !_loadingMore) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text("Chưa có giao dịch trong khoảng lọc."),
        ),
      ];
    }

    final out = <Widget>[];
    for (final b in buckets) {
      final sum = b.items.fold<int>(0, (s, t) => s + t.amountVnd);
      out.add(
        _DayHeader(
          day: b.day,
          totalVnd: sum,
          count: b.items.length,
        ),
      );
      out.addAll(
        b.items.map(
          (t) => _TxRow(
            t: t,
            cat: catMap[t.categoryId],
            onTap: () => showTransactionEditor(
              context,
              widget.repo,
              existing: t,
            ),
          ),
        ),
      );
    }
    return out;
  }

  Widget _pendingActions(BuildContext context, TransactionModel t) {
    final isComplete = t.amountVnd > 0 && t.categoryId.isNotEmpty;
    final editBtn = OutlinedButton(
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      onPressed: () =>
          showTransactionEditor(context, widget.repo, existing: t),
      child: const Text("Cập nhật"),
    );
    if (isComplete) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () => widget.repo.confirmPending(t.id),
            child: const Text("Xác nhận"),
          ),
          const SizedBox(width: 6),
          editBtn,
        ],
      );
    }
    return editBtn;
  }

  /// Format transaction count, e.g. 50+ / 100+ / 1000+
  String _fmtCount(int n, {bool hasMore = false}) {
    if (!hasMore) return '$n';
    for (final cap in [1000, 100, 50]) {
      if (n >= cap) return '$cap+';
    }
    return '$n+';
  }
}

class _DayBucket {
  _DayBucket({required this.day, required this.items});

  final DateTime day;
  final List<TransactionModel> items;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

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

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.totalVnd,
    required this.count,
  });

  final DateTime day;
  final int totalVnd;
  final int count;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat.yMMMEd("vi").format(day);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          Text(
            "${formatMoneyVi(totalVnd)} · $count giao dịch",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Shared header row used by both Pending and History sections so that
/// their titles always start at the same horizontal position.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: child,
    );
  }
}

/// Red pill badge used next to "Chờ đối soát" title — floats up as superscript.
class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Transform.translate(
      offset: const Offset(0, -2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onError,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
        ),
      ),
    );
  }
}

/// Green pill badge used next to "Lịch sử giao dịch".
class _HistoryCountBadge extends StatelessWidget {
  const _HistoryCountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({
    required this.t,
    required this.cat,
    this.trailing,
    this.onTap,
  });

  final TransactionModel t;
  final CategoryModel? cat;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // When category is disabled, display as "Khác" until re-enabled.
    final disabled = cat != null && !cat!.enabled;
    final icon = disabled ? Icons.category : (cat?.icon ?? Icons.category);
    final color = disabled ? Colors.grey : (cat?.color ?? Colors.grey);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Row(
                      children: [
                        if (disabled)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              "Khác",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          )
                        else if (cat != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              cat!.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: color.withValues(alpha: 0.8),
                                  ),
                            ),
                          ),
                        Text(
                          DateFormat.MMMd("vi").format(t.occurredAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    t.amountVnd,
                    isIncome: t.isIncome,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 6),
                    trailing!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
