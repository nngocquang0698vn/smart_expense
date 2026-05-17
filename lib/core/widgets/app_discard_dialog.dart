import "package:flutter/material.dart";

import "../strings.dart";

/// Returns `true` if the user chose to discard unsaved quick-entry changes.
Future<bool> showDiscardEntryDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(AppStrings.discardEntryTitle),
      content: const Text(AppStrings.discardEntryMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(AppStrings.continueEntry),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(AppStrings.cancel),
        ),
      ],
    ),
  );
  return result == true;
}

/// Returns `true` if the user chose to discard unsaved transaction edits.
Future<bool> showDiscardEditDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(AppStrings.discardEditTitle),
      content: const Text(AppStrings.discardEditMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(AppStrings.continueEditing),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(AppStrings.discard),
        ),
      ],
    ),
  );
  return result == true;
}

/// Returns `true` if the user confirmed deleting the current voice note.
Future<bool> showDeleteVoiceNoteDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(AppStrings.deleteVoiceNoteTitle),
      content: const Text(AppStrings.deleteVoiceNoteMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(AppStrings.keepVoiceNote),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(AppStrings.deleteVoiceNote),
        ),
      ],
    ),
  );
  return result == true;
}
