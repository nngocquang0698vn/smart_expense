import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.title,
    required this.amountVnd,
    required this.isIncome,
    required this.categoryId,
    required this.occurredAt,
    required this.pending,
    required this.complete,
    this.note,
    this.audio,
    this.images = const [],
    this.reviewReason,
    this.reviewedAt,
    this.dismissedReviewAt,
  });

  final String id;
  final String title;
  final int amountVnd;
  final bool isIncome;
  final String categoryId;
  final DateTime occurredAt;
  final bool pending;
  final bool complete;
  final String? note;
  final AudioAttachmentModel? audio;
  final List<ImageAttachmentModel> images;
  final String? reviewReason;
  final DateTime? reviewedAt;
  final DateTime? dismissedReviewAt;

  bool get hasAudio => audio != null;
  bool get hasImages => images.isNotEmpty;

  Map<String, Object?> toMap() => {
    "title": title,
    "amountVnd": amountVnd,
    "isIncome": isIncome,
    "categoryId": categoryId,
    "occurredAt": occurredAt.toIso8601String(),
    "pending": pending,
    "complete": complete,
    "note": note,
    "audio": audio?.toMap(),
    "images": images.map((image) => image.toMap()).toList(),
    "reviewReason": reviewReason,
    "reviewedAt": reviewedAt?.toIso8601String(),
    "dismissedReviewAt": dismissedReviewAt?.toIso8601String(),
  };

  static TransactionModel fromMap(String id, Map<String, Object?> map) {
    final legacy = map["amountCents"];
    final rawVnd = map["amountVnd"];
    int asInt(Object? v) => v is int ? v : (v as num).toInt();
    final vnd = rawVnd != null
        ? asInt(rawVnd)
        : (legacy != null ? asInt(legacy) ~/ 100 : 0);
    return TransactionModel(
      id: id,
      title: map["title"]! as String,
      amountVnd: vnd,
      isIncome: map["isIncome"]! as bool,
      categoryId: map["categoryId"]! as String,
      occurredAt: DateTime.parse(map["occurredAt"]! as String),
      pending: map["pending"]! as bool,
      complete: map["complete"]! as bool,
      note: map["note"] as String?,
      audio: AudioAttachmentModel.fromMap(map["audio"]),
      images: _imagesFromMap(map),
      reviewReason: map["reviewReason"] as String?,
      reviewedAt: DateTime.tryParse(map["reviewedAt"] as String? ?? ""),
      dismissedReviewAt: DateTime.tryParse(
        map["dismissedReviewAt"] as String? ?? "",
      ),
    );
  }

  static List<ImageAttachmentModel> _imagesFromMap(Map<String, Object?> map) {
    final fromList =
        (map["images"] as List?)
            ?.map(ImageAttachmentModel.fromMap)
            .whereType<ImageAttachmentModel>()
            .toList() ??
        const <ImageAttachmentModel>[];
    if (fromList.isNotEmpty) return fromList;

    final legacy = map["image"] ?? map["receiptImage"];
    if (legacy is Map) {
      final single = ImageAttachmentModel.fromMap(legacy);
      if (single != null) return [single];
    }
    return const [];
  }

  static const _unset = Object();

  TransactionModel copyWith({
    String? title,
    int? amountVnd,
    bool? isIncome,
    String? categoryId,
    DateTime? occurredAt,
    bool? pending,
    bool? complete,
    Object? note = _unset,
    Object? audio = _unset,
    List<ImageAttachmentModel>? images,
    Object? reviewReason = _unset,
    Object? reviewedAt = _unset,
    Object? dismissedReviewAt = _unset,
  }) {
    return TransactionModel(
      id: id,
      title: title ?? this.title,
      amountVnd: amountVnd ?? this.amountVnd,
      isIncome: isIncome ?? this.isIncome,
      categoryId: categoryId ?? this.categoryId,
      occurredAt: occurredAt ?? this.occurredAt,
      pending: pending ?? this.pending,
      complete: complete ?? this.complete,
      note: note == _unset ? this.note : note as String?,
      audio: audio == _unset ? this.audio : audio as AudioAttachmentModel?,
      images: images ?? this.images,
      reviewReason: reviewReason == _unset
          ? this.reviewReason
          : reviewReason as String?,
      reviewedAt: reviewedAt == _unset
          ? this.reviewedAt
          : reviewedAt as DateTime?,
      dismissedReviewAt: dismissedReviewAt == _unset
          ? this.dismissedReviewAt
          : dismissedReviewAt as DateTime?,
    );
  }
}
