import "package:flutter/material.dart";

class FabCenter extends StatelessWidget {
  const FabCenter({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Material(
        shape: const CircleBorder(),
        elevation: 4,
        color: cs.primary,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.add, color: cs.onPrimary, size: 30),
          ),
        ),
      ),
    );
  }
}
