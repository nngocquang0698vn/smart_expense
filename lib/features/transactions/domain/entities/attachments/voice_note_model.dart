import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";

class VoiceNoteModel {
  const VoiceNoteModel({required this.audio, required this.duration});

  final AudioAttachmentModel audio;
  final Duration duration;
}
