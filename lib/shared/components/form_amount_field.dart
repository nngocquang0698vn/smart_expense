import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/core/utils/amount_input.dart";
import "package:smart_expense/core/utils/amount_input_notifier.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Prominent amount field with custom numeric keypad (no system keyboard).
class FormAmountField extends ConsumerStatefulWidget {
  const FormAmountField({
    super.key,
    required this.initialAmount,
    this.style,
    this.autofocus = false,
    this.alwaysShowKeypad = false,
    this.onDone,
    this.errorText,
    this.keypadOpen = false,
    this.onTap,
    this.isIncome = false,
  });

  final int initialAmount;
  final TextStyle? style;
  final bool autofocus;

  /// When true, keypad opens on first show (e.g. quick entry). User can close with Xong.
  final bool alwaysShowKeypad;

  final VoidCallback? onDone;
  final String? errorText;
  final bool keypadOpen;
  final VoidCallback? onTap;
  final bool isIncome;

  @override
  ConsumerState<FormAmountField> createState() => _FormAmountFieldState();
}

class _FormAmountFieldState extends ConsumerState<FormAmountField> {
  void _openKeypad() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final amount = ref.watch(amountInputProvider(widget.initialAmount));
    final cs = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final radius = BorderRadius.circular(AppRadius.lg);
    final showKeypad = widget.keypadOpen;

    final displayStyle =
        widget.style?.copyWith(color: finance.fieldText) ??
        Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: finance.fieldText,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: finance.fieldFill,
          borderRadius: radius,
          child: InkWell(
            onTap: _openKeypad,
            borderRadius: radius,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: showKeypad ? cs.primary : finance.fieldBorder,
                  width: showKeypad ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.isIncome ? "+ " : "- ", style: displayStyle),
                  Flexible(
                    child: Text(
                      formatAmountInput(amount),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: displayStyle,
                    ),
                  ),
                  Text(
                    " đ",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: finance.fieldText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              widget.errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
