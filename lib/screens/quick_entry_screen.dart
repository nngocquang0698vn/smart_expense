import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:intl/intl.dart";

import "../core/amount_input.dart";
import "../core/constants.dart";
import "../data/ledger_repository.dart";
import "../data/models/category_model.dart";
import "../shared/widgets/app_voice_note_section.dart";
import "../theme/app_finance_colors.dart";
import "../widgets/app_text_field.dart";
import "../widgets/form_amount_field.dart";

enum QuickEntryStartMode { tap, voice, receipt }

enum _EntryStep { amount, details, media, notePending }

class QuickEntryScreen extends StatefulWidget {
  const QuickEntryScreen({
    super.key,
    required this.repo,
    this.startMode = QuickEntryStartMode.tap,
  });

  final LedgerRepository repo;
  final QuickEntryStartMode startMode;

  @override
  State<QuickEntryScreen> createState() => _QuickEntryScreenState();
}

class _QuickEntryScreenState extends State<QuickEntryScreen> {
  final _titleCtrl = TextEditingController();
  final _amount = AmountInputController();
  final _noteCtrl = TextEditingController();
  final _picker = ImagePicker();

  bool _income = false;
  bool _pending = false;
  DateTime _date = DateTime.now();
  String? _categoryId;
  String? _audioBase64;
  final List<String> _imageBase64List = [];
  _EntryStep _step = _EntryStep.amount;

  bool get _isLaptop {
    final width = MediaQuery.sizeOf(context).width;
    return kIsWeb || width >= 1000;
  }

  bool get _hasMedia => _audioBase64 != null || _imageBase64List.isNotEmpty;

  bool get _isDirty =>
      _titleCtrl.text.trim().isNotEmpty ||
      _amount.value > 0 ||
      _noteCtrl.text.trim().isNotEmpty ||
      _audioBase64 != null ||
      _imageBase64List.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
    _pending = widget.startMode != QuickEntryStartMode.tap;
    if (widget.startMode == QuickEntryStartMode.receipt) {
      _step = _EntryStep.media;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (widget.startMode == QuickEntryStartMode.receipt && !_isLaptop) {
        await _pickImage(ImageSource.camera);
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amount.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<bool> _confirmExit() async {
    if (!_isDirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Thoát luồng nhập liệu?"),
        content: const Text(
          "Dữ liệu sẽ bị mất. Bạn có chắc chắn muốn thoát không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Ở lại"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Thoát"),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _handleBack() async {
    final ok = await _confirmExit();
    if (!mounted || !ok) return;
    Navigator.pop(context);
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBase64List.add(base64Encode(bytes));
      _pending = true;
    });
  }

  bool _next(List<CategoryModel> all) {
    switch (_step) {
      case _EntryStep.amount:
        final amount = _amount.value;
        if (amount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vui lòng nhập số tiền hợp lệ.")),
          );
          return false;
        }
        _step = _EntryStep.details;
        return true;
      case _EntryStep.details:
        final options = all.where((c) => c.isIncome == _income).toList();
        if ((_categoryId ?? "").isEmpty && options.isNotEmpty) {
          _categoryId = options.first.id;
        }
        if (_categoryId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vui lòng chọn danh mục.")),
          );
          return false;
        }
        _step = _EntryStep.media;
        return true;
      case _EntryStep.media:
        if (widget.startMode == QuickEntryStartMode.receipt &&
            _imageBase64List.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bạn cần ảnh hoá đơn để tiếp tục.")),
          );
          return false;
        }
        _step = _EntryStep.notePending;
        return true;
      case _EntryStep.notePending:
        return true;
    }
  }

  Future<void> _save(List<CategoryModel> all) async {
    final amount = _amount.value;
    if (amount <= 0) return;
    final matched = all.where((c) => c.isIncome == _income).toList();
    final selected =
        _categoryId ?? (matched.isNotEmpty ? matched.first.id : null);
    if (selected == null) return;

    await widget.repo.addQuick(
      title: _titleCtrl.text.trim().isEmpty
          ? (_income ? "Thu nhập nhanh" : "Chi tiêu nhanh")
          : _titleCtrl.text.trim(),
      amountVnd: amount,
      isIncome: _income,
      categoryId: selected,
      at: _date,
      pending: _pending,
      complete: !_pending,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      audioBase64: _audioBase64,
      imageBase64List: _imageBase64List,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Đã lưu giao dịch.")));
  }

  Future<void> _saveVoiceOnly(List<CategoryModel> all) async {
    if (_audioBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn cần ghi âm trước khi xác nhận.")),
      );
      return;
    }
    final expense = all.firstWhere((c) => !c.isIncome, orElse: () => all.first);
    await widget.repo.addQuick(
      title: "Ghi âm giao dịch",
      amountVnd: 1,
      isIncome: false,
      categoryId: expense.id,
      pending: true,
      complete: false,
      audioBase64: _audioBase64,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã lưu bản ghi âm chờ đối soát.")),
    );
  }

  Widget _row(String k, String v) {
    final muted = context.financeColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(k, style: TextStyle(color: muted)),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _stepPopup(List<CategoryModel> all) {
    final cats = all.where((c) => c.isIncome == _income).take(8).toList();
    _categoryId ??= cats.isNotEmpty ? cats.first.id : null;
    final cs = Theme.of(context).colorScheme;

    Widget body = const SizedBox.shrink();
    if (_step == _EntryStep.amount) {
      body = Column(
        key: const ValueKey("amount"),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Nhập nhanh",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.container),
              color: context.financeColors.fieldFill,
              border: Border.all(color: context.financeColors.fieldBorder),
            ),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text("Chi tiêu")),
                ButtonSegment(value: true, label: Text("Thu nhập")),
              ],
              selected: {_income},
              onSelectionChanged: (v) => setState(() => _income = v.first),
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _titleCtrl, labelText: "Tiêu đề"),
          const SizedBox(height: 12),
          FormAmountField(
            controller: _amount,
            alwaysShowKeypad: widget.startMode == QuickEntryStartMode.tap,
            autofocus: widget.startMode == QuickEntryStartMode.tap,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      );
    } else if (_step == _EntryStep.details) {
      body = Column(
        key: const ValueKey("details"),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Thông tin giao dịch",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today_rounded),
              title: Text(DateFormat("dd/MM/yyyy").format(_date)),
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
          const SizedBox(height: 8),
          Text(
            "Danh mục phổ biến",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final cat = cats[index];
              final active = cat.id == _categoryId;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _categoryId = cat.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: active
                        ? cs.primary
                        : context.financeColors.fieldFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active
                          ? cs.primary
                          : context.financeColors.fieldBorder,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat.icon, color: active ? cs.onPrimary : cat.color),
                      const SizedBox(height: 6),
                      Text(
                        cat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active ? cs.onPrimary : cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    } else if (_step == _EntryStep.media) {
      body = Column(
        key: const ValueKey("media"),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Ghi chú và đính kèm",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _noteCtrl,
            maxLines: 2,
            labelText: "Ghi chú (tuỳ chọn)",
          ),
          const SizedBox(height: 10),
          AppVoiceNoteSection(
            audioBase64: _audioBase64,
            onChanged: (b64) => setState(() {
              _audioBase64 = b64;
              if (b64 != null) _pending = true;
            }),
            maxRecordDuration: const Duration(minutes: 3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!_isLaptop)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text("Chụp ảnh"),
                  ),
                ),
              if (!_isLaptop) const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text("Chọn ảnh"),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (_step == _EntryStep.notePending) {
      body = Column(
        key: const ValueKey("note_pending"),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Ghi chú và đối soát",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _noteCtrl,
            maxLines: 3,
            labelText: "Ghi chú (tuỳ chọn)",
          ),
          const SizedBox(height: 12),
          _row("Loại", _income ? "Thu nhập" : "Chi tiêu"),
          _row("Số tiền", "₫ ${_amount.displayText}"),
          _row("Ngày", DateFormat("dd/MM/yyyy").format(_date)),
          _row("Audio", _audioBase64 != null ? "Có" : "Không"),
          _row(
            "Ảnh",
            _imageBase64List.isEmpty
                ? "Không"
                : "${_imageBase64List.length} ảnh",
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Cần đối soát"),
            subtitle: Text(
              _hasMedia
                  ? "Có audio/ảnh thì luôn cần đối soát."
                  : "Bật nếu muốn chuyển vào danh sách đối soát.",
            ),
            value: _pending,
            onChanged: (v) {
              if (_hasMedia && !v) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Có media thì bắt buộc cần đối soát."),
                  ),
                );
                return;
              }
              setState(() => _pending = v);
            },
          ),
        ],
      );
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: body,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_step != _EntryStep.amount)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _step = _EntryStep.values[_step.index - 1];
                                });
                              },
                              child: const Text("Quay lại"),
                            ),
                          ),
                        if (_step != _EntryStep.amount)
                          const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              if (_step == _EntryStep.notePending) {
                                await _save(all);
                                return;
                              }
                              final ok = _next(all);
                              if (!ok || !mounted) return;
                              setState(() {});
                            },
                            child: Text(
                              _step == _EntryStep.notePending
                                  ? "Lưu giao dịch"
                                  : "Tiếp tục",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _voiceFlow(List<CategoryModel> all) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: AppVoiceNoteSection(
                      audioBase64: _audioBase64,
                      autoStartRecording: true,
                      onChanged: (b64) => setState(() {
                        _audioBase64 = b64;
                        if (b64 != null) _pending = true;
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: () => _saveVoiceOnly(all),
                  child: const Text("Xác nhận đối soát"),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _step = _EntryStep.amount);
                  },
                  icon: const Icon(Icons.touch_app),
                  label: const Text("Chuyển sang Chạm để nhập"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
      future: widget.repo.categories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final all = snapshot.data!;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _handleBack();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                widget.startMode == QuickEntryStartMode.voice
                    ? "Ghi âm giao dịch"
                    : "Nhập nhanh",
              ),
              leading: IconButton(
                onPressed: _handleBack,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            body: widget.startMode == QuickEntryStartMode.voice
                ? _voiceFlow(all)
                : _stepPopup(all),
          ),
        );
      },
    );
  }
}
