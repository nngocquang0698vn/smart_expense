import "package:flutter/material.dart";

import "../../features/voice_note/domain/audio_attachment_model.dart";
import "../../features/voice_note/presentation/widgets/voice_note_player.dart";

class AppAudioPlayer extends StatelessWidget {
  const AppAudioPlayer({super.key, required this.audio, this.onError});

  final AudioAttachmentModel audio;
  final void Function(String message)? onError;

  @override
  Widget build(BuildContext context) {
    return VoiceNotePlayer(audio: audio, onError: onError);
  }
}
