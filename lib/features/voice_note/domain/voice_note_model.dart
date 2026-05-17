class VoiceNoteModel {
  const VoiceNoteModel({
    required this.audioBase64,
    required this.duration,
    this.localPath,
  });

  final String audioBase64;
  final Duration duration;
  final String? localPath;
}
