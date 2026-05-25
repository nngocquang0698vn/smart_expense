import "package:flutter/material.dart";
import "package:smart_expense/core/utils/attachment_capture_policy.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:image_picker/image_picker.dart";
import "package:smart_expense/core/utils/amount_input_notifier.dart";
import "package:smart_expense/core/utils/date_format.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/app_notification.dart";
import "package:smart_expense/shared/components/app_text_field.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/shared/components/app_discard_dialog.dart";
import "package:smart_expense/shared/components/app_primary_button.dart";
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
import "package:smart_expense/shared/components/amount_keypad.dart";
import "package:smart_expense/features/transactions/presentation/widgets/ai_voice_parse_button.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_category_section.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_entry_form.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_sheet_shell.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

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
  final Object _voiceRecorderSessionId = Object();
  late final Future<List<LedgerCategory>> _categoriesFuture;

  bool _income = false;
  bool _pending = false;
  DateTime _date = DateTime.now();
  String? _categoryId;
  bool _amountKeypadOpen = false;

  // Snapshots for dirty detection
  late String _initTitle;
  late int _initAmount;

  AudioAttachmentModel? _audio;
  TransactionDraftValidationError? _validationError;

  // Images
  final _images = <ImageAttachmentModel>[];
  final _imagePicker = ImagePickerService();
  final _imageStorage = ImageStorageService();
  final _audioStorage = AudioStorageService();
  final _draftResolver = const TransactionDraftResolver();
  final _aiMapper = const VoiceTransactionDemoMapper();

  bool get _hasMedia => _audio != null || _images.isNotEmpty;
  bool _aiParsing = false;

  bool get _isDirty =>
      _titleCtrl.text != _initTitle ||
      ref.read(amountInputProvider(_amountKey)) != _initAmount ||
      _noteCtrl.text.isNotEmpty ||
      _audio != null ||
      _images.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = widget.repo.categories().then(
      (list) => list.where((c) => c.enabled).toList(),
    );
    _pending = widget.mode != QuickEntryMode.tap;
    _amountKeypadOpen = widget.mode == QuickEntryMode.tap;

    if (widget.mode == QuickEntryMode.voice) {
      final ts = formatQuickEntryTimestamp(DateTime.now());
      _titleCtrl.text = "${AppLocalizations.vi.quickEntryVoice} - $ts";
    } else if (widget.mode == QuickEntryMode.receipt) {
      final ts = formatQuickEntryTimestamp(DateTime.now());
      _titleCtrl.text = "${AppLocalizations.vi.quickEntryReceipt} - $ts";
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _pickImage(
          AttachmentCapturePolicy.showReceiptCameraButton
              ? ImageSource.camera
              : ImageSource.gallery,
        );
      });
    }

    // Snapshot initial values so we can detect dirty state
    _initTitle = _titleCtrl.text;
    _initAmount = _amountKey;
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

  Future<void> _handleAudioChanged(
    AudioAttachmentModel? audio,
    List<LedgerCategory> cats,
  ) async {
    setState(() => _audio = audio);
    if (audio == null) return;
    await _maybeParseAiVoice(audio, cats);
  }

  Future<void> _maybeParseAiVoice(
    AudioAttachmentModel audio,
    List<LedgerCategory> cats,
  ) async {
    final prefs = ref.read(userPreferencesControllerProvider);
    if (!prefs.aiVoiceRecognitionEnabled) {
      debugPrint("[AI Voice Demo] quick parse skipped: feature off");
      return;
    }
    final endpoint = prefs.aiVoiceApiEndpoint;
    if (endpoint == null || endpoint.trim().isEmpty) {
      debugPrint("[AI Voice Demo] quick parse skipped: missing endpoint");
      showWarning(context, "Bạn cần cấu hình endpoint AI trong Profile trước.");
      return;
    }
    if (_aiParsing) {
      debugPrint("[AI Voice Demo] quick parse skipped: already parsing");
      return;
    }

    setState(() => _aiParsing = true);
    final client = VoiceTransactionDemoApiClient();
    try {
      final bytes = await _audioStorage.read(audio);
      debugPrint(
        "[AI Voice Demo] quick parse start "
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
        "[AI Voice Demo] quick parse success "
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
      debugPrint("[AI Voice Demo] quick parse failed: $error");
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
      setState(() => _validationError = error);
      return;
    }
    setState(() => _validationError = null);

    try {
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

      await ref
          .read(pwaInstallControllerProvider.notifier)
          .onFirstCompleteTransactionSaved(
            pending: _pending,
            complete: draft.complete,
          );
    } catch (_) {
      if (!mounted) return;
      showError(context, context.l10n.transactionSaveFailed);
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);
    showSuccess(
      context,
      _pending
          ? context.l10n.savePendingSuccess
          : context.l10n.saveTransactionSuccess,
    );
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

  // ── Main build ─────────────────────────────────────────────────────────────

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
        final prefs = ref.watch(userPreferencesControllerProvider);
        final showAiParseButton =
            _audio != null && prefs.aiVoiceRecognitionEnabled;

        return TransactionKeypadScaffold(
          keypadVisible: _amountKeypadOpen,
          keypad: _amountKeypad(),
          child: TransactionSheetScrollBody(
            compact: true,
            children: [
              TransactionSheetHeader(title: sheetTitle, onClose: _handleClose),
              const SizedBox(height: AppSpacing.sm),
              TransactionEntryForm(
                density: TransactionFormDensity.compact,
                initialAmount: _amountKey,
                noteController: _noteCtrl,
                isIncome: _income,
                onIncomeChanged: (income) => setState(() {
                  _income = income;
                  _categoryId = null;
                  if (_validationError ==
                      TransactionDraftValidationError.categoryRequired) {
                    _validationError = null;
                  }
                }),
                date: _date,
                onDateChanged: (d) => setState(() => _date = d),
                images: _images,
                onPickImage: _pickImage,
                onDeleteImage: _removeImage,
                audio: _audio,
                onAudioChanged: (audio) => _handleAudioChanged(audio, cats),
                voiceRecorderSessionId: _voiceRecorderSessionId,
                autoStartVoiceRecording: widget.mode == QuickEntryMode.voice,
                amountAlwaysShowKeypad: widget.mode == QuickEntryMode.tap,
                amountAutofocus: widget.mode == QuickEntryMode.tap,
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
                    labelText: context.l10n.titleOptional,
                  ),
                ),
                categorySection: TransactionCategorySection(
                  categories: cats,
                  includeSelectedFrom: cats,
                  isIncome: _income,
                  selectedId: _categoryId,
                  onSelected: (id) {
                    setState(() => _categoryId = id);
                    _clearValidation(
                      TransactionDraftValidationError.categoryRequired,
                    );
                  },
                  errorText:
                      _validationError ==
                          TransactionDraftValidationError.categoryRequired
                      ? _validationMessage(
                          TransactionDraftValidationError.categoryRequired,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TransactionPendingActionRow(
                pendingSwitch: TransactionPendingSwitch(
                  pending: _pending,
                  onChanged: (v) => setState(() => _pending = v),
                  subtitle: _hasMedia
                      ? context.l10n.pendingSubtitleWithMedia
                      : context.l10n.pendingSubtitleDefault,
                ),
                trailing: showAiParseButton
                    ? AiVoiceParseButton(
                        isLoading: _aiParsing,
                        onPressed: _audio == null
                            ? null
                            : () => _maybeParseAiVoice(_audio!, cats),
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppPrimaryButton(
                label: context.l10n.saveTransaction,
                icon: Icons.save_rounded,
                onPressed: _aiParsing ? null : () => _save(cats),
              ),
            ],
          ),
        );
      },
    );
  }
}
