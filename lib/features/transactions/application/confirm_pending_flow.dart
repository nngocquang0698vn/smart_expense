import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/settings/application/user_preferences_controller.dart";
import "package:smart_expense/shared/components/app_confirm_bottom_sheet.dart";

/// Confirms a pending transaction, optionally showing a confirmation sheet.
Future<void> runConfirmPendingFlow({
  required BuildContext context,
  required WidgetRef ref,
  required String transactionId,
}) async {
  final quickConfirm = ref
      .read(userPreferencesControllerProvider)
      .quickConfirmPending;
  if (!quickConfirm) {
    final ok = await AppConfirmBottomSheet.show(
      context,
      title: context.l10n.confirmPendingTitle,
      message: context.l10n.confirmPendingMessage,
    );
    if (!ok || !context.mounted) return;
  }
  await ref.read(ledgerRepositoryProvider).confirmPending(transactionId);
}
