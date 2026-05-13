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
    this.audioBase64,
    this.imageBase64List = const [],
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
  final String? audioBase64;
  final List<String> imageBase64List;

  Map<String, Object?> toMap() => {
        "title": title,
        "amountVnd": amountVnd,
        "isIncome": isIncome,
        "categoryId": categoryId,
        "occurredAt": occurredAt.toIso8601String(),
        "pending": pending,
        "complete": complete,
        "note": note,
        "audioBase64": audioBase64,
        "imageBase64List": imageBase64List,
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
      audioBase64: map["audioBase64"] as String?,
      imageBase64List:
          (map["imageBase64List"] as List?)?.cast<String>() ?? const [],
    );
  }

  TransactionModel copyWith({
    String? title,
    int? amountVnd,
    bool? isIncome,
    String? categoryId,
    DateTime? occurredAt,
    bool? pending,
    bool? complete,
    String? note,
    String? audioBase64,
    List<String>? imageBase64List,
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
      note: note ?? this.note,
      audioBase64: audioBase64 ?? this.audioBase64,
      imageBase64List: imageBase64List ?? this.imageBase64List,
    );
  }
}
