import "dart:async";

import "package:flutter/material.dart";
import "package:just_audio/just_audio.dart";

import "package:smart_expense/features/transactions/data/attachments/voice_player_service.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({
    super.key,
    required this.audio,
    this.onError,
    this.compact = false,
  });

  final AudioAttachmentModel audio;
  final ValueChanged<String>? onError;
  final bool compact;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final _player = VoicePlayerService();
  final _subscriptions = <StreamSubscription<Object?>>[];

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listen();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant VoiceNotePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audio.id != widget.audio.id) {
      unawaited(_load());
    }
  }

  void _listen() {
    _subscriptions.add(
      _player.positionStream.listen((position) {
        if (mounted) setState(() => _position = position);
      }),
    );
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (mounted) {
          setState(() => _duration = duration ?? Duration.zero);
        }
      }),
    );
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() => _playing = state.playing);
        if (state.processingState == ProcessingState.completed) {
          unawaited(_player.seek(Duration.zero));
          unawaited(_player.pause());
        }
      }),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _position = Duration.zero;
      _duration = Duration.zero;
      _playing = false;
    });
    try {
      await _player.load(widget.audio);
    } catch (_) {
      _error = "Không thể phát ghi âm này.";
      widget.onError?.call(_error!);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle() async {
    if (_loading || _error != null) return;
    try {
      if (_playing) {
        await _player.pause();
      } else {
        if (_duration > Duration.zero && _position >= _duration) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (_) {
      widget.onError?.call("Không thể phát ghi âm này.");
    }
  }

  Future<void> _seek(double value) async {
    if (_duration == Duration.zero) return;
    final target = Duration(
      milliseconds: (_duration.inMilliseconds * value).round(),
    );
    await _player.seek(target);
  }

  Future<void> _stop() async {
    if (_loading || _error != null) return;
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, "0");
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, "0");
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    if (_error != null) {
      return Text(
        _error!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: cs.error,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: _loading ? null : _toggle,
          tooltip: _playing ? "Tạm dừng" : "Phát ghi âm",
          icon: _loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
        ),
        IconButton(
          onPressed: _loading || _position == Duration.zero ? null : _stop,
          tooltip: "Dừng",
          icon: const Icon(Icons.stop_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Slider(
                  value: progress,
                  onChanged: _loading ? null : _seek,
                ),
              ),
              if (!widget.compact)
                Text(
                  "${_format(_position)} / ${_duration == Duration.zero ? "--:--" : _format(_duration)}",
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
