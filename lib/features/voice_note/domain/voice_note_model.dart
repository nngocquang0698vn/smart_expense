import "audio_attachment_model.dart";

class VoiceNoteModel {
  const VoiceNoteModel({required this.audio, required this.duration});

  final AudioAttachmentModel audio;
  final Duration duration;
}
