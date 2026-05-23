import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/application/voice_note/voice_recorder_config.dart";
import "package:smart_expense/features/transactions/application/voice_note/voice_recorder_controller.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/voice_recording_status.dart";
import "package:smart_expense/features/transactions/presentation/voice_note/widgets/voice_note_player.dart";
import "package:smart_expense/shared/components/app_discard_dialog.dart";
import "package:smart_expense/shared/components/app_notification.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Ghi chú văn bản + ghi âm trong một ô nhập duy nhất (icon micro bên phải).
class TransactionNoteInput extends ConsumerStatefulWidget {
  const TransactionNoteInput({
    required this.noteController,
    required this.onAudioChanged,
    this.audio,
    this.recorderSessionId,
    this.autoStartRecording = false,
    this.maxRecordDuration = const Duration(minutes: 3),
    this.amountKeypadOpen = false,
    this.onDismissAmountKeypad,
    super.key,
  });

  final TextEditingController noteController;
  final AudioAttachmentModel? audio;
  final ValueChanged<AudioAttachmentModel?> onAudioChanged;
  final Object? recorderSessionId;
  final bool autoStartRecording;
  final Duration maxRecordDuration;

  /// Bàn phím số tùy chỉnh đang mở (ẩn helper gợi ý micro).
  final bool amountKeypadOpen;

  /// Đóng keypad số khi người dùng chuyển sang gõ ghi chú.
  final VoidCallback? onDismissAmountKeypad;

  @override
  ConsumerState<TransactionNoteInput> createState() =>
      _TransactionNoteInputState();
}

class _TransactionNoteInputState extends ConsumerState<TransactionNoteInput> {
  static const _micTapSize = 44.0;

  late final Object _sessionId;
  final FocusNode _noteFocus = FocusNode();
  bool _autoStarted = false;
  bool _focusNoteAfterKeypadDismiss = false;
  bool _dismissingKeypadForNote = false;
  String? _lastShownError;

  VoiceRecorderConfig get _config => VoiceRecorderConfig(
    sessionId: _sessionId,
    maxDuration: widget.maxRecordDuration,
  );

  VoiceRecorderController get _controller =>
      ref.read(voiceRecorderControllerProvider(_config).notifier);

  @override
  void initState() {
    super.initState();
    _sessionId = widget.recorderSessionId ?? Object();
    _noteFocus.addListener(_onNoteFocusChanged);
    if (widget.audio != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.useExisting(widget.audio!);
      });
    }
    if (widget.autoStartRecording) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoStart());
    }
  }

  @override
  void didUpdateWidget(covariant TransactionNoteInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audio?.id != widget.audio?.id && widget.audio != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.useExisting(widget.audio!);
      });
    }
    if (oldWidget.amountKeypadOpen && !widget.amountKeypadOpen) {
      _refocusNoteAfterKeypadClosed();
    }
  }

  @override
  void dispose() {
    _noteFocus.removeListener(_onNoteFocusChanged);
    _noteFocus.dispose();
    super.dispose();
  }

  void _onNoteFocusChanged() {
    if (_noteFocus.hasFocus && widget.amountKeypadOpen) {
      _dismissKeypadForNote();
    }
  }

  void _ensureNoteFocused() {
    if (!_noteFocus.canRequestFocus) return;
    if (!_noteFocus.hasFocus) {
      _noteFocus.requestFocus();
    }
    if (kIsWeb) {
      SystemChannels.textInput.invokeMethod("TextInput.show");
    }
  }

  void _dismissKeypadForNote() {
    if (!widget.amountKeypadOpen || _dismissingKeypadForNote) return;
    _beginNoteFocusFromKeypad();
  }

  /// Web: focus trước, đóng keypad sau frame — tránh mất IME khi rebuild sheet.
  void _beginNoteFocusFromKeypad() {
    _dismissingKeypadForNote = true;
    _focusNoteAfterKeypadDismiss = true;

    _noteFocus.requestFocus();
    if (kIsWeb) {
      SystemChannels.textInput.invokeMethod("TextInput.show");
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _dismissingKeypadForNote = false;
        return;
      }
      if (widget.amountKeypadOpen) {
        widget.onDismissAmountKeypad?.call();
      } else {
        _dismissingKeypadForNote = false;
      }
    });
  }

  void _refocusNoteAfterKeypadClosed() {
    if (!_focusNoteAfterKeypadDismiss) return;
    _focusNoteAfterKeypadDismiss = false;
    _dismissingKeypadForNote = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureNoteFocused();
    });

    if (kIsWeb) {
      for (final delay in [
        AppDurations.fast,
        const Duration(milliseconds: 100),
      ]) {
        Future<void>.delayed(delay, () {
          if (mounted) _ensureNoteFocused();
        });
      }
    }
  }

  void _handleNotePointerDown(PointerDownEvent event) {
    if (!widget.amountKeypadOpen) return;
    _beginNoteFocusFromKeypad();
  }

  void _handleNoteTap() {
    if (widget.amountKeypadOpen) {
      if (!kIsWeb) _beginNoteFocusFromKeypad();
      return;
    }
    _ensureNoteFocused();
  }

  Future<void> _autoStart() async {
    if (_autoStarted || !mounted || widget.audio != null) return;
    _autoStarted = true;
    await _controller.start();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, "0");
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, "0");
    return "$minutes:$seconds";
  }

  Future<void> _finishRecording() async {
    final note = await _controller.finish();
    if (note != null && mounted) {
      widget.onAudioChanged(note.audio);
    }
  }

  Future<void> _onMicPressed(VoiceRecorderState recorderState) async {
    final status = recorderState.status;
    if (status == VoiceRecordingStatus.recording ||
        status == VoiceRecordingStatus.paused) {
      await _finishRecording();
      return;
    }

    final hasAudio = recorderState.voiceNote != null || widget.audio != null;
    if (hasAudio) {
      final replace = await showReplaceVoiceNoteDialog(context);
      if (!mounted || !replace) return;
      _controller.remove();
      widget.onAudioChanged(null);
    }

    await _controller.start();
  }

  void _handleRecorderError(String? message) {
    if (message == null || message.isEmpty || !mounted) return;
    if (_lastShownError == message) return;
    _lastShownError = message;
    showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final recorderState = ref.watch(voiceRecorderControllerProvider(_config));

    ref.listen<VoiceRecorderState>(voiceRecorderControllerProvider(_config), (
      previous,
      next,
    ) {
      if (next.status == VoiceRecordingStatus.error &&
          next.errorMessage != null) {
        _handleRecorderError(next.errorMessage);
      }
    });

    final status = recorderState.status;
    final isRecording = status == VoiceRecordingStatus.recording;
    final isPaused = status == VoiceRecordingStatus.paused;
    final isSaving = status == VoiceRecordingStatus.saving;
    final isActiveRecording = isRecording || isPaused || isSaving;

    final attached = recorderState.voiceNote?.audio ?? widget.audio;
    final systemKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showNoteHelper =
        !isActiveRecording &&
        attached == null &&
        !widget.amountKeypadOpen &&
        !_noteFocus.hasFocus &&
        !systemKeyboardVisible;

    final borderColor = isActiveRecording ? cs.primary : finance.fieldBorder;
    final borderWidth = isActiveRecording ? 2.0 : 1.0;

    final micTooltip = isActiveRecording
        ? l10n.micStopRecording
        : (attached != null ? l10n.micRecordAgain : l10n.micRecordNote);

    final micIcon = isActiveRecording ? Icons.stop_rounded : Icons.mic_rounded;
    final micColor = isActiveRecording ? cs.error : cs.primary;
    final micBackground = isActiveRecording
        ? cs.error.withValues(alpha: 0.12)
        : cs.primary.withValues(alpha: 0.12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: finance.fieldFill,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.xxs,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Icon(
                        Icons.edit_note_rounded,
                        size: 22,
                        color: finance.textHint,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: _handleNotePointerDown,
                        child: TextField(
                          key: const Key("transaction_note_field"),
                          controller: widget.noteController,
                          focusNode: _noteFocus,
                          onTap: _handleNoteTap,
                          maxLines: 3,
                          minLines: 1,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: finance.fieldText,
                                fontWeight: FontWeight.w500,
                              ),
                          cursorColor: cs.primary,
                          decoration: InputDecoration(
                            hintText: l10n.noteOptional,
                            hintStyle: TextStyle(color: finance.textHint),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: micTooltip,
                      child: Tooltip(
                        message: micTooltip,
                        child: Material(
                          color: micBackground,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: isSaving
                                ? null
                                : () => _onMicPressed(recorderState),
                            child: SizedBox.square(
                              dimension: _micTapSize,
                              child: isSaving
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cs.primary,
                                      ),
                                    )
                                  : Icon(micIcon, color: micColor, size: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isActiveRecording) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _CompactLoopProgressBar(
                    elapsed: recorderState.elapsed,
                    paused: isPaused || isSaving,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  _RecordingStatusRow(
                    elapsedText: _formatDuration(recorderState.elapsed),
                    paused: isPaused,
                    saving: isSaving,
                    savingLabel: l10n.voiceNoteSaving,
                    recordingLabel: l10n.voiceNoteRecording,
                    pausedLabel: l10n.voiceNotePaused,
                  ),
                ] else if (attached != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _AudioPlaybackSection(
                    audio: attached,
                    onRemove: () async {
                      final ok = await showDeleteVoiceNoteDialog(context);
                      if (!mounted || !ok) return;
                      _controller.remove();
                      widget.onAudioChanged(null);
                      if (!context.mounted) return;
                      showInfo(context, l10n.voiceNoteDeleted);
                    },
                    onPlaybackError: (message) {
                      if (!mounted) return;
                      showError(context, message);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showNoteHelper) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.noteVoiceHelper,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: finance.textHint,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

/// Thanh tiến trình 15s lặp (giống implementation cũ, chiều cao gọn).
class _CompactLoopProgressBar extends StatelessWidget {
  const _CompactLoopProgressBar({required this.elapsed, required this.paused});

  static const _loopDuration = Duration(seconds: 15);
  static const _barHeight = 8.0;

  final Duration elapsed;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress =
        (elapsed.inMilliseconds % _loopDuration.inMilliseconds) /
        _loopDuration.inMilliseconds;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: _barHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: cs.primary.withValues(alpha: 0.14)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: ColoredBox(
                color: cs.primary.withValues(alpha: paused ? 0.35 : 0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingStatusRow extends StatelessWidget {
  const _RecordingStatusRow({
    required this.elapsedText,
    required this.paused,
    required this.saving,
    required this.savingLabel,
    required this.recordingLabel,
    required this.pausedLabel,
  });

  final String elapsedText;
  final bool paused;
  final bool saving;
  final String savingLabel;
  final String recordingLabel;
  final String pausedLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = saving
        ? savingLabel
        : (paused ? pausedLabel : recordingLabel);

    return Row(
      children: [
        Icon(
          Icons.fiber_manual_record_rounded,
          size: 10,
          color: paused ? cs.onSurfaceVariant : cs.error,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: paused ? cs.onSurfaceVariant : cs.primary,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          elapsedText,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _AudioPlaybackSection extends StatelessWidget {
  const _AudioPlaybackSection({
    required this.audio,
    required this.onRemove,
    required this.onPlaybackError,
  });

  final AudioAttachmentModel audio;
  final VoidCallback onRemove;
  final ValueChanged<String> onPlaybackError;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 16, color: cs.primary),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Text(
                l10n.voiceNoteRecorded,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: finance.fieldText,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: l10n.deleteVoiceNote,
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: Icon(Icons.close_rounded, color: finance.textHint),
            ),
          ],
        ),
        VoiceNotePlayer(audio: audio, compact: true, onError: onPlaybackError),
      ],
    );
  }
}
