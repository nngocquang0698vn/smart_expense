import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/app/theme/theme_settings.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/voice_note_model.dart";
import "package:smart_expense/features/transactions/domain/repositories/voice_recorder_repository.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_note_input.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_sheet_shell.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";

/// Regression: một tap ghi chú khi keypad mở → đóng keypad + gõ được; không khoảng trắng.
void main() {
  testWidgets(
    "one tap on note dismisses keypad, keeps focus, and accepts text",
    (tester) async {
      final noteCtrl = TextEditingController();
      var keypadVisible = true;
      final recorder = _FakeVoiceRecorderRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecorderRepositoryProvider.overrideWith(
              (ref, config) => recorder,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.build(
              const ThemeSettings(),
              brightness: Brightness.light,
            ),
            locale: const Locale("vi", "VN"),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: const MediaQueryData(size: Size(400, 800)),
              child: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) {
                    return TransactionKeypadScaffold(
                      keypadVisible: keypadVisible,
                      keypad: SizedBox(
                        height: kTransactionKeypadHeight,
                        child: const Center(child: Text("amount keypad")),
                      ),
                      child: TransactionSheetScrollBody(
                        children: [
                          TransactionNoteInput(
                            noteController: noteCtrl,
                            amountKeypadOpen: keypadVisible,
                            onDismissAmountKeypad: () {
                              if (keypadVisible) {
                                setState(() => keypadVisible = false);
                              }
                            },
                            onAudioChanged: (_) {},
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text("amount keypad"), findsOneWidget);

      final noteField = find.byKey(const Key("transaction_note_field"));
      await tester.tap(noteField);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(_keypadOpacity(tester), 0);

      await tester.enterText(noteField, "Trà sữa");
      await tester.pump();

      expect(noteCtrl.text, "Trà sữa");
    },
  );

  testWidgets(
    "after keypad dismisses expanded sheet height constraint is removed",
    (tester) async {
      var keypadVisible = true;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return TransactionKeypadScaffold(
                    keypadVisible: keypadVisible,
                    keypad: SizedBox(
                      height: kTransactionKeypadHeight,
                      child: const Center(child: Text("amount keypad")),
                    ),
                    child: TransactionSheetScrollBody(
                      children: [
                        const Text("form body"),
                        TextButton(
                          onPressed: () =>
                              setState(() => keypadVisible = false),
                          child: const Text("close keypad"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(_formSlotHeight(tester), greaterThan(200));

      await tester.tap(find.text("close keypad"));
      await tester.pumpAndSettle();

      expect(_keypadOpacity(tester), 0);
      expect(_formSlotHeight(tester), isNull);
    },
  );
}

double _keypadOpacity(WidgetTester tester) {
  return tester
      .widget<AnimatedOpacity>(
        find.byKey(const Key("transaction_keypad_overlay")),
      )
      .opacity;
}

double? _formSlotHeight(WidgetTester tester) {
  final slot = find.byKey(const Key("transaction_keypad_form_slot"));
  if (slot.evaluate().isEmpty) return null;
  return tester.widget<SizedBox>(slot).height;
}

class _FakeVoiceRecorderRepository implements VoiceRecorderRepository {
  @override
  Duration elapsed = Duration.zero;

  @override
  Future<void> start() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<VoiceNoteModel> stop() async {
    return VoiceNoteModel(
      audio: AudioAttachmentModel(
        id: "a",
        durationMs: 1000,
        createdAt: DateTime(2026, 5, 19),
        mimeType: "audio/m4a",
        extension: ".m4a",
        fileSize: 1,
      ),
      duration: Duration.zero,
    );
  }

  @override
  Future<void> dispose() async {}
}
