import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'contribution_integrity_service.dart';

// ============================================================
// CONTRIBUTION UPLOAD SERVICE
// ============================================================
//
// Responsável pelo arquivo físico da entrega.
//
// Faz:
//
// - validar contexto;
// - calcular SHA-256;
// - gerar storage path seguro;
// - fazer upload;
// - download;
// - gerar signed URL;
// - remover arquivo.
//
// NÃO:
//
// - cria contribution_delivery no banco;
// - aprova entrega;
// - decide status;
// - controla UI.
//
// O Repository/Controller será responsável por registrar os
// metadados da entrega depois que o upload terminar.
//
// ============================================================

class ContributionUploadService {
  // ============================================================
  // DEFAULT BUCKET
  // ============================================================

  static const String defaultBucketName = 'project-deliveries';

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SupabaseClient _supabase;

  final ContributionIntegrityService _integrityService;

  final String bucketName;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  ContributionUploadService({
    SupabaseClient? supabase,
    ContributionIntegrityService? integrityService,
    this.bucketName = defaultBucketName,
  }) : _supabase =
           supabase ??
           Supabase.instance.client,
       _integrityService =
           integrityService ??
           const ContributionIntegrityService();

  // ============================================================
  // UPLOAD CONTRIBUTION BYTES
  // ============================================================
  //
  // Estrutura:
  //
  // project-deliveries/
  //
  //   project_id/
  //     user_id/
  //       contribution_id/
  //         v1/
  //           timestamp_filename.wav
  //
  // ============================================================

  Future<
    ContributionUploadResult
  >
  uploadContributionBytes({
    required String projectId,
    required String contributionId,
    required int version,
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    // ==========================================================
    // AUTH
    // ==========================================================

    final userId = _supabase.auth.currentUser?.id.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    // ==========================================================
    // NORMALIZE
    // ==========================================================

    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    final normalizedContributionId = _requireValue(
      contributionId,
      fieldName: 'contributionId',
    );

    final normalizedFileName = _sanitizeFileName(
      fileName,
    );

    if (version <=
        0) {
      throw ArgumentError.value(
        version,
        'version',
        'A versão precisa ser maior que zero.',
      );
    }

    if (bytes.isEmpty) {
      throw ArgumentError(
        'O arquivo está vazio.',
      );
    }

    // ==========================================================
    // HASH
    // ==========================================================

    final sha256 = _integrityService.hashBytes(
      bytes,
    );

    // ==========================================================
    // STORAGE PATH
    // ==========================================================
    //
    // Usamos novo caminho a cada upload.
    //
    // Não sobrescrevemos arquivos anteriores.
    //
    // ==========================================================

    final now = DateTime.now().toUtc();

    final storagePath = _buildStoragePath(
      projectId: normalizedProjectId,

      userId: userId,

      contributionId: normalizedContributionId,

      version: version,

      fileName: normalizedFileName,

      timestamp: now,
    );

    // ==========================================================
    // UPLOAD
    // ==========================================================

    debugPrint(
      '[CONTRIBUTION UPLOAD] '
      'Enviando: '
      '$storagePath',
    );

    final uploadedPath = await _supabase.storage
        .from(
          bucketName,
        )
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',

            upsert: false,

            contentType: _normalizeMimeType(
              mimeType,
            ),
          ),
        );

    // ==========================================================
    // RESULT
    // ==========================================================

    debugPrint(
      '[CONTRIBUTION UPLOAD] '
      'Upload concluído. '
      'SHA-256: '
      '${_integrityService.shortHash(sha256)}',
    );

    return ContributionUploadResult(
      bucketName: bucketName,

      storagePath: uploadedPath.trim().isNotEmpty
          ? uploadedPath.trim()
          : storagePath,

      fileName: normalizedFileName,

      mimeType: _normalizeMimeType(
        mimeType,
      ),

      fileSize: bytes.lengthInBytes,

      sha256: sha256,

      version: version,

      uploadedBy: userId,

      uploadedAt: now,
    );
  }

  // ============================================================
  // DOWNLOAD
  // ============================================================

  Future<
    Uint8List
  >
  download({
    required String storagePath,
  }) async {
    final normalizedPath = _requireValue(
      storagePath,
      fieldName: 'storagePath',
    );

    return _supabase.storage
        .from(
          bucketName,
        )
        .download(
          normalizedPath,
        );
  }

  // ============================================================
  // CREATE SIGNED URL
  // ============================================================
  //
  // O bucket deve permanecer privado.
  //
  // A UI recebe URLs temporárias quando precisar reproduzir ou
  // baixar uma entrega.
  //
  // ============================================================

  Future<
    String
  >
  createSignedUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  }) async {
    final normalizedPath = _requireValue(
      storagePath,
      fieldName: 'storagePath',
    );

    if (expiresInSeconds <=
        0) {
      throw ArgumentError.value(
        expiresInSeconds,
        'expiresInSeconds',
        'O tempo de expiração precisa ser positivo.',
      );
    }

    return _supabase.storage
        .from(
          bucketName,
        )
        .createSignedUrl(
          normalizedPath,
          expiresInSeconds,
        );
  }

  // ============================================================
  // REMOVE
  // ============================================================
  //
  // Use somente quando o upload ainda não foi formalizado como
  // uma entrega oficial.
  //
  // Depois de registrado como evidência do projeto, a regra de
  // negócio deve preferir versionamento em vez de apagar.
  //
  // ============================================================

  Future<
    void
  >
  remove({
    required String storagePath,
  }) async {
    final normalizedPath = _requireValue(
      storagePath,
      fieldName: 'storagePath',
    );

    await _supabase.storage
        .from(
          bucketName,
        )
        .remove(
          [
            normalizedPath,
          ],
        );
  }

  // ============================================================
  // VERIFY DOWNLOADED FILE
  // ============================================================

  Future<
    bool
  >
  verifyRemoteFile({
    required String storagePath,
    required String expectedSha256,
  }) async {
    final bytes = await download(
      storagePath: storagePath,
    );

    return _integrityService.verifyBytes(
      bytes: bytes,

      expectedHash: expectedSha256,
    );
  }

  // ============================================================
  // BUILD STORAGE PATH
  // ============================================================

  String _buildStoragePath({
    required String projectId,
    required String userId,
    required String contributionId,
    required int version,
    required String fileName,
    required DateTime timestamp,
  }) {
    final timestampValue = timestamp.microsecondsSinceEpoch.toString();

    return '$projectId/'
        '$userId/'
        '$contributionId/'
        'v$version/'
        '${timestampValue}_$fileName';
  }

  // ============================================================
  // SANITIZE FILE NAME
  // ============================================================

  String _sanitizeFileName(
    String value,
  ) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError(
        'Nome do arquivo não pode ficar vazio.',
      );
    }

    // ==========================================================
    // REMOVE PATH
    // ==========================================================

    var normalized = trimmed
        .replaceAll(
          '\\',
          '/',
        )
        .split(
          '/',
        )
        .last;

    // ==========================================================
    // SAFE CHARACTERS
    // ==========================================================

    normalized = normalized.replaceAll(
      RegExp(
        r'[^A-Za-z0-9._\- ]',
      ),
      '_',
    );

    // ==========================================================
    // SPACE
    // ==========================================================

    normalized = normalized.replaceAll(
      RegExp(
        r'\s+',
      ),
      '_',
    );

    // ==========================================================
    // MULTIPLE UNDERSCORES
    // ==========================================================

    normalized = normalized.replaceAll(
      RegExp(
        r'_+',
      ),
      '_',
    );

    // ==========================================================
    // HIDDEN / PATH-LIKE NAME
    // ==========================================================

    normalized = normalized.trim();

    if (normalized.isEmpty ||
        normalized ==
            '.' ||
        normalized ==
            '..') {
      throw ArgumentError(
        'Nome do arquivo inválido.',
      );
    }

    // ==========================================================
    // MAX LENGTH
    // ==========================================================

    const maxLength = 180;

    if (normalized.length >
        maxLength) {
      final extensionIndex = normalized.lastIndexOf(
        '.',
      );

      if (extensionIndex >
              0 &&
          extensionIndex <
              normalized.length -
                  1) {
        final extension = normalized.substring(
          extensionIndex,
        );

        final available =
            maxLength -
            extension.length;

        normalized =
            '${normalized.substring(0, available)}'
            '$extension';
      } else {
        normalized = normalized.substring(
          0,
          maxLength,
        );
      }
    }

    return normalized;
  }

  // ============================================================
  // NORMALIZE MIME TYPE
  // ============================================================

  String? _normalizeMimeType(
    String? value,
  ) {
    final normalized =
        value?.trim() ??
        '';

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // REQUIRE VALUE
  // ============================================================

  String _requireValue(
    String value, {
    required String fieldName,
  }) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        fieldName,
        '$fieldName não pode ficar vazio.',
      );
    }

    return normalized;
  }
}

// ============================================================
// CONTRIBUTION UPLOAD RESULT
// ============================================================
//
// Resultado do Storage.
//
// Depois usamos este objeto para inserir:
//
// contribution_deliveries
//
// ============================================================

class ContributionUploadResult {
  final String bucketName;

  final String storagePath;

  final String fileName;

  final String? mimeType;

  final int fileSize;

  final String sha256;

  final int version;

  final String uploadedBy;

  final DateTime uploadedAt;

  const ContributionUploadResult({
    required this.bucketName,
    required this.storagePath,
    required this.fileName,
    required this.fileSize,
    required this.sha256,
    required this.version,
    required this.uploadedBy,
    required this.uploadedAt,
    this.mimeType,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasHash {
    return sha256.trim().isNotEmpty;
  }

  bool get hasMimeType {
    return mimeType?.trim().isNotEmpty ==
        true;
  }

  // ============================================================
  // DATABASE PAYLOAD
  // ============================================================
  //
  // Pronto para virar o insert de contribution_deliveries.
  //
  // contribution_id fica fora porque o service de upload não
  // precisa conhecer a entidade do banco.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toDeliveryPayload({
    required String contributionId,
  }) {
    return {
      'contribution_id': contributionId.trim(),

      'uploaded_by': uploadedBy,

      'file_name': fileName,

      'storage_path': storagePath,

      'mime_type': mimeType,

      'file_size': fileSize,

      'sha256': sha256,

      'version': version,

      'status': 'submitted',

      'created_at': uploadedAt.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ContributionUploadResult('
        'bucketName: $bucketName, '
        'storagePath: $storagePath, '
        'fileName: $fileName, '
        'fileSize: $fileSize, '
        'version: $version, '
        'uploadedBy: $uploadedBy'
        ')';
  }
}
