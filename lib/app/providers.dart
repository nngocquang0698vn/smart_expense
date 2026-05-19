import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:smart_expense/core/utils/pwa/pwa_install_prompt_controller.dart";
import "package:smart_expense/app/theme/theme_notifier.dart";
import "package:smart_expense/features/transactions/application/voice_note/voice_recorder_config.dart";
import "package:smart_expense/features/transactions/data/attachments/voice_recorder_service.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/domain/repositories/voice_recorder_repository.dart";

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError("SharedPreferences must be provided at bootstrap.");
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  throw UnimplementedError("LedgerRepository must be provided at bootstrap.");
});

final themeNotifierProvider = Provider<ThemeNotifier>((ref) {
  throw UnimplementedError("ThemeNotifier must be provided at bootstrap.");
});

final pwaInstallPromptControllerProvider = Provider<PwaInstallPromptController>(
  (ref) {
    throw UnimplementedError(
      "PwaInstallPromptController must be provided at bootstrap.",
    );
  },
);

final voiceRecorderRepositoryProvider = Provider.autoDispose
    .family<VoiceRecorderRepository, VoiceRecorderConfig>((ref, config) {
      final recorder = VoiceRecorderService();
      ref.onDispose(() => recorder.dispose());
      return recorder;
    });
