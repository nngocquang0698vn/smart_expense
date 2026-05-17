import "package:flutter/material.dart";

import "../../features/voice_note/presentation/widgets/voice_note_player.dart";

class AppAudioPlayer extends StatelessWidget {
  const AppAudioPlayer({super.key, required this.audioBase64, this.onError});

  final String audioBase64;
  final void Function(String message)? onError;

  @override
  Widget build(BuildContext context) {
    return VoiceNotePlayer(audioBase64: audioBase64, onError: onError);
  }
}
