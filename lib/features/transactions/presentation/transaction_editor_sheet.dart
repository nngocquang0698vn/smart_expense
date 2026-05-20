import "package:smart_expense/features/categories/presentation/category_visuals.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:image_picker/image_picker.dart";
import "package:smart_expense/core/utils/amount_input_notifier.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/app_text_field.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/shared/components/app_confirm_bottom_sheet.dart";
import "package:smart_expense/shared/components/app_discard_dialog.dart";
import "package:smart_expense/shared/components/app_primary_button.dart";
import "package:smart_expense/shared/components/app_voice_note_section.dart";
import "package:smart_expense/shared/design_system/theme/app_finance_colors.dart";
import "package:smart_expense/features/categories/application/category_selection_resolver.dart";
import "package:smart_expense/features/transactions/data/attachments/image_picker_service.dart";
import "package:smart_expense/features/transactions/data/attachments/image_storage_service.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/application/transaction_draft_validator.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/shared/components/app_date_picker.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_entry_form.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_sheet_shell.dart";

Future<void> showTransactionEditor(
  BuildContext context,
  LedgerRepository repo, {
  LedgerTransaction? existing,
  bool defaultPending = false,
}) {
  return showTransactionFormSheet(
    context,
    child: _EditorBody(
      repo: repo,
      existing: existing,
      defaultPending: defaultPending,
    ),
  );
}

class _EditorBody extends ConsumerStatefulWidget {
  const _EditorBody({
    required this.repo,
    this.existing,
    required this.defaultPending,
  });

  final LedgerRepository repo;
  final LedgerTransaction? existing;
  final bool defaultPending;

  @override
  ConsumerState<_EditorBody> createState() => _EditorBodyState();
}

class _EditorBodyState extends ConsumerState<_EditorBody> {
  late final int _amountKey;

  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late bool _income;
  String? _categoryId;
  late DateTime _date;
  late bool _pending;
  AudioAttachmentModel? _audio;
  final _images = <ImageAttachmentModel>[];
  final _imagePicker = ImagePickerService();
  final _imageStorage = ImageStorageService();
  final _draftResolver = const TransactionDraftResolver();
  final _categorySelection = const CategorySelectionResolver();

  bool get _showCamera => !kIsWeb;

  // Snapshots for dirty detection
  late String _initTitle;
  late int _initAmount;
  late String _initNote;
  late bool _initIncome;
  late String? _initCategoryId;
  late DateTime _initDate;
  late bool _initPending;
  late AudioAttachmentModel? _initAudio;
  late Set<String> _initImageIds;

  bool get _isDirty =>
      _titleCtrl.text != _initTitle ||
      ref.read(amountInputProvider(_amountKey)) != _initAmount ||
      _noteCtrl.text != _initNote ||
      _income != _initIncome ||
      _categoryId != _initCategoryId ||
      _date != _initDate ||
      _pending != _initPending ||
      _audio?.id != _initAudio?.id ||
      !_setEquals(_images.map((image) => image.id).toSet(), _initImageIds);

  @override
  void initState() {
    super.initState();
    _amountKey = widget.existing?.amountVnd ?? 0;
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _noteCtrl.text = e.note ?? "";
      _income = e.isIncome;
      _categoryId = e.categoryId;
      _date = e.occurredAt;
      _pending = e.pending;
      _audio = e.audio;
      _images.addAll(e.images);
    } else {
      _income = false;
      _date = DateTime.now();
      _pending = widget.defaultPending;
      _audio = null;
    }
    // Snapshot initial values for dirty check
    _initTitle = _titleCtrl.text;
    _initAmount = _amountKey;
    _initNote = _noteCtrl.text;
    _initIncome = _income;
    _initCategoryId = _categoryId;
    _initDate = _date;
    _initPending = _pending;
    _initAudio = _audio;
    _initImageIds = _images.map((image) => image.id).toSet();

    // Rebuild on text changes so dirty flag updates
    _titleCtrl.addListener(() => setState(() {}));
    _noteCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    if (!_isDirty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final discard = await showDiscardEditDialog(context);
    if (discard) {
      await _deleteNewImages();
      if (mounted) Navigator.pop(context);
    }
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    return a.length == b.length && a.containsAll(b);
  }

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

  void _removeImage(ImageAttachmentModel image) {
    setState(() => _images.removeWhere((item) => item.id == image.id));
  }

  Future<void> _deleteNewImages() async {
    for (final image in _images) {
      if (!_initImageIds.contains(image.id)) {
        await _imageStorage.delete(image);
      }
    }
  }

  Future<void> _saveTransaction(List<LedgerCategory> cats) async {
    final amount = ref.read(amountInputProvider(_amountKey));
    final matchingCategories = _categorySelection.enabledForSide(
      cats,
      isIncome: _income,
    );
    final fallbackCategoryId = _categorySelection.fallbackId(
      matchingCategories,
    );
    final draft = _draftResolver.resolve(
      TransactionSaveDraft(
        rawTitle: _titleCtrl.text,
        amountVnd: amount,
        pending: _pending,
        selectedCategoryId: _categoryId,
        fallbackCategoryId: fallbackCategoryId,
        requireTitle: true,
      ),
    );
    final error = TransactionDraftValidator.firstUserError(
      draft.errors,
      includeTitle: true,
    );
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_validationMessage(error))));
      return;
    }

    final e = widget.existing;
    if (e == null) {
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
    } else {
      await widget.repo.putTransaction(
        e.copyWith(
          title: draft.title,
          amountVnd: amount,
          isIncome: _income,
          categoryId: draft.categoryId ?? e.categoryId,
          occurredAt: _date,
          pending: _pending,
          complete: draft.complete,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          audio: _audio,
          images: _images,
        ),
      );
    }

    if (e == null) {
      await ref
          .read(pwaInstallControllerProvider.notifier)
          .onFirstCompleteTransactionSaved(
            pending: _pending,
            complete: draft.complete,
          );
    }

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

  Future<void> _delete() async {
    final confirmed = await AppConfirmBottomSheet.show(
      context,
      title: context.l10n.deleteTransactionTitle,
      message: context.l10n.deleteTransactionMessage,
      confirmLabel: context.l10n.delete,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await widget.repo.deleteTransaction(widget.existing!.id);
    if (!mounted) return;
    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    ref.listen(amountInputProvider(_amountKey), (_, _) => setState(() {}));

    return FutureBuilder<List<LedgerCategory>>(
      future: widget.repo.categories(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final cats = snap.data!;
        final categoryItems = _categorySelection.enabledForSide(
          cats,
          isIncome: _income,
        );
        final dropdownValue = _categorySelection.selectedValueOrNull(
          selectedId: _categoryId,
          items: categoryItems,
        );

        final finance = context.financeColors;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row with close button
                TransactionSheetHeader(
                  title: widget.existing == null
                      ? context.l10n.addTransaction
                      : context.l10n.editTransaction,
                  onClose: _handleClose,
                ),
                const SizedBox(height: 14),

                TransactionEntryForm(
                  titleField: AppTextField(
                    controller: _titleCtrl,
                    labelText: context.l10n.transactionTitle,
                  ),
                  initialAmount: _amountKey,
                  noteController: _noteCtrl,
                  isIncome: _income,
                  onIncomeChanged: (income) => setState(() => _income = income),
                  onSideChanged: () {
                    final nextItems = _categorySelection.enabledForSide(
                      cats,
                      isIncome: _income,
                    );
                    _categoryId = _categorySelection.fallbackId(nextItems);
                  },
                  date: _date,
                  dateStyle: AppDatePickerStyle.listTile,
                  onDateChanged: (d) => setState(() => _date = d),
                  pending: _pending,
                  onPendingChanged: (v) => setState(() => _pending = v),
                  images: _images,
                  showCamera: _showCamera,
                  onPickImage: _pickImage,
                  onDeleteImage: _removeImage,
                  imageThumbnailHeight: 96,
                  mediaSections: [
                    AppVoiceNoteSection(
                      audio: _audio,
                      showWhenEmpty: true,
                      onChanged: (audio) => setState(() {
                        _audio = audio;
                        if (audio != null) _pending = true;
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  categorySection: DropdownButtonFormField<String>(
                    dropdownColor: finance.sheetBackground,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: finance.fieldText),
                    // ignore: deprecated_member_use
                    value: dropdownValue,
                    items: categoryItems
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(c.icon, color: c.color, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  c.name,
                                  style: TextStyle(color: finance.fieldText),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                    decoration: InputDecoration(
                      labelText: context.l10n.category,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Action buttons ───────────────────────────────────────
                AppPrimaryButton(
                  label: context.l10n.save,
                  icon: Icons.save_rounded,
                  onPressed: () => _saveTransaction(cats),
                ),

                // Delete (only for existing transactions)
                if (widget.existing != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: finance.dangerAction,
                      side: BorderSide(color: finance.dangerAction, width: 1.5),
                    ),
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(context.l10n.deleteTransaction),
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
