import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:audioplayers/audioplayers.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:image_picker/image_picker.dart";
import "package:intl/intl.dart";
import "package:record/record.dart";

import "../core/constants.dart";
import "../core/strings.dart";
import "../data/ledger_repository.dart";
import "../data/models/category_model.dart";

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
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool _income = false;
  bool _pending = false;
  DateTime _date = DateTime.now();
  String? _categoryId;

  // Snapshots for dirty detection
  late String _initTitle;
  late String _initAmount;

  // Audio
  final _recorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  StreamSubscription<Uint8List>? _recordSub;
  Timer? _recordTimer;
  final List<int> _recordBytes = [];
  bool _recording = false;
  Duration _recordDuration = Duration.zero;
  bool _microDenied = false;
  String? _audioBase64;

  // Images
  final _imageBase64List = <String>[];
  final _picker = ImagePicker();

  bool get _hasMedia => _audioBase64 != null || _imageBase64List.isNotEmpty;

  // Camera available on native platforms only
  bool get _showCamera => !kIsWeb;

  bool get _isDirty =>
      _titleCtrl.text != _initTitle ||
      _amountCtrl.text != _initAmount ||
      _noteCtrl.text.isNotEmpty ||
      _audioBase64 != null ||
      _imageBase64List.isNotEmpty ||
      _recording;

  @override
  void initState() {
    super.initState();
    _pending = widget.mode != QuickEntryMode.tap;

    if (widget.mode == QuickEntryMode.voice) {
      final ts = DateFormat("dd/MM HH:mm").format(DateTime.now());
      _titleCtrl.text = "Ghi âm giao dịch - $ts";
      _amountCtrl.text = "0";
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) await _startRecording();
      });
    } else if (widget.mode == QuickEntryMode.receipt) {
      final ts = DateFormat("dd/MM HH:mm").format(DateTime.now());
      _titleCtrl.text = "Ảnh hoá đơn - $ts";
      _amountCtrl.text = "0";
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _pickImage(
          _showCamera ? ImageSource.camera : ImageSource.gallery,
        );
      });
    }

    // Snapshot initial values so we can detect dirty state
    _initTitle = _titleCtrl.text;
    _initAmount = _amountCtrl.text;

    _titleCtrl.addListener(() => setState(() {}));
    _amountCtrl.addListener(() => setState(() {}));
    _noteCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recordSub?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
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

  // ── Audio recording ────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final granted = await _recorder.hasPermission();
    if (!granted) {
      if (!mounted) return;
      setState(() => _microDenied = true);
      return;
    }
    setState(() => _microDenied = false);

    await _recordSub?.cancel();
    _recordSub = null;
    _recordTimer?.cancel();
    _recordBytes.clear();
    _recordDuration = Duration.zero;
    _audioBase64 = null;

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    _recordSub = stream.listen((chunk) => _recordBytes.addAll(chunk));
    _recordTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _recordDuration += const Duration(seconds: 1)),
    );
    if (!mounted) return;
    setState(() => _recording = true);
  }

  Future<void> _stopRecording() async {
    await _recordSub?.cancel();
    _recordSub = null;
    _recordTimer?.cancel();
    _recordTimer = null;
    await _recorder.stop();
    if (_recordBytes.isEmpty) {
      setState(() => _recording = false);
      return;
    }
    final wav = _pcm16ToWav(Uint8List.fromList(_recordBytes));
    setState(() {
      _recording = false;
      _audioBase64 = base64Encode(wav);
      _pending = true;
    });
  }

  Future<void> _playAudio() async {
    if (_audioBase64 == null) return;
    await _audioPlayer.stop();
    await _audioPlayer.play(BytesSource(base64Decode(_audioBase64!)));
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

  Future<void> _save(List<CategoryModel> cats, {required bool confirm}) async {
    final title = _titleCtrl.text.trim().isEmpty
        ? (_income ? "Thu nhập nhanh" : "Chi tiêu nhanh")
        : _titleCtrl.text.trim();

    final raw = _amountCtrl.text.replaceAll(RegExp(r"[^\d]"), "");
    final amount = int.tryParse(raw) ?? 0;

    // "confirm" forces pending=false only for voice/receipt modes.
    // In tap mode, always respect the user's pending toggle.
    final effectivePending = (widget.mode != QuickEntryMode.tap && confirm)
        ? false
        : _pending;

    // Require amount > 0 only when not pending (confirmed to history).
    if (!effectivePending && amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập số tiền hợp lệ.")),
      );
      return;
    }

    final matched = cats.where((c) => c.isIncome == _income).toList();
    final catId =
        _categoryId ?? (matched.isNotEmpty ? matched.first.id : null);
    if (!effectivePending && catId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn danh mục.")),
      );
      return;
    }

    if (_recording) await _stopRecording();
    if (!mounted) return;

    // A pending transaction is "complete" (ready for one-tap confirm) when it
    // already has both a valid amount and a category.
    final isInfoComplete = amount > 0 && catId != null;
    final effectiveComplete = effectivePending ? isInfoComplete : true;

    await widget.repo.addQuick(
      title: title,
      amountVnd: amount,
      isIncome: _income,
      categoryId: catId ?? (matched.isNotEmpty ? matched.first.id : ""),
      at: _date,
      pending: effectivePending,
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
          effectivePending
              ? "Đã lưu vào danh sách chờ đối soát."
              : "Đã xác nhận và lưu giao dịch.",
        ),
      ),
    );
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  String _fmtDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, "0");
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, "0");
    return "$mm:$ss";
  }

  Widget _buildAudioSection() {
    if (_microDenied) {
      final cs = Theme.of(context).colorScheme;
      return Card(
        color: cs.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(Icons.mic_off, color: cs.onErrorContainer, size: 32),
              const SizedBox(height: 6),
              Text(
                "Không thể truy cập Micro",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.onErrorContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Kiểm tra lại quyền truy cập trong trình duyệt / thiết bị.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: cs.onErrorContainer),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _startRecording,
                child: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          children: [
            _WaveBars(active: _recording),
            const SizedBox(height: 6),
            Text(
              _fmtDuration(_recordDuration),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
            Text(
              _recording
                  ? "Đang ghi âm..."
                  : (_audioBase64 != null
                      ? "Ghi âm thành công"
                      : "Sẵn sàng ghi âm"),
              style: TextStyle(fontSize: 12, color: cs.primary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_audioBase64 != null && !_recording) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _audioBase64 = null;
                          _recordDuration = Duration.zero;
                        });
                        await _startRecording();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text(AppStrings.reRecord),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _recording
                        ? _stopRecording
                        : (_audioBase64 == null ? _startRecording : _playAudio),
                    icon: Icon(
                      _recording
                          ? Icons.stop
                          : (_audioBase64 == null
                              ? Icons.mic
                              : Icons.play_arrow),
                      size: 16,
                    ),
                    label: Text(
                      _recording
                          ? AppStrings.stopRecording
                          : (_audioBase64 == null
                              ? AppStrings.startRecording
                              : AppStrings.playBack),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Main build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
      future: widget.repo
          .categories()
          .then((list) => list.where((c) => c.enabled).toList()),
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
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.container),
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text(AppStrings.expense)),
                      ButtonSegment(value: true, label: Text(AppStrings.income)),
                    ],
                    selected: {_income},
                    onSelectionChanged: (v) => setState(() {
                      _income = v.first;
                      _categoryId = null;
                    }),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Amount — large & prominent ─────────────────────────────
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  decoration: const InputDecoration(
                    prefixText: "₫ ",
                    hintText: "0",
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Title ─────────────────────────────────────────────────
                TextField(
                  controller: _titleCtrl,
                  decoration:
                      const InputDecoration(labelText: "Tiêu đề (tuỳ chọn)"),
                ),
                const SizedBox(height: 14),

                // ── Audio section ─────────────────────────────────────────
                if (widget.mode == QuickEntryMode.voice ||
                    _audioBase64 != null ||
                    _recording) ...[
                  _buildAudioSection(),
                  const SizedBox(height: 14),
                ],

                // ── Category chips (compact, shows all categories) ────────
                Text(
                  "Danh mục",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (ctx) {
                    final cs = Theme.of(ctx).colorScheme;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cats
                          .where((c) => c.isIncome == _income)
                          .map((cat) {
                        final active = cat.id == _categoryId;
                        return GestureDetector(
                          onTap: () => setState(() => _categoryId = cat.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  active ? cs.primary : cs.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? cs.primary
                                    : cs.outlineVariant,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  size: 16,
                                  color:
                                      active ? cs.onPrimary : cat.color,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? cs.onPrimary
                                        : cs.onSurface,
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
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
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
                          icon: const Icon(Icons.photo_camera_outlined,
                              size: 16),
                          label: const Text(AppStrings.takePhoto),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined,
                            size: 16),
                        label: const Text(AppStrings.pickPhoto),
                      ),
                    ),
                    if (widget.mode != QuickEntryMode.voice) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed:
                            _recording ? _stopRecording : _startRecording,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _recording ? Colors.red : null,
                          side: BorderSide(
                            color: _recording
                                ? Colors.red
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Icon(
                          _recording ? Icons.stop : Icons.mic,
                          size: 20,
                        ),
                      ),
                    ],
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
                              onTap: () => setState(
                                  () => _imageBase64List.removeAt(i)),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
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
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Ghi chú (tuỳ chọn)",
                  ),
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
                // Tap mode: single save button (always confirmed, no draft)
                // Voice/Receipt: two buttons (confirm vs save as draft)
                if (widget.mode == QuickEntryMode.tap)
                  FilledButton(
                    // confirm: !_pending — when pending toggle is ON, don't
                    // force-confirm; let _save respect the toggle.
                    onPressed: () => _save(cats, confirm: !_pending),
                    child: const Text("Lưu giao dịch"),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: () => _save(cats, confirm: true),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text("Lưu & Xác nhận đủ thông tin"),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _save(cats, confirm: false),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text("Lưu (chờ đối soát)"),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── PCM → WAV helpers ──────────────────────────────────────────────────────

  Uint8List _pcm16ToWav(
    Uint8List pcm, {
    int sampleRate = 16000,
    int channels = 1,
    int bitsPerSample = 16,
  }) {
    final dataLength = pcm.length;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final fileSize = 36 + dataLength;

    final out = BytesBuilder();
    out.add(ascii.encode("RIFF"));
    out.add(_le32(fileSize));
    out.add(ascii.encode("WAVE"));
    out.add(ascii.encode("fmt "));
    out.add(_le32(16));
    out.add(_le16(1));
    out.add(_le16(channels));
    out.add(_le32(sampleRate));
    out.add(_le32(byteRate));
    out.add(_le16(blockAlign));
    out.add(_le16(bitsPerSample));
    out.add(ascii.encode("data"));
    out.add(_le32(dataLength));
    out.add(pcm);
    return out.takeBytes();
  }

  List<int> _le16(int v) => [v & 0xff, (v >> 8) & 0xff];

  List<int> _le32(int v) => [
        v & 0xff,
        (v >> 8) & 0xff,
        (v >> 16) & 0xff,
        (v >> 24) & 0xff,
      ];
}

// ── Simple wave-bar visual indicator ─────────────────────────────────────────

class _WaveBars extends StatelessWidget {
  const _WaveBars({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const heights = [10.0, 18.0, 28.0, 40.0, 32.0, 24.0, 36.0, 20.0, 14.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final h in heights)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 6,
            height: h,
            decoration: BoxDecoration(
              color: active ? cs.primary : cs.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}
