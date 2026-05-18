// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import "dart:html" as html;
import "dart:typed_data";

Future<String> temporaryVoiceNotePath(String extension) async {
  final safeExt = extension.startsWith(".") ? extension : ".$extension";
  return "voice_note_${DateTime.now().microsecondsSinceEpoch}$safeExt";
}

Future<List<int>> readVoiceNoteBytes(String path) async {
  final request = await html.HttpRequest.request(
    path,
    responseType: "arraybuffer",
  );
  final buffer = request.response as ByteBuffer;
  return Uint8List.view(buffer);
}
