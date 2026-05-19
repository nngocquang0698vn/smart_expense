import "package:smart_expense/features/transactions/domain/entities/attachments/voice_note_model.dart";

abstract interface class VoiceRecorderRepository {
  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<void> cancel();
  Future<VoiceNoteModel> stop();
  Duration get elapsed;
  Future<void> dispose();
}
