import "package:flutter/material.dart";

import "package:smart_expense/core/utils/amount_input.dart";
import "package:smart_expense/shared/design_system/design_system.dart";
import "package:smart_expense/shared/components/amount_keypad.dart";

/// Prominent amount field with custom numeric keypad (no system keyboard).
class FormAmountField extends StatefulWidget {
  const FormAmountField({
    super.key,
    required this.controller,
    this.style,
    this.autofocus = false,
    this.alwaysShowKeypad = false,
    this.onDone,
  });

  final AmountInputController controller;
  final TextStyle? style;
  final bool autofocus;

  /// When true, keypad opens on first show (e.g. quick entry). User can close with Xong.
  final bool alwaysShowKeypad;

  final VoidCallback? onDone;

  @override
  State<FormAmountField> createState() => _FormAmountFieldState();
}

class _FormAmountFieldState extends State<FormAmountField> {
  late bool _keypadOpen;

  @override
  void initState() {
    super.initState();
    _keypadOpen = widget.alwaysShowKeypad || widget.autofocus;
    widget.controller.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onAmountChanged);
    super.dispose();
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
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
                        widget.controller.displayText,
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
              onDigit: widget.controller.appendDigit,
              onTripleZero: widget.controller.appendTripleZero,
              onBackspace: widget.controller.backspace,
              onDone: _closeKeypad,
            ),
          ],
        ],
      ),
    );
  }
}
