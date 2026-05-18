import "package:flutter/material.dart";

import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/voice_recording_status.dart";
import "package:smart_expense/features/transactions/presentation/voice_note/controllers/voice_recorder_controller.dart";
import "package:smart_expense/shared/dialogs/dialogs.dart";
import "package:smart_expense/features/transactions/presentation/voice_note/widgets/voice_note_preview.dart";

class VoiceRecorderInput extends StatefulWidget {
  const VoiceRecorderInput({
    super.key,
    this.audio,
    required this.onChanged,
    this.autoStartRecording = false,
    this.showWhenEmpty = true,
    this.maxRecordDuration = const Duration(minutes: 3),
  });

  final AudioAttachmentModel? audio;
  final ValueChanged<AudioAttachmentModel?> onChanged;
  final bool autoStartRecording;
  final bool showWhenEmpty;
  final Duration maxRecordDuration;

  @override
  State<VoiceRecorderInput> createState() => _VoiceRecorderInputState();
}

class _VoiceRecorderInputState extends State<VoiceRecorderInput> {
  late final VoiceRecorderController _controller;
  bool _autoStarted = false;
  bool _showPreviewActions = false;

  @override
  void initState() {
    super.initState();
    _controller = VoiceRecorderController(
      maxDuration: widget.maxRecordDuration,
    );
    if (widget.audio != null) {
      _controller.useExisting(widget.audio!);
    }
    if (widget.autoStartRecording) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoStart());
    }
  }

  @override
  void didUpdateWidget(covariant VoiceRecorderInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audio?.id != widget.audio?.id && widget.audio != null) {
      _controller.useExisting(widget.audio!);
    }
  }

  Future<void> _autoStart() async {
    if (_autoStarted || !mounted || widget.audio != null) {
      return;
    }
    _autoStarted = true;
    await _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, "0");
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, "0");
    return "$minutes:$seconds";
  }

  Future<void> _finish() async {
    final note = await _controller.finish();
    if (note != null) {
      widget.onChanged(note.audio);
      setState(() => _showPreviewActions = true);
    }
  }

  void _remove() {
    _controller.remove();
    widget.onChanged(null);
    _showPreviewActions = false;
  }

  Future<void> _confirmDelete() async {
    final ok = await showDeleteVoiceNoteDialog(context);
    if (ok) {
      _remove();
      _showMessage("Đã xoá ghi âm.");
    }
  }

  Future<void> _recordAgain() async {
    _remove();
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (!widget.showWhenEmpty &&
            _controller.status == VoiceRecordingStatus.idle &&
            _controller.voiceNote == null) {
          return const SizedBox.shrink();
        }

        final error = _controller.errorMessage;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _buildContent(error),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(String? error) {
    final status = _controller.status;
    final note = _controller.voiceNote;
    if (status == VoiceRecordingStatus.recording ||
        status == VoiceRecordingStatus.paused ||
        status == VoiceRecordingStatus.saving) {
      return _RecordingPanel(
        key: const ValueKey("recording"),
        status: status,
        elapsed: _controller.elapsed,
        format: _format,
        onPause: _controller.pause,
        onResume: _controller.resume,
        onCancel: () async {
          await _controller.cancel();
          widget.onChanged(null);
          _showMessage("Đã huỷ ghi âm.");
        },
        onFinish: _finish,
      );
    }

    if (note != null) {
      return VoiceNotePreview(
        key: const ValueKey("preview"),
        audio: note.audio,
        showActions: _showPreviewActions,
        onShowActions: () => setState(() => _showPreviewActions = true),
        onHideActions: () {
          if (_showPreviewActions && mounted) {
            setState(() => _showPreviewActions = false);
          }
        },
        onDelete: _confirmDelete,
        onRecordAgain: _recordAgain,
        onError: _showMessage,
      );
    }

    return _IdlePanel(
      key: const ValueKey("idle"),
      error: status == VoiceRecordingStatus.error ? error : null,
      onStart: _controller.start,
    );
  }
}

class _RoundBarIconButton extends StatelessWidget {
  const _RoundBarIconButton({
    required this.size,
    required this.iconSize,
    required this.onPressed,
    required this.tooltip,
    required this.iconData,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final double size;
  final double iconSize;
  final VoidCallback? onPressed;
  final String tooltip;
  final IconData iconData;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkResponse(
          onTap: onPressed,
          radius: size / 2,
          customBorder: const CircleBorder(),
          containedInkWell: true,
          child: SizedBox.square(
            dimension: size,
            child: Icon(iconData, size: iconSize, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}

class _IdlePanel extends StatelessWidget {
  const _IdlePanel({super.key, this.error, required this.onStart});

  final String? error;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.mic_none_rounded, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Ghi chú bằng giọng nói",
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton.filled(
              onPressed: onStart,
              tooltip: "Bắt đầu ghi âm",
              icon: const Icon(Icons.mic_rounded),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _RecordingPanel extends StatelessWidget {
  const _RecordingPanel({
    super.key,
    required this.status,
    required this.elapsed,
    required this.format,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onFinish,
  });

  final VoiceRecordingStatus status;
  final Duration elapsed;
  final String Function(Duration duration) format;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paused = status == VoiceRecordingStatus.paused;
    final saving = status == VoiceRecordingStatus.saving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: saving ? null : onCancel,
              tooltip: "Huỷ ghi âm",
              icon: const Icon(Icons.close_rounded, size: 18),
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                fixedSize: const Size.square(28),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _ScaledRecordingBar(
                elapsed: elapsed,
                paused: paused || saving,
                timerText: format(elapsed),
                onTogglePause: saving ? null : (paused ? onResume : onPause),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              onPressed: saving ? null : onFinish,
              tooltip: "Hoàn tất ghi âm",
              icon: saving
                  ? const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                fixedSize: const Size.square(28),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          paused ? "Đang tạm dừng ghi âm" : "Đang ghi âm",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: paused ? cs.onSurfaceVariant : cs.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ScaledRecordingBar extends StatelessWidget {
  const _ScaledRecordingBar({
    required this.elapsed,
    required this.paused,
    required this.timerText,
    required this.onTogglePause,
  });

  static const _loopDuration = Duration(seconds: 15);
  static const _baseHeight = 42.0;
  static const _scale = 24.0 / _baseHeight;
  static const _controlSize = 28.0;

  final Duration elapsed;
  final bool paused;
  final String timerText;
  final VoidCallback? onTogglePause;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress =
        (elapsed.inMilliseconds % _loopDuration.inMilliseconds) /
        _loopDuration.inMilliseconds;
    final trackHeight = _baseHeight * _scale;

    return SizedBox(
      height: _controlSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: trackHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: cs.primary.withValues(alpha: 0.16)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: ColoredBox(
                      color: cs.primary.withValues(alpha: paused ? 0.36 : 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _RoundBarIconButton(
                size: _controlSize,
                iconSize: 16,
                onPressed: onTogglePause,
                tooltip: paused ? "Tiếp tục ghi" : "Tạm dừng",
                iconData: paused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
              ),
              const Spacer(),
              _BarTimerChip(text: timerText, size: _controlSize),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarTimerChip extends StatelessWidget {
  const _BarTimerChip({required this.text, required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(cs.primaryContainer, cs.surface, 0.32)!,
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size, minWidth: size),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
