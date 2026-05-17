import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:intl/intl.dart";

import "../core/amount_input.dart";
import "../core/constants.dart";
import "../core/strings.dart";
import "../data/ledger_repository.dart";
import "../data/models/category_model.dart";
import "../data/models/transaction_model.dart";
import "../features/categories/application/category_selection_resolver.dart";
import "../features/image_attachment/data/image_picker_service.dart";
import "../features/image_attachment/data/image_storage_service.dart";
import "../features/image_attachment/domain/image_attachment_model.dart";
import "../features/image_attachment/presentation/widgets/image_attachment_list.dart";
import "../features/transactions/application/transaction_draft_validator.dart";
import "../features/voice_note/domain/audio_attachment_model.dart";
import "../shared/widgets/app_confirm_bottom_sheet.dart";
import "../shared/widgets/app_voice_note_section.dart";
import "../theme/app_finance_colors.dart";
import "app_text_field.dart";
import "form_amount_field.dart";

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
  final _titleCtrl = TextEditingController();
  final _amount = AmountInputController();
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
      _amount.value != _initAmount ||
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
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amount.setValue(e.amountVnd);
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
    _initAmount = _amount.value;
    _initNote = _noteCtrl.text;
    _initIncome = _income;
    _initCategoryId = _categoryId;
    _initDate = _date;
    _initPending = _pending;
    _initAudio = _audio;
    _initImageIds = _images.map((image) => image.id).toSet();

    // Rebuild on text changes so dirty flag updates
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
    if (discard == true) {
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
      ).showSnackBar(const SnackBar(content: Text(AppStrings.imageSaveFailed)));
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

  Future<void> _saveTransaction(List<CategoryModel> cats) async {
    final amount = _amount.value;
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
    final message = _firstDraftErrorMessage(draft.errors);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
    if (errors.contains(TransactionDraftValidationError.titleRequired)) {
      return AppStrings.titleRequired;
    }
    if (errors.contains(TransactionDraftValidationError.amountRequired)) {
      return AppStrings.amountRequired;
    }
    if (errors.contains(TransactionDraftValidationError.categoryRequired)) {
      return AppStrings.categoryRequired;
    }
    return null;
  }

  Future<void> _delete() async {
    final confirmed = await AppConfirmBottomSheet.show(
      context,
      title: AppStrings.deleteTransactionTitle,
      message: AppStrings.deleteTransactionMessage,
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await widget.repo.deleteTransaction(widget.existing!.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
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

        final hasImages = _images.isNotEmpty;
        final finance = context.financeColors;

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

                AppTextField(
                  controller: _titleCtrl,
                  labelText: AppStrings.transactionTitle,
                ),
                const SizedBox(height: 12),

                FormAmountField(controller: _amount),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.container),
                    color: finance.fieldFill,
                    border: Border.all(color: finance.fieldBorder),
                  ),
                  child: SegmentedButton<bool>(
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
                    onSelectionChanged: (s) {
                      setState(() {
                        _income = s.first;
                        final nextItems = _categorySelection.enabledForSide(
                          cats,
                          isIncome: _income,
                        );
                        _categoryId = _categorySelection.fallbackId(nextItems);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Category dropdown
                DropdownButtonFormField<String>(
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
                  decoration: const InputDecoration(
                    labelText: AppStrings.category,
                  ),
                ),
                const SizedBox(height: 12),

                // Date picker
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    side: BorderSide(color: finance.fieldBorder),
                  ),
                  tileColor: finance.fieldFill,
                  title: const Text(AppStrings.transactionDate),
                  subtitle: Text(DateFormat.yMMMd("vi").format(_date)),
                  trailing: Icon(
                    Icons.calendar_month,
                    color: finance.textMuted,
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                ),

                // Pending toggle — free to toggle for all transaction types
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: const Text(AppStrings.pending),
                  subtitle: const Text(
                    "Bật nếu cần xem lại giao dịch này sau.",
                  ),
                  value: _pending,
                  onChanged: (v) => setState(() => _pending = v),
                ),

                const SizedBox(height: 4),
                AppTextField(
                  controller: _noteCtrl,
                  labelText: AppStrings.note,
                  maxLines: 2,
                ),

                const SizedBox(height: 12),
                AppVoiceNoteSection(
                  audio: _audio,
                  showWhenEmpty: true,
                  onChanged: (audio) => setState(() {
                    _audio = audio;
                    if (audio != null) _pending = true;
                  }),
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    if (!kIsWeb) ...[
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

                // Image thumbnails
                if (hasImages) ...[
                  const SizedBox(height: 8),
                  ImageAttachmentList(
                    images: _images,
                    onDelete: _removeImage,
                    height: 96,
                  ),
                ],

                const SizedBox(height: 20),

                // ── Action buttons ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _saveTransaction(cats),
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text(AppStrings.save),
                  ),
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
