import "package:flutter/material.dart";

import "../../core/design_system/app_button_styles.dart";

/// Action button for [ColorScheme.primaryContainer] media cards (audio, …).
class AppTintedCardButton extends StatelessWidget {
  const AppTintedCardButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : _primary = false;

  const AppTintedCardButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : _primary = true;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool _primary;

  @override
  Widget build(BuildContext context) {
    if (_primary) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: AppButtonStyles.tintedCardPrimary(context),
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: AppButtonStyles.tintedCardSecondary(context),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
