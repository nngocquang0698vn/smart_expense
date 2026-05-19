import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/core/utils/amount_input.dart";
import "package:smart_expense/core/utils/amount_input_notifier.dart";
import "package:smart_expense/shared/design_system/design_system.dart";
import "package:smart_expense/shared/components/amount_keypad.dart";

/// Prominent amount field with custom numeric keypad (no system keyboard).
class FormAmountField extends ConsumerStatefulWidget {
  const FormAmountField({
    super.key,
    required this.initialAmount,
    this.style,
    this.autofocus = false,
    this.alwaysShowKeypad = false,
    this.onDone,
  });

  final int initialAmount;
  final TextStyle? style;
  final bool autofocus;

  /// When true, keypad opens on first show (e.g. quick entry). User can close with Xong.
  final bool alwaysShowKeypad;

  final VoidCallback? onDone;

  @override
  ConsumerState<FormAmountField> createState() => _FormAmountFieldState();
}

class _FormAmountFieldState extends ConsumerState<FormAmountField> {
  late bool _keypadOpen;

  @override
  void initState() {
    super.initState();
    _keypadOpen = widget.alwaysShowKeypad || widget.autofocus;
  }

  void _openKeypad() {
    if (_keypadOpen) return;
    setState(() => _keypadOpen = true);
  }

  void _closeKeypad() {
    setState(() => _keypadOpen = false);
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final amount = ref.watch(amountInputProvider(widget.initialAmount));
    final notifier = ref.read(
      amountInputProvider(widget.initialAmount).notifier,
    );
    final cs = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final radius = BorderRadius.circular(AppRadius.lg);
    final showKeypad = _keypadOpen;

    final displayStyle =
        widget.style?.copyWith(color: finance.fieldText) ??
        Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: finance.fieldText,
        );

    return TapRegion(
      onTapOutside: (_) {
        if (_keypadOpen) _closeKeypad();
      },
      child: Column(
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
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "₫ ",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: finance.fieldText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        formatAmountInput(amount),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: displayStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showKeypad) ...[
            const SizedBox(height: AppSpacing.xs),
            AmountKeypad(
              onDigit: notifier.appendDigit,
              onTripleZero: notifier.appendTripleZero,
              onBackspace: notifier.backspace,
              onDone: _closeKeypad,
            ),
          ],
        ],
      ),
    );
  }
}
