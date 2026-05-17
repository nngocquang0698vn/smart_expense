import "package:flutter/material.dart";

import "../shared/widgets/app_empty_state.dart";

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.color});

  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) => AppEmptyState(message: message);
}
