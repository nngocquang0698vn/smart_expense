import "package:flutter/material.dart";

import "../../features/voice_note/domain/audio_attachment_model.dart";
import "../../features/voice_note/presentation/widgets/voice_note_player.dart";
import "../../features/voice_note/presentation/widgets/voice_recorder_input.dart";

class AppVoiceNoteSection extends StatelessWidget {
  const AppVoiceNoteSection({
    super.key,
    this.audio,
    required this.onChanged,
    this.maxRecordDuration = const Duration(minutes: 3),
    this.showWhenEmpty = true,
    this.autoStartRecording = false,
  });

  final AudioAttachmentModel? audio;
  final ValueChanged<AudioAttachmentModel?> onChanged;
  final Duration maxRecordDuration;
  final bool showWhenEmpty;
  final bool autoStartRecording;

  @override
  Widget build(BuildContext context) {
    return VoiceRecorderInput(
      audio: audio,
      onChanged: onChanged,
      maxRecordDuration: maxRecordDuration,
      showWhenEmpty: showWhenEmpty,
      autoStartRecording: autoStartRecording,
    );
  }
}

class AppVoiceNotePlayback extends StatelessWidget {
  const AppVoiceNotePlayback({super.key, required this.audio});

  final AudioAttachmentModel audio;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: VoiceNotePlayer(
          audio: audio,
          onError: (message) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message))),
        ),
      ),
    );
  }
}
