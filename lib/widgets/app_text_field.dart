import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../core/constants.dart";
import "../theme/app_finance_colors.dart";

/// Cashew-style “bubbly” field: filled container on [AppFinanceColors.fieldFill].
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.style,
    this.prefixText,
    this.suffix,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextStyle? style;
  final String? prefixText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final finance = context.financeColors;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      style:
          style ??
          Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: finance.fieldText,
            fontWeight: FontWeight.w500,
          ),
      cursorColor: cs.primary,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixText: prefixText,
        suffix: suffix,
        filled: true,
        fillColor: finance.fieldFill,
        labelStyle: TextStyle(color: finance.textHint),
        floatingLabelStyle: TextStyle(
          color: finance.fieldText,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: finance.textHint),
        prefixStyle: TextStyle(
          color: finance.fieldText,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: finance.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
