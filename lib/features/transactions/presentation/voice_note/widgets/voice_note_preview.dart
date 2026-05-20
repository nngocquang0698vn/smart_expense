import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/presentation/voice_note/widgets/voice_note_player.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

class VoiceNotePreview extends StatelessWidget {
  const VoiceNotePreview({
    super.key,
    required this.audio,
    required this.showActions,
    required this.onShowActions,
    required this.onHideActions,
    required this.onDelete,
    required this.onRecordAgain,
    this.onError,
  });

  final AudioAttachmentModel audio;
  final bool showActions;
  final VoidCallback onShowActions;
  final VoidCallback onHideActions;
  final VoidCallback onDelete;
  final VoidCallback onRecordAgain;
  final ValueChanged<String>? onError;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return TapRegion(
      onTapOutside: (_) => onHideActions(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onShowActions,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VoiceNotePlayer(audio: audio, onError: onError),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: showActions
                  ? Padding(
                      key: const ValueKey("voice_preview_actions"),
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onDelete,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              label: Text(l10n.deleteVoiceNote),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.error,
                                side: BorderSide(color: cs.error),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onRecordAgain,
                              icon: const Icon(Icons.mic_rounded, size: 18),
                              label: Text(l10n.reRecord),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey("voice_preview_no_actions"),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
