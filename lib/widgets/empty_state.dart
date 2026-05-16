import "package:flutter/material.dart";

/// Generic empty-state message displayed when a list has no items.
///
/// Uses the theme's [bodyMedium] style tinted with [color] (defaults to
/// [ColorScheme.outline] so it looks muted without extra imports).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.color,
  });

  final String message;

  /// Text colour. Defaults to [ColorScheme.outline] when `null`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: effectiveColor),
        ),
      ),
    );
  }
}
