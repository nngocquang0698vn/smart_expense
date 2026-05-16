import "dart:convert";

import "package:audioplayers/audioplayers.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";

import "../core/strings.dart";
import "../data/ledger_repository.dart";
import "../data/models/category_model.dart";
import "../data/models/transaction_model.dart";

Future<void> showTransactionEditor(
  BuildContext context,
  LedgerRepository repo, {
  TransactionModel? existing,
  bool defaultPending = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: false,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _EditorBody(
        repo: repo,
        existing: existing,
        defaultPending: defaultPending,
      ),
    ),
  );
}

class _EditorBody extends StatefulWidget {
  const _EditorBody({
    required this.repo,
    this.existing,
    required this.defaultPending,
  });

  final LedgerRepository repo;
  final TransactionModel? existing;
  final bool defaultPending;

  @override
  State<_EditorBody> createState() => _EditorBodyState();
}

class _EditorBodyState extends State<_EditorBody> {
  final _audioPlayer = AudioPlayer();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late bool _income;
  String? _categoryId;
  late DateTime _date;
  late bool _pending;

  // Snapshots for dirty detection
  late String _initTitle;
  late String _initAmount;
  late String _initNote;
  late bool _initIncome;
  late String? _initCategoryId;
  late DateTime _initDate;
  late bool _initPending;

  bool get _isDirty =>
      _titleCtrl.text != _initTitle ||
      _amountCtrl.text != _initAmount ||
      _noteCtrl.text != _initNote ||
      _income != _initIncome ||
      _categoryId != _initCategoryId ||
      _date != _initDate ||
      _pending != _initPending;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amountVnd.toString();
      _noteCtrl.text = e.note ?? "";
      _income = e.isIncome;
      _categoryId = e.categoryId;
      _date = e.occurredAt;
      _pending = e.pending;
    } else {
      _income = false;
      _date = DateTime.now();
      _pending = widget.defaultPending;
    }
    // Snapshot initial values for dirty check
    _initTitle = _titleCtrl.text;
    _initAmount = _amountCtrl.text;
    _initNote = _noteCtrl.text;
    _initIncome = _income;
    _initCategoryId = _categoryId;
    _initDate = _date;
    _initPending = _pending;

    // Rebuild on text changes so dirty flag updates
    _titleCtrl.addListener(() => setState(() {}));
    _amountCtrl.addListener(() => setState(() {}));
    _noteCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String base64Audio) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(BytesSource(base64Decode(base64Audio)));
  }

  Future<void> _handleClose() async {
    if (!_isDirty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Huỷ thay đổi?"),
        content: const Text(
          "Mọi thay đổi chưa lưu sẽ bị mất. Bạn có chắc chắn muốn đóng không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Tiếp tục chỉnh sửa"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Huỷ thay đổi"),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  Future<void> _validateAndRun({
    required List<CategoryModel> cats,
    required bool confirm,
  }) async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên giao dịch.")),
      );
      return;
    }

    final raw = _amountCtrl.text.replaceAll(RegExp(r"[^\d]"), "");
    final amount = int.tryParse(raw) ?? 0;

    // When confirming (not pending anymore), require a real amount
    final effectivePending = confirm ? false : _pending;
    if (!effectivePending && amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập số tiền hợp lệ.")),
      );
      return;
    }

    final catId = _categoryId ??
        cats.firstWhere((c) => c.isIncome == _income, orElse: () => cats.first).id;

    final e = widget.existing;
    if (e == null) {
      await widget.repo.addQuick(
        title: title,
        amountVnd: amount,
        isIncome: _income,
        categoryId: catId,
        at: _date,
        pending: effectivePending,
        complete: !effectivePending,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
    } else {
      await widget.repo.putTransaction(
        e.copyWith(
          title: title,
          amountVnd: amount,
          isIncome: _income,
          categoryId: catId,
          occurredAt: _date,
          pending: effectivePending,
          complete: !effectivePending,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(confirm ? "Đã xác nhận và lưu giao dịch." : "Đã lưu giao dịch."),
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xoá giao dịch?"),
        content: const Text("Hành động này không thể hoàn tác."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xoá"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.repo.deleteTransaction(widget.existing!.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
      future: widget.repo
          .categories()
          .then((list) => list.where((c) => c.enabled).toList()),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final cats = snap.data!;
        _categoryId ??= cats
            .firstWhere((c) => c.isIncome == _income, orElse: () => cats.first)
            .id;

        final hasAudio =
            (widget.existing?.audioBase64 ?? "").isNotEmpty;
        final hasImages =
            widget.existing?.imageBase64List.isNotEmpty ?? false;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row with close button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.existing == null
                            ? AppStrings.addTransaction
                            : AppStrings.editTransaction,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: _handleClose,
                      icon: const Icon(Icons.close),
                      tooltip: AppStrings.close,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                TextField(
                  controller: _titleCtrl,
                  decoration:
                      const InputDecoration(labelText: AppStrings.transactionTitle),
                ),
                const SizedBox(height: 12),

                // Amount
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: AppStrings.amount,
                    hintText: "0",
                  ),
                ),
                const SizedBox(height: 12),

                // Income / Expense toggle
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text(AppStrings.expense)),
                    ButtonSegment(value: true, label: Text(AppStrings.income)),
                  ],
                  selected: {_income},
                  onSelectionChanged: (s) {
                    setState(() {
                      _income = s.first;
                      _categoryId = cats
                          .firstWhere((c) => c.isIncome == _income,
                              orElse: () => cats.first)
                          .id;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Category dropdown
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _categoryId,
                  items: cats
                      .where((c) => c.isIncome == _income)
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(c.icon, color: c.color, size: 20),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                  decoration: const InputDecoration(labelText: AppStrings.category),
                ),
                const SizedBox(height: 12),

                // Date picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.transactionDate),
                  subtitle: Text(DateFormat.yMMMd("vi").format(_date)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate:
                          DateTime(DateTime.now().year + 1, 12, 31),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                ),

                // Pending toggle — free to toggle for all transaction types
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.pending),
                  subtitle: const Text(
                      "Bật nếu cần xem lại giao dịch này sau."),
                  value: _pending,
                  onChanged: (v) => setState(() => _pending = v),
                ),

                // Note
                const SizedBox(height: 4),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: AppStrings.note),
                ),

                // Audio playback
                if (hasAudio) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: ListTile(
                      leading: Icon(Icons.audiotrack,
                          color: Theme.of(context).colorScheme.primary),
                      title: const Text("Audio đính kèm"),
                      subtitle: const Text("Nhấn ▶ để nghe lại ghi âm"),
                      trailing: IconButton(
                        onPressed: () =>
                            _playAudio(widget.existing!.audioBase64!),
                        icon: Icon(Icons.play_arrow,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                ],

                // Image thumbnails
                if (hasImages) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          widget.existing!.imageBase64List.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final bytes = base64Decode(
                            widget.existing!.imageBase64List[i]);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            bytes,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Action buttons ───────────────────────────────────────
                // 1. Save & Confirm (sets pending = false)
                FilledButton.icon(
                  onPressed: () =>
                      _validateAndRun(cats: cats, confirm: true),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(AppStrings.saveAndConfirm),
                ),
                const SizedBox(height: 8),

                // 2. Save draft (keeps pending as-is)
                OutlinedButton.icon(
                  onPressed: () =>
                      _validateAndRun(cats: cats, confirm: false),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text(AppStrings.save),
                ),

                // 3. Delete (only for existing transactions)
                if (widget.existing != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text(AppStrings.deleteTransaction),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
