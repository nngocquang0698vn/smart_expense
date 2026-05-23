import "dart:typed_data";

import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/data/attachments/image_storage_service.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Mở xem ảnh gốc toàn màn hình (zoom/pan).
Future<void> showImageAttachmentPreview(
  BuildContext context, {
  required ImageAttachmentModel image,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    useSafeArea: true,
    builder: (ctx) => ImageAttachmentPreviewDialog(image: image),
  );
}

class ImageAttachmentPreviewDialog extends StatefulWidget {
  const ImageAttachmentPreviewDialog({
    super.key,
    required this.image,
    this.storage,
  });

  final ImageAttachmentModel image;
  final ImageStorageService? storage;

  @override
  State<ImageAttachmentPreviewDialog> createState() =>
      _ImageAttachmentPreviewDialogState();
}

class _ImageAttachmentPreviewDialogState
    extends State<ImageAttachmentPreviewDialog> {
  late final ImageStorageService _storage;
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? ImageStorageService();
    _bytesFuture = _loadBytes();
  }

  Future<Uint8List> _loadBytes() async {
    final data = await _storage.read(widget.image);
    return Uint8List.fromList(data);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Dialog(
      key: const Key("image_attachment_preview"),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton.filled(
              onPressed: () => Navigator.of(context).pop(),
              tooltip: l10n.close,
              icon: const Icon(Icons.close_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: FutureBuilder<Uint8List>(
              future: _bytesFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _PreviewMessage(
                    icon: Icons.broken_image_outlined,
                    message: l10n.imagePreviewLoadFailed,
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Material(
                    color: Colors.black,
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      child: Center(
                        child: Image.memory(
                          snapshot.data!,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMessage extends StatelessWidget {
  const _PreviewMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white70),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
