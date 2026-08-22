import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class BeatStorageService {
  static const String uploadFunctionName = 'create-work-upload-url';
  static const String playbackFunctionName = 'create-work-playback-url';
  static const String deleteFunctionName = 'delete-work-file';

  static const int maxFileSizeBytes =
      100 *
      1024 *
      1024;

  final SupabaseClient _supabase;
  final http.Client _httpClient;

  BeatStorageService({
    SupabaseClient? supabase,
    http.Client? httpClient,
  }) : _supabase =
           supabase ??
           Supabase.instance.client,
       _httpClient =
           httpClient ??
           http.Client();

  Future<
    BeatUploadResult
  >
  uploadBeat({
    required String workId,
    required String userId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final normalizedWorkId = _required(
      workId,
      'workId',
    );
    final normalizedUserId = _required(
      userId,
      'userId',
    );
    final normalizedFileName = _sanitizeFileName(
      fileName,
    );

    _validateCurrentUser(
      normalizedUserId,
    );

    if (bytes.isEmpty) {
      throw ArgumentError(
        'O beat está vazio.',
      );
    }
    if (bytes.length >
        maxFileSizeBytes) {
      throw ArgumentError(
        'O beat ultrapassa o limite de 100 MB.',
      );
    }

    final resolvedContentType = _resolveContentType(
      fileName: normalizedFileName,
      contentType: contentType,
    );

    final uploadData = await _requestUploadUrl(
      workId: normalizedWorkId,
      fileName: normalizedFileName,
      contentType: resolvedContentType,
      fileSizeBytes: bytes.length,
    );

    debugPrint(
      '[BEAT STORAGE] Enviando beat para R2...',
    );

    final response = await _httpClient.put(
      Uri.parse(
        uploadData.uploadUrl,
      ),
      headers: {
        'Content-Type': resolvedContentType,
      },
      body: bytes,
    );

    if (response.statusCode <
            200 ||
        response.statusCode >=
            300) {
      final responseBody = response.body.trim();

      debugPrint(
        '[BEAT STORAGE] Upload recusado pelo R2.',
      );

      debugPrint(
        '[BEAT STORAGE] HTTP: ${response.statusCode}',
      );

      debugPrint(
        '[BEAT STORAGE] Response: $responseBody',
      );

      throw StateError(
        'Falha no upload do beat '
        '(HTTP ${response.statusCode}). '
        '${responseBody.isNotEmpty ? responseBody : ''}',
      );
    }

    return BeatUploadResult(
      objectKey: uploadData.objectKey,
      fileName: normalizedFileName,
      contentType: resolvedContentType,
      fileSizeBytes: bytes.length,
    );
  }

  Future<
    String
  >
  createPlaybackUrl({
    required String workId,
  }) async {
    final id = _required(
      workId,
      'workId',
    );
    final response = await _supabase.functions.invoke(
      playbackFunctionName,
      body: {
        'workId': id,
      },
    );
    final data = _readMap(
      response.data,
    );
    return _requiredFromMap(
      data,
      'playbackUrl',
    );
  }

  Future<
    void
  >
  deleteBeat({
    required String workId,
  }) async {
    final id = _required(
      workId,
      'workId',
    );
    await _supabase.functions.invoke(
      deleteFunctionName,
      body: {
        'workId': id,
      },
    );
  }

  Future<
    _BeatUploadData
  >
  _requestUploadUrl({
    required String workId,
    required String fileName,
    required String contentType,
    required int fileSizeBytes,
  }) async {
    final response = await _supabase.functions.invoke(
      uploadFunctionName,
      body: {
        'workId': workId,
        'fileName': fileName,
        'contentType': contentType,
        'fileSizeBytes': fileSizeBytes,
      },
    );

    final data = _readMap(
      response.data,
    );
    return _BeatUploadData(
      uploadUrl: _requiredFromMap(
        data,
        'uploadUrl',
      ),
      objectKey: _requiredFromMap(
        data,
        'objectKey',
      ),
    );
  }

  void _validateCurrentUser(
    String userId,
  ) {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId ==
            null ||
        currentUserId.isEmpty) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }
    if (currentUserId !=
        userId) {
      throw StateError(
        'O usuário autenticado não corresponde ao dono do upload.',
      );
    }
  }

  String _resolveContentType({
    required String fileName,
    String? contentType,
  }) {
    final explicit = contentType?.trim();
    if (explicit !=
            null &&
        explicit.isNotEmpty) {
      if (!_allowedMimeTypes.contains(
        explicit,
      )) {
        throw ArgumentError(
          'Formato de áudio não permitido: $explicit',
        );
      }
      return explicit;
    }

    final extension = fileName
        .split(
          '.',
        )
        .last
        .toLowerCase();
    final resolved = _mimeByExtension[extension];
    if (resolved ==
        null) {
      throw ArgumentError(
        'Extensão de áudio não suportada.',
      );
    }
    return resolved;
  }

  static const Set<
    String
  >
  _allowedMimeTypes = {
    'audio/mpeg',
    'audio/wav',
    'audio/x-wav',
    'audio/mp4',
    'audio/aac',
    'audio/ogg',
    'audio/flac',
  };

  static const Map<
    String,
    String
  >
  _mimeByExtension = {
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    'ogg': 'audio/ogg',
    'flac': 'audio/flac',
  };

  String _sanitizeFileName(
    String value,
  ) {
    final normalized = value.trim().replaceAll(
      RegExp(
        r'[^a-zA-Z0-9._-]',
      ),
      '_',
    );
    if (normalized.isEmpty) {
      throw ArgumentError(
        'fileName não pode ser vazio.',
      );
    }
    return normalized;
  }

  String _required(
    String value,
    String field,
  ) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError(
        '$field não pode ser vazio.',
      );
    }
    return normalized;
  }

  Map<
    String,
    dynamic
  >
  _readMap(
    dynamic raw,
  ) {
    if (raw
        is Map) {
      return Map<
        String,
        dynamic
      >.from(
        raw,
      );
    }
    if (raw
        is String) {
      final decoded = jsonDecode(
        raw,
      );
      if (decoded
          is Map) {
        return Map<
          String,
          dynamic
        >.from(
          decoded,
        );
      }
    }
    throw StateError(
      'Resposta inválida da Edge Function.',
    );
  }

  String _requiredFromMap(
    Map<
      String,
      dynamic
    >
    map,
    String key,
  ) {
    final value =
        map[key]?.toString().trim() ??
        '';
    if (value.isEmpty) {
      throw StateError(
        'Campo "$key" ausente na resposta.',
      );
    }
    return value;
  }

  void dispose() {
    _httpClient.close();
  }
}

class BeatUploadResult {
  final String objectKey;
  final String fileName;
  final String contentType;
  final int fileSizeBytes;

  const BeatUploadResult({
    required this.objectKey,
    required this.fileName,
    required this.contentType,
    required this.fileSizeBytes,
  });
}

class _BeatUploadData {
  final String uploadUrl;
  final String objectKey;

  const _BeatUploadData({
    required this.uploadUrl,
    required this.objectKey,
  });
}
