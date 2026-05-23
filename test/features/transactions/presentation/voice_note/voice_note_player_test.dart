import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/presentation/voice_note/widgets/voice_note_player.dart";

void main() {
  testWidgets("does not load or show spinner before play is tapped", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceNotePlayer(
            compact: true,
            audio: AudioAttachmentModel(
              id: "audio-1",
              durationMs: 18000,
              createdAt: DateTime(2024),
              mimeType: "audio/mpeg",
              extension: ".mp3",
              fileSize: 1024,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
