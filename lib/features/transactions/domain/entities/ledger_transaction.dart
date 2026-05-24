import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";

class LedgerTransaction {
  const LedgerTransaction({
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

  bool get hasAudio => audio != null;
  bool get hasImages => images.isNotEmpty;

  static const _unset = Object();

  LedgerTransaction copyWith({
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
    return LedgerTransaction(
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
