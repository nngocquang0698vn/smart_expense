import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "../data/ledger_repository.dart";
import "quick_entry_sheet.dart";

Future<void> handleAddFab(
  BuildContext context,
  LedgerRepository repo,
) async {
  final choice = await _showAddOptionsSheet(context);
  if (!context.mounted || choice == null) return;

  await showQuickEntrySheet(context, repo, mode: choice);
}

Future<QuickEntryMode?> _showAddOptionsSheet(BuildContext context) {
  return showModalBottomSheet<QuickEntryMode>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    "Thêm nhanh",
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _OptionCard(
                icon: Icons.touch_app,
                title: "Chạm để nhập",
                subtitle: "Nhập liệu cực nhanh với một lần chạm",
                background: const Color(0xFF00544D),
                foreground: Colors.white,
                onTap: () => Navigator.pop(ctx, QuickEntryMode.tap),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                icon: Icons.mic,
                title: "Ghi âm",
                subtitle: "Ghi nhanh một bản ghi âm để đối soát sau",
                background: const Color(0xFFE6F8FF),
                foreground: const Color(0xFF004D4D),
                onTap: () => Navigator.pop(ctx, QuickEntryMode.voice),
              ),
              const SizedBox(height: 10),
              // Show receipt on all platforms; web gets gallery-only picker
              _OptionCard(
                icon: kIsWeb ? Icons.photo_library_outlined : Icons.photo_camera,
                title: kIsWeb ? "Chọn ảnh hoá đơn" : "Chụp ảnh hoá đơn",
                subtitle: kIsWeb
                    ? "Chọn ảnh từ máy để lưu hoá đơn đối soát"
                    : "Lưu ảnh hoá đơn để đối soát sau",
                background: const Color(0xFFE6F8FF),
                foreground: const Color(0xFF004D4D),
                onTap: () => Navigator.pop(ctx, QuickEntryMode.receipt),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                child: Icon(icon, color: foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: foreground.withValues(alpha: 0.85),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
