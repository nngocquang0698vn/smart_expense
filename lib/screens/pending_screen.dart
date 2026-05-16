import "package:flutter/material.dart";

import "../core/constants.dart";
import "../core/strings.dart";
import "../data/date_filter.dart";
import "../data/ledger_repository.dart";
import "../data/models/category_model.dart";
import "../data/models/transaction_model.dart";
import "../utils/tx_grouping.dart";
import "../widgets/date_filter_sheet.dart";
import "../widgets/transaction_editor_sheet.dart";
import "../widgets/tx_row.dart";

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

  // ── Lifecycle ─────────────────────────────────────────────────────────────

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

  // ── Data loading ──────────────────────────────────────────────────────────

  void _onRepo() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      widget.repo.pendingAll(_filter),
      widget.repo.categories(),
    ]);
    if (!mounted) return;
    setState(() {
      _pending = results[0] as List<TransactionModel>;
      _categories = results[1] as List<CategoryModel>;
      _loading = false;
    });
  }

  Future<void> _pickFilter() async {
    final next = await showDateFilterSheet(context, _filter);
    if (next != null && mounted) {
      setState(() => _filter = next);
      await _load();
    }
  }

  void _openEditor(TransactionModel t) =>
      showTransactionEditor(context, widget.repo, existing: t);

  // ── Build ─────────────────────────────────────────────────────────────────

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
    final buckets = groupByDay(_pending);

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text("Đối soát"),
          actions: [
            TextButton.icon(
              onPressed: _pickFilter,
              icon: const Icon(Icons.filter_alt_outlined),
              label: Text(_filter.label()),
            ),
          ],
        ),
        if (_pending.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(AppStrings.noPending)),
          )
        else ...[
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
                  trailing: buildPendingActions(
                    transaction: t,
                    onConfirm: () => widget.repo.confirmPending(t.id),
                    onEdit: () => _openEditor(t),
                  ),
                  onTap: () => _openEditor(t),
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
  }
}
