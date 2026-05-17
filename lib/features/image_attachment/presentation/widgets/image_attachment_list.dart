import "dart:typed_data";

import "package:flutter/material.dart";

import "../../data/image_storage_service.dart";
import "../../domain/image_attachment_model.dart";

class ImageAttachmentList extends StatelessWidget {
  const ImageAttachmentList({
    super.key,
    required this.images,
    required this.onDelete,
    this.height = 88,
  });

  final List<ImageAttachmentModel> images;
  final ValueChanged<ImageAttachmentModel> onDelete;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _ImageAttachmentTile(
            image: images[index],
            size: height,
            onDelete: () => onDelete(images[index]),
          );
        },
      ),
    );
  }
}

class _ImageAttachmentTile extends StatefulWidget {
  const _ImageAttachmentTile({
    required this.image,
    required this.size,
    required this.onDelete,
  });

  final ImageAttachmentModel image;
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FutureBuilder<Uint8List>(
            future: _bytes,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ImageStateBox(
                  size: widget.size,
                  icon: Icons.broken_image_outlined,
                  label: "Lỗi ảnh",
                );
              }
              if (!snapshot.hasData) {
                return _ImageStateBox(
                  size: widget.size,
                  icon: Icons.image_outlined,
                  label: "Đang tải",
                );
              }
              return Image.memory(
                snapshot.data!,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
              );
            },
          ),
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
