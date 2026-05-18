// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import "dart:html" as html;
import "dart:typed_data";

import "package:smart_expense/features/transactions/data/attachments/voice_playback_source_service.dart";

Future<VoicePlaybackSource> createVoicePlaybackSource(
  List<int> bytes, {
  required String contentType,
}) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], contentType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  return VoicePlaybackSource.url(url);
}

Future<void> releaseVoicePlaybackSource(VoicePlaybackSource? source) async {
  if (source == null || source.isFile) return;
  html.Url.revokeObjectUrl(source.value);
}
