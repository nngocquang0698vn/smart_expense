import "package:flutter/material.dart";

/// A titled card used on the home dashboard and any future summary surfaces.
///
/// Renders a rounded [Card] with a [label] in the theme's [labelLarge] style
/// above an arbitrary [child] widget.
///
/// ```dart
/// SummaryCard(
///   label: AppStrings.income,
///   child: MoneyText(income, isIncome: true),
/// )
/// ```
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
