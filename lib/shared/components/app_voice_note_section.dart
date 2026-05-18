import "package:flutter/material.dart";

import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/presentation/voice_note/widgets/voice_recorder_input.dart";

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
