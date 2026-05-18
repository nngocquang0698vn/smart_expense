import "dart:io";

import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";

Future<String> temporaryVoiceNotePath(String extension) async {
  final dir = await getTemporaryDirectory();
  final safeExt = extension.startsWith(".") ? extension : ".$extension";
  final stamp = DateTime.now().microsecondsSinceEpoch;
  return p.join(dir.path, "voice_note_$stamp$safeExt");
}

Future<List<int>> readVoiceNoteBytes(String path) {
  return File(path).readAsBytes();
}
