import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/data/attachments/image_storage_service.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/shared/components/inline_nav_buttons.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Mở xem ảnh gốc toàn màn hình (zoom/pan), có thể lướt Trước/Sau giữa các ảnh.
Future<void> showImageAttachmentPreview(
  BuildContext context, {
  required List<ImageAttachmentModel> images,
  required int initialIndex,
}) {
  if (images.isEmpty) return Future.value();
  final index = initialIndex.clamp(0, images.length - 1);
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    useSafeArea: true,
    builder: (ctx) =>
        ImageAttachmentPreviewDialog(images: images, initialIndex: index),
  );
}

class ImageAttachmentPreviewDialog extends StatefulWidget {
  const ImageAttachmentPreviewDialog({
    super.key,
    required this.images,
    required this.initialIndex,
    this.storage,
  });

  final List<ImageAttachmentModel> images;
  final int initialIndex;
  final ImageStorageService? storage;

  @override
  State<ImageAttachmentPreviewDialog> createState() =>
      _ImageAttachmentPreviewDialogState();
}

class _ImageAttachmentPreviewDialogState
    extends State<ImageAttachmentPreviewDialog> {
  late final ImageStorageService _storage;
  late final PageController _pageController;
  late int _currentIndex;
  final _bytesCache = <String, Future<Uint8List>>{};

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? ImageStorageService();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Uint8List> _loadBytes(ImageAttachmentModel image) {
    return _bytesCache.putIfAbsent(image.id, () async {
      final data = await _storage.read(image);
      return Uint8List.fromList(data);
    });
  }

  void _goPrevious() {
    if (_currentIndex <= 0) return;
    _pageController.previousPage(
      duration: AppDurations.fast,
      curve: Curves.easeOutCubic,
    );
  }

  void _goNext() {
    if (_currentIndex >= widget.images.length - 1) return;
    _pageController.nextPage(
      duration: AppDurations.fast,
      curve: Curves.easeOutCubic,
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goPrevious();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goNext();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canPrev = _currentIndex > 0;
    final canNext = _currentIndex < widget.images.length - 1;
    final showNav = widget.images.length > 1;

    return Dialog(
      key: const Key("image_attachment_preview"),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (showNav)
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        InlineNavButtons(
                          variant: InlineNavVariant.onDark,
                          previousLabel: l10n.pendingPrevious,
                          nextLabel: l10n.pendingNext,
                          canGoPrevious: canPrev,
                          canGoNext: canNext,
                          onPrevious: _goPrevious,
                          onNext: _goNext,
                        ),
                        Text(
                          l10n.imagePreviewCounter(
                            _currentIndex + 1,
                            widget.images.length,
                          ),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white70,
                                fontWeight: AppTypography.semibold,
                              ),
                        ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: l10n.close,
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder: (context, index) {
                      final image = widget.images[index];
                      return FutureBuilder<Uint8List>(
                        future: _loadBytes(image),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _PreviewMessage(
                              icon: Icons.broken_image_outlined,
                              message: l10n.imagePreviewLoadFailed,
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
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
                      );
                    },
                  ),
                  if (showNav) ...[
                    Positioned(
                      left: 0,
                      child: _SideNavButton(
                        icon: Icons.chevron_left_rounded,
                        enabled: canPrev,
                        onPressed: _goPrevious,
                        tooltip: l10n.pendingPrevious,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: _SideNavButton(
                        icon: Icons.chevron_right_rounded,
                        enabled: canNext,
                        onPressed: _goNext,
                        tooltip: l10n.pendingNext,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNavButton extends StatelessWidget {
  const _SideNavButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: enabled ? 0.35 : 0.15),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white, size: 32),
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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
