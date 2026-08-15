import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// PROFILE TRACK SERVICE
// ============================================================
//
// Responsável somente pelos ARQUIVOS das demos.
//
// Arquitetura:
//
// Flutter
//    ↓
// Supabase Edge Functions
//    ↓
// Cloudflare R2
//
// Supabase:
//
// - Auth;
// - Edge Functions;
// - Postgres através do Repository.
//
// Cloudflare R2:
//
// - armazenamento dos arquivos de áudio.
//
// Este service NÃO:
//
// - possui credenciais do R2;
// - acessa API S3 diretamente;
// - cria linha em profile_tracks;
// - decide permissões de audiência;
// - controla UI.
//
// ============================================================

class ProfileTrackService {
  // ============================================================
  // EDGE FUNCTIONS
  // ============================================================

  static const String uploadFunctionName = 'create-track-upload-url';

  static const String playbackFunctionName = 'create-track-playback-url';

  static const String deleteFunctionName = 'delete-profile-track';

  // ============================================================
  // LIMITES
  // ============================================================

  static const int maxFileSizeBytes =
      8 *
      1024 *
      1024;

  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // HTTP
  // ============================================================

  final http.Client _httpClient;

  // ============================================================
  // ESTADO
  // ============================================================

  bool _disposed = false;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  ProfileTrackService({
    SupabaseClient? supabase,
    http.Client? httpClient,
  }) : _supabase =
           supabase ??
           Supabase.instance.client,
       _httpClient =
           httpClient ??
           http.Client();

  // ============================================================
  // UPLOAD
  // ============================================================
  //
  // Fluxo:
  //
  // 1. valida usuário;
  // 2. valida arquivo;
  // 3. chama create-track-upload-url;
  // 4. recebe uploadUrl + objectKey;
  // 5. envia bytes diretamente ao R2;
  // 6. retorna objectKey.
  //
  // O objectKey posteriormente será salvo em:
  //
  // public.profile_tracks.storage_path
  //
  // ============================================================

  Future<
    String
  >
  uploadTrack({
    required String userId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    _ensureNotDisposed();

    final normalizedUserId = userId.trim();

    final normalizedFileName = _sanitizeFileName(
      fileName,
    );

    // ==========================================================
    // USER
    // ==========================================================

    if (normalizedUserId.isEmpty) {
      throw ArgumentError(
        'userId não pode ser vazio.',
      );
    }

    // ==========================================================
    // FILE
    // ==========================================================

    if (normalizedFileName.isEmpty) {
      throw ArgumentError(
        'fileName não pode ser vazio.',
      );
    }

    if (bytes.isEmpty) {
      throw ArgumentError(
        'O arquivo está vazio.',
      );
    }

    if (bytes.length >
        maxFileSizeBytes) {
      throw ArgumentError(
        'A música ultrapassa o limite de 8 MB.',
      );
    }

    // ==========================================================
    // AUTH
    // ==========================================================

    _validateCurrentUser(
      normalizedUserId,
    );

    // ==========================================================
    // CONTENT TYPE
    // ==========================================================

    final resolvedContentType = _resolveContentType(
      fileName: normalizedFileName,
      contentType: contentType,
    );

    // ==========================================================
    // FORMATO SUPORTADO
    // ==========================================================

    if (!_isSupportedContentType(
      resolvedContentType,
    )) {
      throw ArgumentError(
        'Formato de áudio não suportado.',
      );
    }

    debugPrint(
      '[PROFILE TRACK] '
      'Solicitando URL de upload.',
    );

    // ==========================================================
    // PRESIGNED PUT URL
    // ==========================================================

    final uploadData = await _requestUploadUrl(
      fileName: normalizedFileName,
      contentType: resolvedContentType,
      fileSizeBytes: bytes.length,
    );

    debugPrint(
      '[PROFILE TRACK] '
      'Enviando arquivo ao Cloudflare R2.',
    );

    // ==========================================================
    // R2 PUT
    // ==========================================================

    final response = await _httpClient.put(
      Uri.parse(
        uploadData.uploadUrl,
      ),
      headers: {
        'Content-Type': resolvedContentType,
      },
      body: bytes,
    );

    // ==========================================================
    // HTTP RESULT
    // ==========================================================

    if (!_isSuccessfulStatus(
      response.statusCode,
    )) {
      debugPrint(
        '[PROFILE TRACK] '
        'Upload R2 falhou. '
        'HTTP ${response.statusCode}.',
      );

      if (response.body.isNotEmpty) {
        debugPrint(
          '[PROFILE TRACK] '
          'R2 response: '
          '${response.body}',
        );
      }

      throw StateError(
        'Não foi possível enviar a música.',
      );
    }

    debugPrint(
      '[PROFILE TRACK] '
      'Upload R2 concluído.',
    );

    debugPrint(
      '[PROFILE TRACK] '
      'Object key: '
      '${uploadData.objectKey}',
    );

    return uploadData.objectKey;
  }

  // ============================================================
  // REQUEST UPLOAD URL
  // ============================================================

  Future<
    _TrackUploadData
  >
  _requestUploadUrl({
    required String fileName,
    required String contentType,
    required int fileSizeBytes,
  }) async {
    _ensureNotDisposed();

    try {
      final response = await _supabase.functions.invoke(
        uploadFunctionName,
        body: {
          'fileName': fileName,
          'contentType': contentType,
          'fileSizeBytes': fileSizeBytes,
        },
      );
      debugPrint(
        '[PROFILE TRACK] '
        'Edge Function respondeu.',
      );

      debugPrint(
        '[PROFILE TRACK] '
        'Status: '
        '${response.status}',
      );

      debugPrint(
        '[PROFILE TRACK] '
        'Data: '
        '${response.data}',
      );

      final data = _readResponseMap(
        response.data,
      );

      _throwIfEdgeFunctionError(
        data,
      );

      final uploadUrl = _readRequiredString(
        data,
        'uploadUrl',
      );

      final objectKey = _readRequiredString(
        data,
        'objectKey',
      );

      return _TrackUploadData(
        uploadUrl: uploadUrl,
        objectKey: objectKey,
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE TRACK] '
        'Erro ao solicitar URL de upload: '
        '$error',
      );

      rethrow;
    }
  }

  // ============================================================
  // PLAYBACK URL
  // ============================================================
  //
  // Recebe somente trackId.
  //
  // A Edge Function:
  //
  // 1. identifica o usuário autenticado;
  // 2. busca profile_tracks;
  // 3. lê audience_roles;
  // 4. verifica se o usuário pode ouvir;
  // 5. gera presigned GET URL;
  // 6. retorna playbackUrl.
  //
  // ============================================================

  Future<
    String
  >
  createPlaybackUrl({
    required String trackId,
  }) async {
    _ensureNotDisposed();

    final normalizedTrackId = trackId.trim();

    if (normalizedTrackId.isEmpty) {
      return '';
    }

    _requireAuthenticatedUser();

    try {
      debugPrint(
        '[PROFILE TRACK] '
        'Solicitando URL de reprodução.',
      );

      final response = await _supabase.functions.invoke(
        playbackFunctionName,
        body: {
          'trackId': normalizedTrackId,
        },
      );

      final data = _readResponseMap(
        response.data,
      );

      _throwIfEdgeFunctionError(
        data,
      );

      final playbackUrl = _readRequiredString(
        data,
        'playbackUrl',
      );

      debugPrint(
        '[PROFILE TRACK] '
        'URL temporária de reprodução criada.',
      );

      return playbackUrl;
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE TRACK] '
        'Erro ao obter URL de reprodução: '
        '$error',
      );

      rethrow;
    }
  }

  // ============================================================
  // DELETE TRACK
  // ============================================================
  //
  // A Edge Function delete-profile-track executa:
  //
  // 1. valida JWT;
  // 2. recebe trackId;
  // 3. busca a linha no Postgres;
  // 4. confirma user_id == auth.uid();
  // 5. obtém storage_path do banco;
  // 6. remove objeto do R2;
  // 7. remove linha de profile_tracks.
  //
  // Portanto:
  //
  // - NÃO enviamos objectKey;
  // - NÃO confiamos em storagePath vindo do Flutter;
  // - NÃO excluímos banco separadamente.
  //
  // ============================================================

  Future<
    void
  >
  deleteTrack({
    required String trackId,
  }) async {
    _ensureNotDisposed();

    final normalizedTrackId = trackId.trim();

    if (normalizedTrackId.isEmpty) {
      throw ArgumentError(
        'trackId não pode ser vazio.',
      );
    }

    _requireAuthenticatedUser();

    try {
      debugPrint(
        '[PROFILE TRACK] '
        'Solicitando exclusão da demo.',
      );

      final response = await _supabase.functions.invoke(
        deleteFunctionName,
        body: {
          'trackId': normalizedTrackId,
        },
      );

      final data = _readResponseMap(
        response.data,
      );

      _throwIfEdgeFunctionError(
        data,
      );

      final success = _readBool(
        data['success'],
      );

      if (!success) {
        throw StateError(
          'A exclusão não foi confirmada pelo servidor.',
        );
      }

      debugPrint(
        '[PROFILE TRACK] '
        'Demo removida do R2 e do Postgres.',
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE TRACK] '
        'Erro ao excluir demo: '
        '$error',
      );

      rethrow;
    }
  }

  // ============================================================
  // COMPATIBILIDADE TEMPORÁRIA
  // ============================================================
  //
  // Mantemos este método somente enquanto outros arquivos
  // antigos ainda podem chamá-lo.
  //
  // Internamente ignoramos storagePath e exigimos trackId.
  //
  // Depois podemos remover completamente.
  //
  // ============================================================

  @Deprecated(
    'Use deleteTrack(trackId: ...) diretamente.',
  )
  Future<
    void
  >
  deleteTrackFile({
    required String storagePath,
    String? trackId,
  }) async {
    final normalizedTrackId =
        trackId?.trim() ??
        '';

    if (normalizedTrackId.isEmpty) {
      throw UnsupportedError(
        'A exclusão agora exige trackId. '
        'Use deleteTrack(trackId: track.id).',
      );
    }

    await deleteTrack(
      trackId: normalizedTrackId,
    );
  }

  // ============================================================
  // CREATE SIGNED URL LEGADO
  // ============================================================

  @Deprecated(
    'Use createPlaybackUrl(trackId: ...).',
  )
  Future<
    String
  >
  createSignedUrl({
    required String storagePath,
    int expiresInSeconds = 600,
  }) {
    throw UnsupportedError(
      'createSignedUrl(storagePath) foi removido. '
      'Use createPlaybackUrl(trackId: track.id).',
    );
  }

  // ============================================================
  // PUBLIC URL
  // ============================================================
  //
  // Bucket R2 privado.
  //
  // Não fornecemos URL pública permanente.
  //
  // ============================================================

  String getPublicUrl({
    required String storagePath,
  }) {
    return '';
  }

  // ============================================================
  // AUTH USER
  // ============================================================

  User _requireAuthenticatedUser() {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return currentUser;
  }

  // ============================================================
  // VALIDAR PROPRIETÁRIO
  // ============================================================

  void _validateCurrentUser(
    String userId,
  ) {
    final currentUser = _requireAuthenticatedUser();

    if (currentUser.id !=
        userId) {
      throw StateError(
        'O usuário autenticado não corresponde '
        'ao proprietário da música.',
      );
    }
  }

  // ============================================================
  // EDGE FUNCTION ERROR
  // ============================================================

  void _throwIfEdgeFunctionError(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final error = data['error']?.toString().trim();

    if (error ==
            null ||
        error.isEmpty) {
      return;
    }

    throw StateError(
      error,
    );
  }

  // ============================================================
  // RESPONSE MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  _readResponseMap(
    dynamic value,
  ) {
    if (value
        is Map<
          String,
          dynamic
        >) {
      return value;
    }

    if (value
        is Map) {
      return Map<
        String,
        dynamic
      >.from(
        value,
      );
    }

    if (value
        is String) {
      final normalized = value.trim();

      if (normalized.isEmpty) {
        return <
          String,
          dynamic
        >{};
      }

      final decoded = jsonDecode(
        normalized,
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

  // ============================================================
  // REQUIRED STRING
  // ============================================================

  String _readRequiredString(
    Map<
      String,
      dynamic
    >
    data,
    String key,
  ) {
    final value = data[key]?.toString().trim();

    if (value ==
            null ||
        value.isEmpty) {
      throw StateError(
        'Campo "$key" não retornado pela Edge Function.',
      );
    }

    return value;
  }

  // ============================================================
  // BOOL
  // ============================================================

  bool _readBool(
    dynamic value,
  ) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is num) {
      return value !=
          0;
    }

    final normalized = value?.toString().trim().toLowerCase();

    return normalized ==
            'true' ||
        normalized ==
            '1';
  }

  // ============================================================
  // HTTP STATUS
  // ============================================================

  bool _isSuccessfulStatus(
    int statusCode,
  ) {
    return statusCode >=
            200 &&
        statusCode <
            300;
  }

  // ============================================================
  // CONTENT TYPE
  // ============================================================

  String _resolveContentType({
    required String fileName,
    String? contentType,
  }) {
    final normalizedContentType = contentType?.trim().toLowerCase();

    if (normalizedContentType !=
            null &&
        normalizedContentType.isNotEmpty) {
      if (normalizedContentType ==
          'audio/mp3') {
        return 'audio/mpeg';
      }

      if (normalizedContentType ==
          'audio/x-wav') {
        return 'audio/wav';
      }

      return normalizedContentType;
    }

    final lowerFileName = fileName.toLowerCase();

    if (lowerFileName.endsWith(
      '.mp3',
    )) {
      return 'audio/mpeg';
    }

    if (lowerFileName.endsWith(
      '.wav',
    )) {
      return 'audio/wav';
    }

    if (lowerFileName.endsWith(
      '.m4a',
    )) {
      return 'audio/mp4';
    }

    if (lowerFileName.endsWith(
      '.aac',
    )) {
      return 'audio/aac';
    }

    if (lowerFileName.endsWith(
      '.ogg',
    )) {
      return 'audio/ogg';
    }

    return 'application/octet-stream';
  }

  // ============================================================
  // CONTENT TYPE SUPORTADO
  // ============================================================

  bool _isSupportedContentType(
    String contentType,
  ) {
    switch (contentType) {
      case 'audio/mpeg':
      case 'audio/wav':
      case 'audio/mp4':
      case 'audio/aac':
      case 'audio/ogg':
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // SANITIZE FILE NAME
  // ============================================================

  String _sanitizeFileName(
    String value,
  ) {
    final normalized = value
        .trim()
        .replaceAll(
          RegExp(
            r'[^a-zA-Z0-9._-]',
          ),
          '_',
        )
        .replaceAll(
          RegExp(
            r'_+',
          ),
          '_',
        );

    return normalized;
  }

  // ============================================================
  // DISPOSE CHECK
  // ============================================================

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError(
        'ProfileTrackService já foi encerrado.',
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _httpClient.close();
  }
}

// ============================================================
// TRACK UPLOAD DATA
// ============================================================

class _TrackUploadData {
  final String uploadUrl;

  final String objectKey;

  const _TrackUploadData({
    required this.uploadUrl,
    required this.objectKey,
  });
}
