import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:intl/intl.dart";

import "../core/amount_input.dart";
import "../core/constants.dart";
import "../core/strings.dart";
import "../data/ledger_repository.dart";
import "../data/models/category_model.dart";
import "../features/image_attachment/data/image_picker_service.dart";
import "../features/image_attachment/data/image_storage_service.dart";
import "../features/image_attachment/domain/image_attachment_model.dart";
import "../features/image_attachment/presentation/widgets/image_attachment_list.dart";
import "../features/transactions/application/transaction_draft_validator.dart";
import "../features/voice_note/domain/audio_attachment_model.dart";
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

  AudioAttachmentModel? _audio;

  // Images
  final _images = <ImageAttachmentModel>[];
  final _imagePicker = ImagePickerService();
  final _imageStorage = ImageStorageService();
  final _draftResolver = const TransactionDraftResolver();

  bool get _hasMedia => _audio != null || _images.isNotEmpty;

  // Camera available on native platforms only
  bool get _showCamera => !kIsWeb;

  bool get _isDirty =>
      _titleCtrl.text != _initTitle ||
      _amount.value != _initAmount ||
      _noteCtrl.text.isNotEmpty ||
      _audio != null ||
      _images.isNotEmpty;

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
    if (discard == true) {
      await _deleteImages(_images);
      if (mounted) Navigator.pop(context);
    }
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pick(source);
      if (picked == null || !mounted) return;
      setState(() {
        _images.add(picked.image);
        _pending = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.imageSaveFailed)));
    }
  }

  Future<void> _removeImage(ImageAttachmentModel image) async {
    setState(() => _images.removeWhere((item) => item.id == image.id));
    await _imageStorage.delete(image);
  }

  Future<void> _deleteImages(List<ImageAttachmentModel> images) async {
    for (final image in images) {
      await _imageStorage.delete(image);
    }
  }

  // ── Save logic ────────────────────────────────────────────────────────────

  Future<void> _save(List<CategoryModel> cats) async {
    final amount = _amount.value;
    final matched = cats.where((c) => c.isIncome == _income).toList();
    final catId = _categoryId ?? (matched.isNotEmpty ? matched.first.id : null);

    final draft = _draftResolver.resolve(
      TransactionSaveDraft(
        rawTitle: _titleCtrl.text,
        fallbackTitle: _income
            ? AppStrings.quickIncomeTitle
            : AppStrings.quickExpenseTitle,
        amountVnd: amount,
        pending: _pending,
        selectedCategoryId: _categoryId,
        fallbackCategoryId: catId,
      ),
    );
    final message = _firstDraftErrorMessage(draft.errors);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    await widget.repo.addQuick(
      title: draft.title,
      amountVnd: amount,
      isIncome: _income,
      categoryId: draft.categoryId ?? "",
      at: _date,
      pending: _pending,
      complete: draft.complete,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      audio: _audio,
      images: _images,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _pending
              ? AppStrings.savePendingSuccess
              : AppStrings.saveTransactionSuccess,
        ),
      ),
    );
  }

  String? _firstDraftErrorMessage(
    List<TransactionDraftValidationError> errors,
  ) {
    if (errors.contains(TransactionDraftValidationError.amountRequired)) {
      return AppStrings.amountRequired;
    }
    if (errors.contains(TransactionDraftValidationError.categoryRequired)) {
      return AppStrings.categoryRequired;
    }
    return null;
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
                if (widget.mode == QuickEntryMode.voice || _audio != null) ...[
                  AppVoiceNoteSection(
                    audio: _audio,
                    autoStartRecording: widget.mode == QuickEntryMode.voice,
                    onChanged: (audio) => setState(() {
                      _audio = audio;
                      if (audio != null) _pending = true;
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
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ImageAttachmentList(
                    images: _images,
                    onDelete: _removeImage,
                    height: 80,
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
