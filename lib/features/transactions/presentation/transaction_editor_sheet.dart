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
import "package:smart_expense/shared/components/app_notification.dart";
import "package:smart_expense/shared/components/amount_keypad.dart";
import "package:smart_expense/shared/design_system/design_system.dart";
import "package:smart_expense/features/categories/application/category_selection_resolver.dart";
import "package:smart_expense/features/transactions/data/attachments/image_picker_service.dart";
import "package:smart_expense/features/transactions/data/attachments/image_storage_service.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/application/transaction_draft_validator.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_category_section.dart";
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
  final Object _voiceRecorderSessionId = Object();
  late final Future<List<LedgerCategory>> _categoriesFuture;
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
  TransactionDraftValidationError? _validationError;
  bool _amountKeypadOpen = false;

  bool get _hasMedia => _audio != null || _images.isNotEmpty;

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
    _categoriesFuture = widget.repo.categories();
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

    _titleCtrl.addListener(_clearTitleValidationOnInput);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_clearTitleValidationOnInput);
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _clearTitleValidationOnInput() {
    if (_validationError == TransactionDraftValidationError.titleRequired &&
        _titleCtrl.text.trim().isNotEmpty) {
      setState(() => _validationError = null);
    }
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
      setState(() => _images.add(picked.image));
    } catch (_) {
      if (!mounted) return;
      showError(context, context.l10n.imageSaveFailed);
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
      setState(() => _validationError = error);
      return;
    }
    setState(() => _validationError = null);

    final e = widget.existing;
    try {
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
    } catch (_) {
      if (!mounted) return;
      showError(context, context.l10n.transactionSaveFailed);
      return;
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
    showSuccess(
      context,
      e == null
          ? (_pending
                ? context.l10n.savePendingSuccess
                : context.l10n.saveTransactionSuccess)
          : context.l10n.transactionUpdatedSuccess,
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
    try {
      await widget.repo.deleteTransaction(widget.existing!.id);
    } catch (_) {
      if (!mounted) return;
      showError(context, context.l10n.transactionDeleteFailed);
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    showSuccess(context, context.l10n.transactionDeletedSuccess);
  }

  void _clearValidation(TransactionDraftValidationError error) {
    if (_validationError == error) {
      setState(() => _validationError = null);
    }
  }

  String? _validationMessageFor(TransactionDraftValidationError error) {
    return _validationError == error ? _validationMessage(error) : null;
  }

  AmountKeypad _amountKeypad() {
    final notifier = ref.read(amountInputProvider(_amountKey).notifier);
    return AmountKeypad(
      onDigit: notifier.appendDigit,
      onTripleZero: notifier.appendTripleZero,
      onBackspace: notifier.backspace,
      onDone: () => setState(() => _amountKeypadOpen = false),
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

  @override
  Widget build(BuildContext context) {
    ref.listen(amountInputProvider(_amountKey), (_, next) {
      if (_validationError == TransactionDraftValidationError.amountRequired &&
          next > 0) {
        setState(() => _validationError = null);
      }
    });

    return FutureBuilder<List<LedgerCategory>>(
      future: _categoriesFuture,
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

        final finance = context.financeColors;

        return TransactionKeypadScaffold(
          keypadVisible: _amountKeypadOpen,
          keypad: _amountKeypad(),
          child: TransactionSheetScrollBody(
            compact: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              TransactionSheetHeader(
                title: widget.existing == null
                    ? context.l10n.addTransaction
                    : context.l10n.editTransaction,
                onClose: _handleClose,
              ),
              const SizedBox(height: AppSpacing.xs),
              TransactionEntryForm(
                density: TransactionFormDensity.compact,
                titleField: Focus(
                  onFocusChange: (focused) {
                    if (focused && _amountKeypadOpen) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _amountKeypadOpen = false);
                        }
                      });
                    }
                  },
                  child: AppTextField(
                    controller: _titleCtrl,
                    labelText: context.l10n.transactionTitle,
                    errorText: _validationMessageFor(
                      TransactionDraftValidationError.titleRequired,
                    ),
                  ),
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
                  if (_validationError ==
                      TransactionDraftValidationError.categoryRequired) {
                    _validationError = null;
                  }
                },
                date: _date,
                onDateChanged: (d) => setState(() => _date = d),
                images: _images,
                onPickImage: _pickImage,
                onDeleteImage: _removeImage,
                audio: _audio,
                onAudioChanged: (audio) => setState(() => _audio = audio),
                voiceRecorderSessionId: _voiceRecorderSessionId,
                imageThumbnailHeight: 80,
                amountErrorText: _validationMessageFor(
                  TransactionDraftValidationError.amountRequired,
                ),
                amountKeypadOpen: _amountKeypadOpen,
                onAmountTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() => _amountKeypadOpen = true);
                },
                onAmountDone: () => setState(() => _amountKeypadOpen = false),
                onDismissAmountKeypad: () {
                  if (_amountKeypadOpen) {
                    setState(() => _amountKeypadOpen = false);
                  }
                },
                categorySection: TransactionCategorySection(
                  categories: categoryItems,
                  includeSelectedFrom: cats,
                  isIncome: _income,
                  selectedId: _categoryId,
                  onSelected: (id) {
                    setState(() => _categoryId = id);
                    _clearValidation(
                      TransactionDraftValidationError.categoryRequired,
                    );
                  },
                  errorText: _validationMessageFor(
                    TransactionDraftValidationError.categoryRequired,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TransactionPendingSwitch(
                pending: _pending,
                onChanged: (v) => setState(() => _pending = v),
                subtitle: _hasMedia
                    ? context.l10n.pendingSubtitleWithMedia
                    : context.l10n.pendingSubtitleDefault,
              ),
              const SizedBox(height: AppSpacing.xs),
              // ── Action buttons (một hàng khi sửa giao dịch) ───────────
              if (widget.existing == null)
                AppPrimaryButton(
                  label: context.l10n.save,
                  icon: Icons.save_rounded,
                  onPressed: () => _saveTransaction(cats),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        width: double.infinity,
                        child: AppPrimaryButton(
                          label: context.l10n.save,
                          icon: Icons.save_rounded,
                          onPressed: () => _saveTransaction(cats),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: finance.dangerAction,
                          side: BorderSide(
                            color: finance.dangerAction,
                            width: 1.5,
                          ),
                          minimumSize: const Size(0, 52),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(
                          context.l10n.deleteTransaction,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
