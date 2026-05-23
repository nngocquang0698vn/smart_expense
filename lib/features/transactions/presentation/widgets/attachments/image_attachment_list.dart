import "dart:typed_data";

import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/data/attachments/image_storage_service.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/presentation/widgets/attachments/image_attachment_preview.dart";

class ImageAttachmentList extends StatelessWidget {
  const ImageAttachmentList({
    super.key,
    required this.images,
    required this.onDelete,
    this.height = 88,
    this.trailing = const [],
  });

  final List<ImageAttachmentModel> images;
  final ValueChanged<ImageAttachmentModel> onDelete;
  final double height;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty && trailing.isEmpty) return const SizedBox.shrink();
    final trailingCount = trailing.length;
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + trailingCount,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index < images.length) {
            final image = images[index];
          return _ImageAttachmentTile(
            key: ValueKey(image.id),
            image: image,
            images: images,
            imageIndex: index,
            size: height,
            onDelete: () => onDelete(image),
          );
          }
          return trailing[index - images.length];
        },
      ),
    );
  }
}

class _ImageAttachmentTile extends StatefulWidget {
  const _ImageAttachmentTile({
    super.key,
    required this.image,
    required this.images,
    required this.imageIndex,
    required this.size,
    required this.onDelete,
  });

  final ImageAttachmentModel image;
  final List<ImageAttachmentModel> images;
  final int imageIndex;
  final double size;
  final VoidCallback onDelete;

  @override
  State<_ImageAttachmentTile> createState() => _ImageAttachmentTileState();
}

class _ImageAttachmentTileState extends State<_ImageAttachmentTile> {
  final _storage = ImageStorageService();
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _load();
  }

  @override
  void didUpdateWidget(covariant _ImageAttachmentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.id != widget.image.id) {
      _bytes = _load();
    }
  }

  Future<Uint8List> _load() async {
    final bytes = await _storage.read(widget.image);
    return Uint8List.fromList(bytes);
  }

  void _openPreview(BuildContext context) {
    showImageAttachmentPreview(
      context,
      images: widget.images,
      initialIndex: widget.imageIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final previewHint = context.l10n.imagePreviewTapHint;
    return Stack(
      children: [
        FutureBuilder<Uint8List>(
          future: _bytes,
          builder: (context, snapshot) {
            final canPreview = snapshot.hasData && !snapshot.hasError;
            Widget thumb;
            if (snapshot.hasError) {
              thumb = _ImageStateBox(
                size: widget.size,
                icon: Icons.broken_image_outlined,
                label: "Lỗi ảnh",
              );
            } else if (!snapshot.hasData) {
              thumb = _ImageStateBox(
                size: widget.size,
                icon: Icons.image_outlined,
                label: "Đang tải",
              );
            } else {
              thumb = Image.memory(
                snapshot.data!,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
              );
            }

            return Semantics(
              button: canPreview,
              label: canPreview ? previewHint : null,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canPreview ? () => _openPreview(context) : null,
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: thumb,
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          top: 2,
          right: 2,
          child: IconButton.filled(
            onPressed: widget.onDelete,
            tooltip: "Xoá ảnh",
            icon: const Icon(Icons.close_rounded, size: 14),
            style: IconButton.styleFrom(
              backgroundColor: cs.scrim.withValues(alpha: 0.62),
              foregroundColor: Colors.white,
              fixedSize: const Size.square(26),
              minimumSize: const Size.square(26),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageStateBox extends StatelessWidget {
  const _ImageStateBox({
    required this.size,
    required this.icon,
    required this.label,
  });

  final double size;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: cs.surfaceContainerHighest),
      child: SizedBox.square(
        dimension: size,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
