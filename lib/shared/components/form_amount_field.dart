import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/core/utils/amount_input.dart";
import "package:smart_expense/core/utils/amount_input_notifier.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Hiển thị số tiền: [boxed] có viền; [prominent] chữ lớn màu thu/chi (Stitch).
enum FormAmountFieldVariant { boxed, prominent }

/// Prominent amount field with custom numeric keypad (no system keyboard).
class FormAmountField extends ConsumerStatefulWidget {
  const FormAmountField({
    super.key,
    required this.initialAmount,
    this.variant = FormAmountFieldVariant.prominent,
    this.style,
    this.autofocus = false,
    this.alwaysShowKeypad = false,
    this.onDone,
    this.errorText,
    this.keypadOpen = false,
    this.onTap,
    this.isIncome = false,
    this.compact = false,
  });

  final int initialAmount;
  final FormAmountFieldVariant variant;
  final TextStyle? style;
  final bool autofocus;
  final bool alwaysShowKeypad;
  final VoidCallback? onDone;
  final String? errorText;
  final bool keypadOpen;
  final VoidCallback? onTap;
  final bool isIncome;
  final bool compact;

  @override
  ConsumerState<FormAmountField> createState() => _FormAmountFieldState();
}

class _FormAmountFieldState extends ConsumerState<FormAmountField> {
  void _openKeypad() {
    widget.onTap?.call();
  }

  Color _amountColor(AppFinanceColors finance) {
    return widget.isIncome ? finance.incomeAmount : finance.expenseAmount;
  }

  TextStyle _amountTextStyle(BuildContext context, AppFinanceColors finance) {
    final color = _amountColor(finance);
    if (widget.style != null) {
      return widget.style!.copyWith(color: color);
    }
    final base = widget.variant == FormAmountFieldVariant.prominent
        ? Theme.of(context).textTheme.displaySmall
        : Theme.of(context).textTheme.headlineMedium;
    return base!.copyWith(
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.5,
    );
  }

  TextStyle _currencyStyle(BuildContext context, AppFinanceColors finance) {
    final color = _amountColor(finance);
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
    );
  }

  Widget _buildProminentAmount(
    BuildContext context,
    int amount,
    AppFinanceColors finance,
  ) {
    final displayStyle = _amountTextStyle(context, finance);
    final prefix = widget.isIncome ? "+ " : "- ";

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _openKeypad,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: widget.compact ? AppSpacing.sm : AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(prefix, style: displayStyle),
              Flexible(
                child: Text(
                  formatAmountInput(amount),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: displayStyle,
                ),
              ),
              Text(" đ", style: _currencyStyle(context, finance)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoxedAmount(
    BuildContext context,
    int amount,
    AppFinanceColors finance,
    ColorScheme cs,
  ) {
    final displayStyle = _amountTextStyle(context, finance);
    final radius = BorderRadius.circular(AppRadius.lg);
    final showKeypad = widget.keypadOpen;
    final prefix = widget.isIncome ? "+ " : "- ";

    return Material(
      color: finance.fieldFill,
      borderRadius: radius,
      child: InkWell(
        onTap: _openKeypad,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: showKeypad ? _amountColor(finance) : finance.fieldBorder,
              width: showKeypad ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(prefix, style: displayStyle),
              Flexible(
                child: Text(
                  formatAmountInput(amount),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: displayStyle,
                ),
              ),
              Text(" đ", style: _currencyStyle(context, finance)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = ref.watch(amountInputProvider(widget.initialAmount));
    final cs = Theme.of(context).colorScheme;
    final finance = context.financeColors;

    final amountWidget = widget.variant == FormAmountFieldVariant.prominent
        ? _buildProminentAmount(context, amount, finance)
        : _buildBoxedAmount(context, amount, finance, cs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        amountWidget,
        if (widget.errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              widget.errorText!,
              textAlign: TextAlign.center,
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
