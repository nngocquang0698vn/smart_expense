import "package:flutter/material.dart";

import "voice_note_player.dart";

class VoiceNotePreview extends StatelessWidget {
  const VoiceNotePreview({
    super.key,
    required this.audioBase64,
    required this.showActions,
    required this.onShowActions,
    required this.onHideActions,
    required this.onDelete,
    required this.onRecordAgain,
    this.onError,
  });

  final String audioBase64;
  final bool showActions;
  final VoidCallback onShowActions;
  final VoidCallback onHideActions;
  final VoidCallback onDelete;
  final VoidCallback onRecordAgain;
  final ValueChanged<String>? onError;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TapRegion(
      onTapOutside: (_) => onHideActions(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onShowActions,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VoiceNotePlayer(audioBase64: audioBase64, onError: onError),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: showActions
                  ? Padding(
                      key: const ValueKey("voice_preview_actions"),
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onDelete,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              label: const Text("Xoá ghi âm"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.error,
                                side: BorderSide(color: cs.error),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onRecordAgain,
                              icon: const Icon(Icons.mic_rounded, size: 18),
                              label: const Text("Ghi lại"),
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
