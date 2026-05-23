import "dart:convert";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/data/attachments/image_storage_service.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/presentation/widgets/attachments/image_attachment_preview.dart";

class _FakeImageStorageService extends ImageStorageService {
  _FakeImageStorageService(this.bytes);

  final Uint8List bytes;

  @override
  Future<List<int>> read(ImageAttachmentModel image) async => bytes;
}

void main() {
  final image = ImageAttachmentModel(
    id: "img-1",
    mimeType: "image/png",
    extension: ".png",
    fileSize: 4,
    width: 1,
    height: 1,
    createdAt: DateTime(2026, 5, 19),
  );

  /// 1×1 PNG đỏ hợp lệ.
  final pngBytes = base64Decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==",
  );

  Widget host(Widget child) {
    return MaterialApp(
      locale: const Locale("vi", "VN"),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets("opens preview dialog with zoomable image", (tester) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ImageAttachmentPreviewDialog(
                image: image,
                storage: _FakeImageStorageService(pngBytes),
              ),
            ),
            child: const Text("open"),
          ),
        ),
      ),
    );

    await tester.tap(find.text("open"));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("image_attachment_preview")), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets("closes preview when close button tapped", (tester) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ImageAttachmentPreviewDialog(
                image: image,
                storage: _FakeImageStorageService(pngBytes),
              ),
            ),
            child: const Text("open"),
          ),
        ),
      ),
    );

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip("Đóng"));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("image_attachment_preview")), findsNothing);
  });
}
