import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:image_picker/image_picker.dart";
import "package:smart_expense/core/utils/amount_input_notifier.dart";
import "package:smart_expense/core/utils/date_format.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/app_text_field.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/shared/components/app_discard_dialog.dart";
import "package:smart_expense/shared/components/app_primary_button.dart";
import "package:smart_expense/shared/components/app_voice_note_section.dart";
import "package:smart_expense/features/transactions/data/attachments/image_picker_service.dart";
import "package:smart_expense/features/transactions/data/attachments/image_storage_service.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/application/transaction_draft_validator.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_category_chips.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_entry_form.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_sheet_shell.dart";

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

class _QuickEntryBody extends ConsumerStatefulWidget {
  const _QuickEntryBody({required this.repo, required this.mode});

  final LedgerRepository repo;
  final QuickEntryMode mode;

  @override
  ConsumerState<_QuickEntryBody> createState() => _QuickEntryBodyState();
}

class _QuickEntryBodyState extends ConsumerState<_QuickEntryBody> {
  static const _amountKey = 0;

  final _titleCtrl = TextEditingController();
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
      ref.read(amountInputProvider(_amountKey)) != _initAmount ||
      _noteCtrl.text.isNotEmpty ||
      _audio != null ||
      _images.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pending = widget.mode != QuickEntryMode.tap;

    if (widget.mode == QuickEntryMode.voice) {
      final ts = formatQuickEntryTimestamp(DateTime.now());
      _titleCtrl.text = "${AppLocalizations.vi.quickEntryVoice} - $ts";
    } else if (widget.mode == QuickEntryMode.receipt) {
      final ts = formatQuickEntryTimestamp(DateTime.now());
      _titleCtrl.text = "${AppLocalizations.vi.quickEntryReceipt} - $ts";
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _pickImage(
          _showCamera ? ImageSource.camera : ImageSource.gallery,
        );
      });
    }

    // Snapshot initial values so we can detect dirty state
    _initTitle = _titleCtrl.text;
    _initAmount = _amountKey;

    _titleCtrl.addListener(() => setState(() {}));
    _noteCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
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
      ).showSnackBar(SnackBar(content: Text(context.l10n.imageSaveFailed)));
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

  Future<void> _save(List<LedgerCategory> cats) async {
    final amount = ref.read(amountInputProvider(_amountKey));
    final matched = cats.where((c) => c.isIncome == _income).toList();
    final catId = _categoryId ?? (matched.isNotEmpty ? matched.first.id : null);

    final draft = _draftResolver.resolve(
      TransactionSaveDraft(
        rawTitle: _titleCtrl.text,
        fallbackTitle: _income
            ? context.l10n.quickIncomeTitle
            : context.l10n.quickExpenseTitle,
        amountVnd: amount,
        pending: _pending,
        selectedCategoryId: _categoryId,
        fallbackCategoryId: catId,
      ),
    );
    final error = TransactionDraftValidator.firstUserError(draft.errors);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_validationMessage(error))));
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
              ? context.l10n.savePendingSuccess
              : context.l10n.saveTransactionSuccess,
        ),
      ),
    );
  }

  String _validationMessage(TransactionDraftValidationError error) {
    return switch (error) {
      TransactionDraftValidationError.titleRequired =>
        context.l10n.titleRequired,
      TransactionDraftValidationError.amountRequired =>
        context.l10n.amountRequired,
      TransactionDraftValidationError.categoryRequired =>
        context.l10n.categoryRequired,
    };
  }

  // ── Main build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen(amountInputProvider(_amountKey), (_, _) => setState(() {}));

    return FutureBuilder<List<LedgerCategory>>(
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
          QuickEntryMode.voice => context.l10n.quickEntryVoice,
          QuickEntryMode.receipt => context.l10n.quickEntryReceipt,
          QuickEntryMode.tap => context.l10n.quickEntryTap,
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
                TransactionEntryForm(
                  typeToggleFirst: true,
                  showSelectedIcon: false,
                  initialAmount: _amountKey,
                  noteController: _noteCtrl,
                  isIncome: _income,
                  onIncomeChanged: (income) => setState(() {
                    _income = income;
                    _categoryId = null;
                  }),
                  date: _date,
                  onDateChanged: (d) => setState(() => _date = d),
                  pending: _pending,
                  onPendingChanged: (v) => setState(() => _pending = v),
                  pendingSubtitle: _hasMedia
                      ? context.l10n.pendingSubtitleWithMedia
                      : context.l10n.pendingSubtitleDefault,
                  images: _images,
                  showCamera: _showCamera,
                  onPickImage: _pickImage,
                  onDeleteImage: _removeImage,
                  amountAlwaysShowKeypad: widget.mode == QuickEntryMode.tap,
                  amountAutofocus: widget.mode == QuickEntryMode.tap,
                  titleField: AppTextField(
                    controller: _titleCtrl,
                    labelText: context.l10n.titleOptional,
                  ),
                  mediaSections: [
                    if (widget.mode == QuickEntryMode.voice ||
                        _audio != null) ...[
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
                  ],
                  categorySection: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.category,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TransactionCategoryChips(
                        categories: cats,
                        isIncome: _income,
                        selectedId: _categoryId,
                        onSelected: (id) => setState(() => _categoryId = id),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Action buttons ────────────────────────────────────────
                AppPrimaryButton(
                  label: context.l10n.saveTransaction,
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
