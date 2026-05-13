import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../data/date_filter.dart";
import "../data/ledger_repository.dart";
import "../data/models/category_model.dart";
import "../data/models/transaction_model.dart";
import "../widgets/date_filter_sheet.dart";
import "../widgets/money.dart";
import "../widgets/transaction_editor_sheet.dart";

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key, required this.repo});

  final LedgerRepository repo;

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  DateFilterSelection _filter = const DateFilterSelection(
    preset: DateFilterPreset.thisMonth,
  );
  List<TransactionModel> _pending = [];
  List<CategoryModel> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.repo.addListener(_onRepo);
    _load();
  }

  @override
  void dispose() {
    widget.repo.removeListener(_onRepo);
    super.dispose();
  }

  void _onRepo() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await widget.repo.pendingAll(_filter);
    final c = await widget.repo.categories();
    if (!mounted) return;
    setState(() {
      _pending = p;
      _categories = c;
      _loading = false;
    });
  }

  Future<void> _pickFilter() async {
    final next = await showDateFilterSheet(context, _filter);
    if (next != null) {
      setState(() => _filter = next);
      await _load();
    }
  }

  List<_DayBucket> _bucket(List<TransactionModel> list) {
    final map = <DateTime, List<TransactionModel>>{};
    for (final t in list) {
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
    if (_loading) {
      return const CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text("Đối soát")),
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    final catMap = {for (final c in _categories) c.id: c};
    final buckets = _bucket(_pending);
    final children = <Widget>[
      SliverAppBar.large(
        title: const Text("Đối soát"),
        actions: [
          TextButton.icon(
            onPressed: _pickFilter,
            icon: const Icon(Icons.filter_alt_outlined),
            label: Text(_filter.label(context)),
          ),
        ],
      ),
    ];

    if (_pending.isEmpty) {
      children.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text("Không có giao dịch chờ.")),
        ),
      );
    } else {
      for (final b in buckets) {
        children.add(
          SliverToBoxAdapter(
            child: _DayBlockHeader(day: b.day, items: b.items),
          ),
        );
        for (final t in b.items) {
          children.add(
            SliverToBoxAdapter(
              child: _PendingRow(
                t: t,
                cat: catMap[t.categoryId],
                onConfirm: () => widget.repo.confirmPending(t.id),
                onEdit: () => showTransactionEditor(
                  context,
                  widget.repo,
                  existing: t,
                ),
              ),
            ),
          );
        }
      }
    }
    children.add(const SliverToBoxAdapter(child: SizedBox(height: 96)));

    return CustomScrollView(slivers: children);
  }
}

class _DayBucket {
  _DayBucket({required this.day, required this.items});

  final DateTime day;
  final List<TransactionModel> items;
}

class _DayBlockHeader extends StatelessWidget {
  const _DayBlockHeader({required this.day, required this.items});

  final DateTime day;
  final List<TransactionModel> items;

  @override
  Widget build(BuildContext context) {
    final sum = items.fold<int>(0, (s, t) => s + t.amountVnd);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.yMMMEd("vi").format(day),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            "${formatMoneyVi(sum)} · ${items.length} giao dịch",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.t,
    required this.cat,
    required this.onConfirm,
    required this.onEdit,
  });

  final TransactionModel t;
  final CategoryModel? cat;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final icon = cat?.icon ?? Icons.category;
    final color = cat?.color ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onEdit,
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
                    Text(
                      DateFormat.MMMd("vi").format(t.occurredAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      children: [
                        if ((t.audioBase64 ?? "").isNotEmpty)
                          const Icon(Icons.audiotrack, size: 16),
                        if (t.imageBase64List.isNotEmpty)
                          const Icon(Icons.image_outlined, size: 16),
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
                  const SizedBox(height: 6),
                  // Show both buttons when info is complete (amount>0 + category set).
                  if (t.amountVnd > 0 && t.categoryId.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: onConfirm,
                          child: const Text("Xác nhận"),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: onEdit,
                          child: const Text("Cập nhật"),
                        ),
                      ],
                    )
                  else
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: onEdit,
                      child: const Text("Cập nhật"),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
