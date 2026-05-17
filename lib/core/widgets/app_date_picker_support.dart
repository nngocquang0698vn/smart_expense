import "package:flutter/material.dart";

import "../constants.dart";
import "app_date_picker_layout.dart";

/// Wraps Material date picker dialogs on wide screens.
Widget wrapDatePickerDialog(BuildContext context, Widget? child) {
  if (child == null) return const SizedBox.shrink();

  final width = MediaQuery.sizeOf(context).width;
  if (width < AppBreakpoints.desktop) return child;

  return Center(
    child: ConstrainedBox(
      key: const Key("app_date_picker_dialog_constraint"),
      constraints: const BoxConstraints(
        maxWidth: AppDatePickerLayout.dialogMaxWidth,
        maxHeight: AppDatePickerLayout.dialogMaxHeight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        child: child,
      ),
    ),
  );
}
