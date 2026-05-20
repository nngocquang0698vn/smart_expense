import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

Future<void> showTransactionFormSheet(
  BuildContext context, {
  required Widget child,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: child,
    ),
  );
}

const double kTransactionKeypadHeight = 268;

class TransactionKeypadScaffold extends StatelessWidget {
  const TransactionKeypadScaffold({
    super.key,
    required this.keypadVisible,
    required this.keypad,
    required this.child,
  });

  final bool keypadVisible;
  final Widget keypad;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.95,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedPadding(
              duration: AppDurations.fast,
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                bottom: keypadVisible ? kTransactionKeypadHeight : 0,
              ),
              child: child,
            ),
          ),
          AnimatedPositioned(
            duration: AppDurations.fast,
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: keypadVisible ? 0 : -kTransactionKeypadHeight,
            child: SafeArea(top: false, child: keypad),
          ),
        ],
      ),
    );
  }
}

class TransactionSheetHeader extends StatelessWidget {
  const TransactionSheetHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          tooltip: context.l10n.close,
        ),
      ],
    );
  }
}
