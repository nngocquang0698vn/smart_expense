import "dart:async";
import "dart:convert";

import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "package:http_parser/http_parser.dart";

import "package:smart_expense/core/storage/audio_storage_helper.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";

const kDefaultVoiceTransactionDemoEndpoint =
    "https://smart-expense-m8nm.onrender.com";

class VoiceTransactionDemoApiException implements Exception {
  const VoiceTransactionDemoApiException(this.message);

  final String message;

  @override
  String toString() => "VoiceTransactionDemoApiException: $message";
}

class VoiceTransactionDemoEndpoint {
  const VoiceTransactionDemoEndpoint._();

  static const path = "/voice-transaction-demo";

  static String normalize(String input) {
    var value = input.trim();
    while (value.endsWith("/")) {
      value = value.substring(0, value.length - 1);
    }
    if (value.endsWith(path)) {
      value = value.substring(0, value.length - path.length);
    }
    while (value.endsWith("/")) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  static bool isValidBase(String input) {
    final normalized = normalize(input);
    return normalized.startsWith("http://") ||
        normalized.startsWith("https://");
  }

  static Uri parseUri(String endpoint) =>
      Uri.parse("${normalize(endpoint)}$path");

  static Uri healthUri(String endpoint) =>
      Uri.parse("${normalize(endpoint)}/health");
}

class VoiceTransactionDemoApiClient {
  VoiceTransactionDemoApiClient({http.Client? client})
    : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 10);
  static const _logName = "VoiceTransactionDemoApiClient";

  final http.Client _client;

  Future<void> health({required String endpoint}) async {
    final uri = VoiceTransactionDemoEndpoint.healthUri(endpoint);
    _log("health start uri=$uri");
    try {
      final response = await _client.get(uri).timeout(_timeout);
      _log("health response status=${response.statusCode}");
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = _shortBody(response.body);
        throw VoiceTransactionDemoApiException(
          "Health check failed with HTTP ${response.statusCode}"
          "${body.isEmpty ? "" : ": $body"}",
        );
      }
    } on VoiceTransactionDemoApiException {
      rethrow;
    } on TimeoutException catch (error) {
      _log("health timeout after ${_timeout.inSeconds}s", error: error);
      throw VoiceTransactionDemoApiException(
        "Health check timed out after ${_timeout.inSeconds}s.",
      );
    } catch (error) {
      _log("health failed", error: error);
      throw VoiceTransactionDemoApiException(
        "Health check failed before response: $error",
      );
    }
  }

  Future<VoiceTransactionDemoResponse> parseAudio({
    required String endpoint,
    required String? demoToken,
    required AudioAttachmentModel audio,
    required List<int> audioBytes,
    String locale = "vi-VN",
    String timezone = "Asia/Ho_Chi_Minh",
  }) async {
    if (audioBytes.isEmpty) {
      throw const VoiceTransactionDemoApiException("Audio is empty.");
    }

    final uri = VoiceTransactionDemoEndpoint.parseUri(endpoint);
    final request = http.MultipartRequest("POST", uri);
    final token = demoToken?.trim();
    if (token != null && token.isNotEmpty) {
      request.headers["X-Demo-Token"] = token;
    }
    request.fields["locale"] = locale;
    request.fields["timezone"] = timezone;

    final contentType = _contentTypeFor(audio, audioBytes);
    final filename = _filenameFor(audio, audioBytes);
    _log(
      "parse start uri=$uri audioId=${audio.id} "
      "filename=$filename contentType=${contentType ?? "unknown"} "
      "bytes=${audioBytes.length} hasToken=${token?.isNotEmpty == true}",
    );

    try {
      request.files.add(
        http.MultipartFile.fromBytes(
          "audio",
          audioBytes,
          filename: filename,
          contentType: _mediaTypeOrNull(contentType),
        ),
      );
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(_timeout);
      _log(
        "parse response status=${response.statusCode} "
        "bodyBytes=${response.bodyBytes.length}",
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = _shortBody(response.body);
        _log("parse non-2xx body=$body");
        throw VoiceTransactionDemoApiException(
          "Parse failed with HTTP ${response.statusCode}"
          "${body.isEmpty ? "" : ": $body"}",
        );
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final parsed = VoiceTransactionDemoResponse.fromJson(decoded);
      _log(
        "parse decoded transcriptLength=${parsed.transcript.length} "
        "warnings=${parsed.warnings.length} pendingForced=true",
      );
      return parsed;
    } on VoiceTransactionDemoApiException {
      rethrow;
    } on TimeoutException catch (error) {
      _log("parse timeout after ${_timeout.inSeconds}s", error: error);
      throw VoiceTransactionDemoApiException(
        "Parse timed out after ${_timeout.inSeconds}s.",
      );
    } on FormatException catch (error) {
      _log("parse invalid response JSON", error: error);
      throw VoiceTransactionDemoApiException(
        "Parse returned invalid JSON: $error",
      );
    } catch (error) {
      _log("parse failed", error: error);
      throw VoiceTransactionDemoApiException(
        "Parse failed before response: $error",
      );
    }
  }

  String _filenameFor(AudioAttachmentModel audio, List<int> bytes) {
    final extension = _extensionFor(audio, bytes);
    return "voice_note$extension";
  }

  String _extensionFor(AudioAttachmentModel audio, List<int> bytes) {
    final detected = AudioStorageHelper.extensionForBytes(bytes);
    if (detected != ".m4a" || audio.extension.trim().isEmpty) {
      return detected;
    }
    final extension = audio.extension.trim();
    return extension.startsWith(".") ? extension : ".$extension";
  }

  String? _contentTypeFor(AudioAttachmentModel audio, List<int> bytes) {
    final stored = audio.mimeType.trim();
    if (stored.isNotEmpty && stored != "audio/*") return stored;
    return AudioStorageHelper.contentTypeForBytes(bytes);
  }

  MediaType? _mediaTypeOrNull(String? contentType) {
    if (contentType == null || contentType.trim().isEmpty) return null;
    try {
      return MediaType.parse(contentType);
    } catch (error) {
      _log("ignore invalid contentType=$contentType", error: error);
      return null;
    }
  }

  void close() {
    _client.close();
  }

  static void _log(String message, {Object? error}) {
    debugPrint("[AI Voice Demo][$_logName] $message");
    if (error != null) {
      debugPrint("[AI Voice Demo][$_logName] error=$error");
    }
  }

  static String _shortBody(String body) {
    final compact = body.replaceAll(RegExp(r"\s+"), " ").trim();
    if (compact.length <= 240) return compact;
    return "${compact.substring(0, 240)}...";
  }
}

class VoiceTransactionDemoResponse {
  const VoiceTransactionDemoResponse({
    required this.transcript,
    required this.transactionDraft,
    required this.warnings,
  });

  final String transcript;
  final VoiceTransactionDraftResponse transactionDraft;
  final List<String> warnings;

  factory VoiceTransactionDemoResponse.fromJson(Map<String, dynamic> json) {
    return VoiceTransactionDemoResponse(
      transcript: json["transcript"] as String? ?? "",
      transactionDraft: VoiceTransactionDraftResponse.fromJson(
        json["transactionDraft"],
      ),
      warnings: [
        for (final warning in (json["warnings"] as List? ?? const []))
          if (warning != null) warning.toString(),
      ],
    );
  }
}

class VoiceTransactionDraftResponse {
  const VoiceTransactionDraftResponse({
    this.title,
    this.amountVnd,
    required this.isIncome,
    this.categoryName,
    this.categoryKey,
    this.categoryId,
    this.note,
    this.transactionDate,
    required this.pending,
    this.confidence,
  });

  final String? title;
  final int? amountVnd;
  final bool isIncome;
  final String? categoryName;
  final String? categoryKey;
  final String? categoryId;
  final String? note;
  final DateTime? transactionDate;
  final bool pending;
  final double? confidence;

  factory VoiceTransactionDraftResponse.fromJson(Object? raw) {
    final json = raw is Map ? raw : const <String, Object?>{};
    return VoiceTransactionDraftResponse(
      title: _stringOrNull(json["title"]),
      amountVnd: (json["amountVnd"] as num?)?.toInt(),
      isIncome: json["isIncome"] as bool? ?? false,
      categoryName: _stringOrNull(json["categoryName"]),
      categoryKey: _stringOrNull(json["categoryKey"]),
      categoryId: _stringOrNull(json["categoryId"]),
      note: _stringOrNull(json["note"]),
      transactionDate: _parseDate(json["transactionDate"]),
      pending: true,
      confidence: (json["confidence"] as num?)?.toDouble(),
    );
  }

  static String? _stringOrNull(Object? raw) {
    if (raw is! String) return null;
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }
}
