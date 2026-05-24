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
  };

  static TransactionModel fromMap(String id, Map<String, Object?> map) {
    int asInt(Object? v) => v is int ? v : (v as num).toInt();
    return TransactionModel(
      id: id,
      title: map["title"]! as String,
      amountVnd: asInt(map["amountVnd"]),
      isIncome: map["isIncome"]! as bool,
      categoryId: map["categoryId"]! as String,
      occurredAt: DateTime.parse(map["occurredAt"]! as String),
      pending: map["pending"]! as bool,
      complete: map["complete"]! as bool,
      note: map["note"] as String?,
      audio: AudioAttachmentModel.fromMap(map["audio"]),
      images:
          (map["images"] as List?)
              ?.map(ImageAttachmentModel.fromMap)
              .whereType<ImageAttachmentModel>()
              .toList() ??
          const <ImageAttachmentModel>[],
    );
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
    );
  }
}
