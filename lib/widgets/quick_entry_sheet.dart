import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "../core/amount_input.dart";
import "../core/date_format.dart";
import "../core/strings.dart";
import "../data/ledger_repository.dart";
import "../data/models/category_model.dart";
import "../features/image_attachment/data/image_picker_service.dart";
import "../features/image_attachment/data/image_storage_service.dart";
import "../features/image_attachment/domain/image_attachment_model.dart";
import "../features/transactions/application/transaction_draft_validator.dart";
import "../features/transactions/presentation/widgets/transaction_category_chips.dart";
import "../features/transactions/presentation/widgets/transaction_date_picker_field.dart";
import "../features/transactions/presentation/widgets/transaction_image_attachments.dart";
import "../features/transactions/presentation/widgets/transaction_sheet_shell.dart";
import "../features/transactions/presentation/widgets/transaction_type_toggle.dart";
import "../features/voice_note/domain/audio_attachment_model.dart";
import "../shared/widgets/app_discard_dialog.dart";
import "../shared/widgets/app_primary_button.dart";
import "../shared/widgets/app_voice_note_section.dart";
import "app_text_field.dart";
import "form_amount_field.dart";

enum QuickEntryMode { tap, voice, receipt }

Future<void> showQuickEntrySheet(
  BuildContext context,
  LedgerRepository repo, {
  QuickEntryMode mode = QuickEntryMode.tap,
}) {
  return showTransactionFormSheet(
    context,
    child: _QuickEntryBody(repo: repo, mode: mode),
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
      final ts = formatQuickEntryTimestamp(DateTime.now());
      _titleCtrl.text = "Ghi âm giao dịch - $ts";
      _amount.setValue(0);
    } else if (widget.mode == QuickEntryMode.receipt) {
      final ts = formatQuickEntryTimestamp(DateTime.now());
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
    final discard = await showDiscardEntryDialog(context);
    if (discard) {
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
    final message = TransactionDraftValidator.firstUserMessage(draft.errors);
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
                TransactionSheetHeader(
                  title: sheetTitle,
                  onClose: _handleClose,
                ),
                const SizedBox(height: 12),
                TransactionTypeToggle(
                  isIncome: _income,
                  showSelectedIcon: false,
                  onChanged: (income) => setState(() {
                    _income = income;
                    _categoryId = null;
                  }),
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
                TransactionCategoryChips(
                  categories: cats,
                  isIncome: _income,
                  selectedId: _categoryId,
                  onSelected: (id) => setState(() => _categoryId = id),
                ),
                const SizedBox(height: 14),

                // ── Date picker ───────────────────────────────────────────
                TransactionDatePickerField(
                  date: _date,
                  onDateChanged: (d) => setState(() => _date = d),
                ),
                const SizedBox(height: 10),
                TransactionImageAttachments(
                  images: _images,
                  showCamera: _showCamera,
                  onPick: _pickImage,
                  onDelete: _removeImage,
                ),

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
                AppPrimaryButton(
                  label: AppStrings.saveTransaction,
                  icon: Icons.save_rounded,
                  onPressed: () => _save(cats),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
