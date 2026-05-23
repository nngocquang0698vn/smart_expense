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
    builder: (ctx) {
      final viewInsets = MediaQuery.viewInsetsOf(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: child,
      );
    },
  );
}

const double kTransactionKeypadHeight = 268;

/// Bọc form + keypad số — [Stack] cố định, keypad overlay (opacity), không animate
/// chiều cao slot → tránh overflow vàng lúc đóng/mở keypad trên web.
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
    final screenH = MediaQuery.sizeOf(context).height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : screenH;
        final sheetHeight = keypadVisible
            ? (screenH * 0.95).clamp(0.0, maxH)
            : null;
        final formHeight = keypadVisible && sheetHeight != null
            ? (sheetHeight - kTransactionKeypadHeight).clamp(0.0, maxH)
            : null;

        return SizedBox(
          height: sheetHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.topCenter,
            children: [
              SizedBox(
                key: const Key("transaction_keypad_form_slot"),
                height: formHeight,
                width: double.infinity,
                child: child,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: !keypadVisible,
                  child: AnimatedOpacity(
                    key: const Key("transaction_keypad_overlay"),
                    duration: AppDurations.fast,
                    curve: Curves.easeOut,
                    opacity: keypadVisible ? 1 : 0,
                    child: SafeArea(top: false, child: keypad),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

/// Form sheet có thể cuộn khi nội dung dài; khi keypad đóng vẫn co gọn.
class TransactionSheetScrollBody extends StatelessWidget {
  const TransactionSheetScrollBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 28),
    this.compact = false,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final bool compact;

  EdgeInsets get _effectivePadding {
    if (!compact) return padding;
    return EdgeInsets.fromLTRB(
      padding.left,
      6,
      padding.right,
      padding.bottom - 8 > 12 ? padding.bottom - 8 : 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.92;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          padding: _effectivePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
