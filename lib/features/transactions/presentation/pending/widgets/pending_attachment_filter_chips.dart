import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/application/pending/pending_attachment_filter.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

class PendingAttachmentFilterChips extends StatelessWidget {
  const PendingAttachmentFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PendingAttachmentFilter selected;
  final ValueChanged<PendingAttachmentFilter> onSelected;

  String _label(AppLocalizations l10n, PendingAttachmentFilter filter) {
    return switch (filter) {
      PendingAttachmentFilter.all => l10n.pendingFilterAll,
      PendingAttachmentFilter.withImages => l10n.pendingFilterWithImages,
      PendingAttachmentFilter.withAudio => l10n.pendingFilterWithAudio,
      PendingAttachmentFilter.withMedia => l10n.pendingFilterWithMedia,
      PendingAttachmentFilter.withoutAttachments =>
        l10n.pendingFilterWithoutAttachments,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          for (final filter in PendingAttachmentFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(_label(l10n, filter)),
                selected: selected == filter,
                onSelected: (v) {
                  if (v) onSelected(filter);
                },
              ),
            ),
        ],
      ),
    );
  }
}
