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
import "package:smart_expense/features/settings/application/user_preferences_controller.dart";
import "package:smart_expense/features/transactions/application/transaction_image_actions.dart";
import "package:smart_expense/features/transactions/application/voice_transaction_demo_mapper.dart";
import "package:smart_expense/features/transactions/data/attachments/audio_storage_service.dart";
import "package:smart_expense/features/transactions/data/attachments/image_picker_service.dart";
import "package:smart_expense/features/transactions/data/attachments/image_storage_service.dart";
import "package:smart_expense/features/transactions/data/voice_transaction_demo_api_client.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/application/transaction_draft_validator.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/presentation/widgets/ai_voice_parse_button.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_category_section.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_entry_form.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_sheet_shell.dart";

enum TransactionEditorPresentation { sheet, embedded }

class TransactionEditorBody extends ConsumerStatefulWidget {
  const TransactionEditorBody({
    super.key,
    required this.repo,
    this.existing,
    this.defaultPending = false,
    this.presentation = TransactionEditorPresentation.sheet,
    this.onSaved,
    this.footerActions,
  });

  final LedgerRepository repo;
  final LedgerTransaction? existing;
  final bool defaultPending;
  final TransactionEditorPresentation presentation;
  final VoidCallback? onSaved;
  final Widget? footerActions;

  @override
  TransactionEditorBodyState createState() => TransactionEditorBodyState();
}

class TransactionEditorBodyState extends ConsumerState<TransactionEditorBody> {
  late int _amountKey;

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
  final _audioStorage = AudioStorageService();
  final _draftResolver = const TransactionDraftResolver();
  final _categorySelection = const CategorySelectionResolver();
  final _aiMapper = const VoiceTransactionDemoMapper();
  TransactionDraftValidationError? _validationError;
  bool _amountKeypadOpen = false;
  bool _aiParsing = false;

  bool get _hasMedia => _audio != null || _images.isNotEmpty;
  bool get isEmbedded =>
      widget.presentation == TransactionEditorPresentation.embedded;

  late String _initTitle;
  late int _initAmount;
  late String _initNote;
  late bool _initIncome;
  late String? _initCategoryId;
  late DateTime _initDate;
  late bool _initPending;
  late AudioAttachmentModel? _initAudio;
  late Set<String> _initImageIds;

  bool get isDirty =>
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
    _bootstrapFromExisting(widget.existing);
    _titleCtrl.addListener(_clearTitleValidationOnInput);
  }

  @override
  void didUpdateWidget(TransactionEditorBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.existing?.id != widget.existing?.id) {
      _bootstrapFromExisting(widget.existing);
      setState(() {});
    }
  }

  void _bootstrapFromExisting(LedgerTransaction? e) {
    _amountKey = e?.amountVnd ?? 0;
    _titleCtrl.text = e?.title ?? "";
    _noteCtrl.text = e?.note ?? "";
    _income = e?.isIncome ?? false;
    _categoryId = e?.categoryId;
    _date = e?.occurredAt ?? DateTime.now();
    _pending = e?.pending ?? widget.defaultPending;
    _audio = e?.audio;
    _images
      ..clear()
      ..addAll(e?.images ?? const []);
    _snapshotInitial();
  }

  void _snapshotInitial() {
    _initTitle = _titleCtrl.text;
    _initAmount = _amountKey;
    _initNote = _noteCtrl.text;
    _initIncome = _income;
    _initCategoryId = _categoryId;
    _initDate = _date;
    _initPending = _pending;
    _initAudio = _audio;
    _initImageIds = _images.map((image) => image.id).toSet();
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

  Future<bool> requestClose() async {
    if (!isDirty) return true;
    final discard = await showDiscardEditDialog(context);
    if (discard) {
      await discardUnsavedImages();
    }
    return discard;
  }

  Future<void> discardUnsavedImages() async {
    for (final image in _images) {
      if (!_initImageIds.contains(image.id)) {
        await _imageStorage.delete(image);
      }
    }
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    return a.length == b.length && a.containsAll(b);
  }

  Future<void> _pickImage(ImageSource source) async {
    final outcome = await TransactionImageActions.pickAndAdd(
      context: context,
      picker: _imagePicker,
      source: source,
      currentImageCount: _images.length,
    );
    if (!mounted) return;
    TransactionImageActions.notifyOutcome(context, outcome);
    if (outcome.status == TransactionImagePickStatus.added ||
        outcome.status == TransactionImagePickStatus.addedPartial) {
      setState(() => _images.addAll(outcome.images));
    }
  }

  void _removeImage(ImageAttachmentModel image) {
    setState(() => _images.removeWhere((item) => item.id == image.id));
  }

  Future<void> saveTransaction() async {
    final cats = await _categoriesFuture;
    if (!mounted) return;
    await _saveTransaction(cats);
  }

  Future<void> deleteTransaction() => _delete();

  Future<void> parseAiVoiceFromAudio() async {
    final audio = _audio;
    if (audio == null) {
      debugPrint("[AI Voice Demo] editor parse skipped: no audio");
      return;
    }
    final prefs = ref.read(userPreferencesControllerProvider);
    final endpoint = prefs.aiVoiceApiEndpoint;
    if (!prefs.aiVoiceRecognitionEnabled ||
        endpoint == null ||
        endpoint.trim().isEmpty) {
      debugPrint("[AI Voice Demo] editor parse skipped: missing config");
      showWarning(context, "Bạn cần cấu hình endpoint AI trong Profile trước.");
      return;
    }
    if (_aiParsing) {
      debugPrint("[AI Voice Demo] editor parse skipped: already parsing");
      return;
    }

    setState(() => _aiParsing = true);
    final client = VoiceTransactionDemoApiClient();
    try {
      final cats = await _categoriesFuture;
      final bytes = await _audioStorage.read(audio);
      debugPrint(
        "[AI Voice Demo] editor parse start "
        "transactionId=${widget.existing?.id ?? "new"} "
        "audioId=${audio.id} mime=${audio.mimeType} "
        "extension=${audio.extension} bytes=${bytes.length}",
      );
      final response = await client.parseAudio(
        endpoint: endpoint,
        demoToken: prefs.aiVoiceDemoToken,
        audio: audio,
        audioBytes: bytes,
      );
      if (!mounted) return;
      final patch = _aiMapper.map(
        response: response,
        categories: cats,
        currentCategoryId: _categoryId,
      );
      debugPrint(
        "[AI Voice Demo] editor parse success "
        "title=${patch.title != null} amount=${patch.amountVnd != null} "
        "categoryId=${patch.categoryId ?? "unchanged"} "
        "date=${patch.occurredAt?.toIso8601String() ?? "unchanged"} "
        "warnings=${response.warnings.length}",
      );
      _applyAiPatch(patch);
      showSuccess(
        context,
        "AI đã điền thông tin. Bạn hãy kiểm tra lại trước khi lưu.",
      );
    } catch (error) {
      debugPrint("[AI Voice Demo] editor parse failed: $error");
      if (mounted) {
        showError(
          context,
          "Đã có lỗi khi AI nhận diện ghi âm. Bạn hãy tiếp tục lưu giao dịch và đối soát lại sau khi rảnh.",
        );
      }
    } finally {
      client.close();
      if (mounted) setState(() => _aiParsing = false);
    }
  }

  void _applyAiPatch(VoiceTransactionFormPatch patch) {
    setState(() {
      if (patch.title != null) _titleCtrl.text = patch.title!;
      if (patch.note != null) _noteCtrl.text = patch.note!;
      if (patch.amountVnd != null) {
        ref
            .read(amountInputProvider(_amountKey).notifier)
            .setValue(patch.amountVnd!);
      }
      _income = patch.isIncome;
      _categoryId = patch.categoryId ?? _categoryId;
      _date = patch.occurredAt ?? _date;
      _pending = true;
      _validationError = null;
    });
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
    _snapshotInitial();
    if (isEmbedded) {
      widget.onSaved?.call();
      showSuccess(context, context.l10n.transactionUpdatedSuccess);
    } else {
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
    if (isEmbedded) {
      widget.onSaved?.call();
    } else {
      Navigator.pop(context);
    }
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

  Future<void> _handleSheetClose() async {
    if (await requestClose() && mounted && !isEmbedded) {
      Navigator.pop(context);
    }
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
        final prefs = ref.watch(userPreferencesControllerProvider);
        final showAiParseButton =
            _audio != null && prefs.aiVoiceRecognitionEnabled;

        final form = TransactionEntryForm(
          density: TransactionFormDensity.compact,
          titleField: Focus(
            onFocusChange: (focused) {
              if (focused && _amountKeypadOpen) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _amountKeypadOpen = false);
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
        );

        final pendingSwitch = TransactionPendingSwitch(
          pending: _pending,
          onChanged: (v) => setState(() => _pending = v),
          subtitle: _hasMedia
              ? context.l10n.pendingSubtitleWithMedia
              : context.l10n.pendingSubtitleDefault,
        );

        final saveRow = widget.existing == null
            ? AppPrimaryButton(
                label: context.l10n.save,
                icon: Icons.save_rounded,
                onPressed: () => _saveTransaction(cats),
              )
            : Row(
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
                  if (!isEmbedded) ...[
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
                ],
              );

        final children = <Widget>[
          if (!isEmbedded) ...[
            TransactionSheetHeader(
              title: widget.existing == null
                  ? context.l10n.addTransaction
                  : context.l10n.editTransaction,
              onClose: _handleSheetClose,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          form,
          const SizedBox(height: AppSpacing.sm),
          TransactionPendingActionRow(
            pendingSwitch: pendingSwitch,
            trailing: showAiParseButton
                ? AiVoiceParseButton(
                    isLoading: _aiParsing,
                    onPressed: parseAiVoiceFromAudio,
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (widget.footerActions != null) ...[
            widget.footerActions!,
            if (!isEmbedded) const SizedBox(height: AppSpacing.xs),
          ] else
            saveRow,
          if (isEmbedded) const SizedBox(height: AppSpacing.md),
        ];

        if (isEmbedded) {
          return TransactionKeypadScaffold(
            keypadVisible: _amountKeypadOpen,
            keypad: _amountKeypad(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: children,
            ),
          );
        }

        return TransactionKeypadScaffold(
          keypadVisible: _amountKeypadOpen,
          keypad: _amountKeypad(),
          child: TransactionSheetScrollBody(
            compact: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: children,
          ),
        );
      },
    );
  }
}
