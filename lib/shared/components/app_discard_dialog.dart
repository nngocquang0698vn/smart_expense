import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";

/// Returns `true` if the user chose to discard unsaved quick-entry changes.
Future<bool> showDiscardEntryDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.discardEntryTitle),
      content: Text(context.l10n.discardEntryMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.l10n.continueEntry),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.l10n.cancel),
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
      title: Text(context.l10n.discardEditTitle),
      content: Text(context.l10n.discardEditMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.l10n.continueEditing),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.l10n.discard),
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
      title: Text(context.l10n.deleteVoiceNoteTitle),
      content: Text(context.l10n.deleteVoiceNoteMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.l10n.keepVoiceNote),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.l10n.deleteVoiceNote),
        ),
      ],
    ),
  );
  return result == true;
}

/// Returns `true` if the user confirmed replacing the current voice note.
Future<bool> showReplaceVoiceNoteDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.replaceVoiceNoteTitle),
      content: Text(context.l10n.replaceVoiceNoteMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.l10n.keepVoiceNote),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.l10n.reRecord),
        ),
      ],
    ),
  );
  return result == true;
}
