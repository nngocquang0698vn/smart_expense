import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../core/constants.dart";
import "../theme/app_finance_colors.dart";

/// Prominent amount field — Cashew `canvasContainer` fill + clear border.
class FormAmountField extends StatelessWidget {
  const FormAmountField({
    super.key,
    required this.controller,
    this.style,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final TextStyle? style;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final radius = BorderRadius.circular(AppRadius.input);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: finance.fieldFill,
        borderRadius: radius,
        border: Border.all(color: finance.fieldBorder),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        cursorColor: cs.primary,
        style: style?.copyWith(color: finance.fieldText) ??
            Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: finance.fieldText,
                ),
        decoration: InputDecoration(
          prefixText: "₫ ",
          prefixStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: finance.fieldText,
                fontWeight: FontWeight.w700,
              ),
          hintText: "0",
          hintStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: finance.textHint,
              ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
