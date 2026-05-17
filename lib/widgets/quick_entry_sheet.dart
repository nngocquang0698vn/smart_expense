import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:intl/intl.dart";

import "../core/amount_input.dart";
import "../core/constants.dart";
import "../core/strings.dart";
import "../data/ledger_repository.dart";
import "../data/models/category_model.dart";
import "../shared/widgets/app_voice_note_section.dart";
import "../theme/app_finance_colors.dart";
import "app_text_field.dart";
import "form_amount_field.dart";

enum QuickEntryMode { tap, voice, receipt }

Future<void> showQuickEntrySheet(
  BuildContext context,
  LedgerRepository repo, {
  QuickEntryMode mode = QuickEntryMode.tap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _QuickEntryBody(repo: repo, mode: mode),
    ),
  );
}

class _QuickEntryBody extends StatefulWidget {
  const _QuickEntryBody({required this.repo, required this.mode});

  final LedgerRepository repo;
  final QuickEntryMode mode;

  @override
  State<_QuickEntryBody> createState() => _QuickEntryBodyState();
}

class _QuickEntryBodyState extends State<_QuickEntryBody> {
  final _titleCtrl = TextEditingController();
  final _amount = AmountInputController();
  final _noteCtrl = TextEditingController();

  bool _income = false;
  bool _pending = false;
  DateTime _date = DateTime.now();
  String? _categoryId;

  // Snapshots for dirty detection
  late String _initTitle;
  late int _initAmount;

  String? _audioBase64;

  // Images
  final _imageBase64List = <String>[];
  final _picker = ImagePicker();

  bool get _hasMedia => _audioBase64 != null || _imageBase64List.isNotEmpty;

  // Camera available on native platforms only
  bool get _showCamera => !kIsWeb;

  bool get _isDirty =>
      _titleCtrl.text != _initTitle ||
      _amount.value != _initAmount ||
      _noteCtrl.text.isNotEmpty ||
      _audioBase64 != null ||
      _imageBase64List.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pending = widget.mode != QuickEntryMode.tap;

    if (widget.mode == QuickEntryMode.voice) {
      final ts = DateFormat("dd/MM HH:mm").format(DateTime.now());
      _titleCtrl.text = "Ghi âm giao dịch - $ts";
      _amount.setValue(0);
    } else if (widget.mode == QuickEntryMode.receipt) {
      final ts = DateFormat("dd/MM HH:mm").format(DateTime.now());
      _titleCtrl.text = "Ảnh hoá đơn - $ts";
      _amount.setValue(0);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _pickImage(
          _showCamera ? ImageSource.camera : ImageSource.gallery,
        );
      });
    }

    // Snapshot initial values so we can detect dirty state
    _initTitle = _titleCtrl.text;
    _initAmount = _amount.value;

    _titleCtrl.addListener(() => setState(() {}));
    _amount.addListener(() => setState(() {}));
    _noteCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amount.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Close with unsaved-changes guard ──────────────────────────────────────

  Future<void> _handleClose() async {
    if (!_isDirty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Huỷ nhập liệu?"),
        content: const Text(
          "Mọi thay đổi chưa lưu sẽ bị mất. Bạn có chắc chắn muốn đóng không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Tiếp tục nhập"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBase64List.add(base64Encode(bytes));
      _pending = true;
    });
  }

  // ── Save logic ────────────────────────────────────────────────────────────

  Future<void> _save(List<CategoryModel> cats) async {
    final title = _titleCtrl.text.trim().isEmpty
        ? (_income ? "Thu nhập nhanh" : "Chi tiêu nhanh")
        : _titleCtrl.text.trim();

    final amount = _amount.value;

    if (!_pending && amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập số tiền hợp lệ.")),
      );
      return;
    }

    final matched = cats.where((c) => c.isIncome == _income).toList();
    final catId = _categoryId ?? (matched.isNotEmpty ? matched.first.id : null);
    if (!_pending && catId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng chọn danh mục.")));
      return;
    }

    final isInfoComplete = amount > 0 && catId != null;
    final effectiveComplete = _pending ? isInfoComplete : true;

    await widget.repo.addQuick(
      title: title,
      amountVnd: amount,
      isIncome: _income,
      categoryId: catId ?? (matched.isNotEmpty ? matched.first.id : ""),
      at: _date,
      pending: _pending,
      complete: effectiveComplete,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      audioBase64: _audioBase64,
      imageBase64List: _imageBase64List,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _pending ? "Đã lưu vào danh sách chờ đối soát." : "Đã lưu giao dịch.",
        ),
      ),
    );
  }

  // ── Main build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
      future: widget.repo.categories().then(
        (list) => list.where((c) => c.enabled).toList(),
      ),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final cats = snap.data!;
        final incomeCats = cats.where((c) => c.isIncome == _income).toList();
        _categoryId ??= incomeCats.isNotEmpty ? incomeCats.first.id : null;

        final sheetTitle = switch (widget.mode) {
          QuickEntryMode.voice => "Ghi âm giao dịch",
          QuickEntryMode.receipt => "Ảnh hoá đơn",
          QuickEntryMode.tap => "Nhập nhanh",
        };

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header with close button ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sheetTitle,
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
                const SizedBox(height: 12),

                // ── Income / Expense toggle ────────────────────────────────
                Builder(
                  builder: (context) {
                    final finance = context.financeColors;
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppRadius.container,
                        ),
                        color: finance.fieldFill,
                        border: Border.all(color: finance.fieldBorder),
                      ),
                      child: SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text(AppStrings.expense),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(AppStrings.income),
                          ),
                        ],
                        selected: {_income},
                        onSelectionChanged: (v) => setState(() {
                          _income = v.first;
                          _categoryId = null;
                        }),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // ── Amount — large & prominent ─────────────────────────────
                FormAmountField(
                  controller: _amount,
                  alwaysShowKeypad: widget.mode == QuickEntryMode.tap,
                  autofocus: widget.mode == QuickEntryMode.tap,
                ),
                const SizedBox(height: 10),

                // ── Title ─────────────────────────────────────────────────
                AppTextField(
                  controller: _titleCtrl,
                  labelText: "Tiêu đề (tuỳ chọn)",
                ),
                const SizedBox(height: 14),

                // ── Audio section ─────────────────────────────────────────
                if (widget.mode == QuickEntryMode.voice ||
                    _audioBase64 != null) ...[
                  AppVoiceNoteSection(
                    audioBase64: _audioBase64,
                    autoStartRecording: widget.mode == QuickEntryMode.voice,
                    onChanged: (b64) => setState(() {
                      _audioBase64 = b64;
                      if (b64 != null) _pending = true;
                    }),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Category chips (compact, shows all categories) ────────
                Text("Danh mục", style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Builder(
                  builder: (ctx) {
                    final cs = Theme.of(ctx).colorScheme;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cats.where((c) => c.isIncome == _income).map((
                        cat,
                      ) {
                        final active = cat.id == _categoryId;
                        return GestureDetector(
                          onTap: () => setState(() => _categoryId = cat.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? cs.primary
                                  : context.financeColors.fieldFill,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? cs.primary
                                    : context.financeColors.fieldBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  size: 16,
                                  color: active ? cs.onPrimary : cat.color,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: active ? cs.onPrimary : cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // ── Date picker ───────────────────────────────────────────
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today_rounded),
                    title: Text(DateFormat("dd/MM/yyyy").format(_date)),
                    subtitle: const Text(AppStrings.transactionDate),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // ── Attachment row ────────────────────────────────────────
                Row(
                  children: [
                    if (_showCamera) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(
                            Icons.photo_camera_outlined,
                            size: 16,
                          ),
                          label: const Text(AppStrings.takePhoto),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 16,
                        ),
                        label: const Text(AppStrings.pickPhoto),
                      ),
                    ),
                  ],
                ),

                // ── Image thumbnails ──────────────────────────────────────
                if (_imageBase64List.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageBase64List.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, i) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(_imageBase64List[i]),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _imageBase64List.removeAt(i)),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.scrim.withValues(alpha: 0.62),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ── Note ──────────────────────────────────────────────────
                AppTextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  labelText: "Ghi chú (tuỳ chọn)",
                ),
                const SizedBox(height: 10),

                // ── Pending toggle (free — no media restriction) ───────────
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.pending),
                  subtitle: Text(
                    _hasMedia
                        ? "Có audio/ảnh — nên bật để đối soát sau."
                        : "Bật để chuyển vào danh sách đối soát.",
                  ),
                  value: _pending,
                  onChanged: (v) => setState(() => _pending = v),
                ),
                const SizedBox(height: 12),

                // ── Action buttons ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _save(cats),
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text(AppStrings.saveTransaction),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
