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
  //
  // Faz o download autenticado do bucket privado.
  //
  // A policy de SELECT em storage.objects continua sendo a
  // responsável por decidir se o usuário pode acessar o arquivo.
  //
  // ============================================================

  Future<
    Uint8List
  >
  download({
    required String storagePath,
  }) async {
    _requireAuthenticatedUser();

    final normalizedPath = _requireValue(
      storagePath,
      fieldName: 'storagePath',
    );

    debugPrint(
      '[CONTRIBUTION UPLOAD] '
      'Baixando: '
      '$normalizedPath',
    );

    final bytes = await _supabase.storage
        .from(
          bucketName,
        )
        .download(
          normalizedPath,
        );

    if (bytes.isEmpty) {
      throw StateError(
        'O arquivo baixado está vazio.',
      );
    }

    debugPrint(
      '[CONTRIBUTION UPLOAD] '
      'Download concluído. '
      'Bytes: ${bytes.lengthInBytes}',
    );

    return bytes;
  }

  // ============================================================
  // DOWNLOAD AND VERIFY
  // ============================================================
  //
  // Baixa o arquivo e compara o SHA-256 com o hash salvo na
  // contribution_delivery.
  //
  // Isso permite que a UI só grave no disco um arquivo cuja
  // integridade foi confirmada.
  //
  // ============================================================

  Future<
    ContributionDownloadResult
  >
  downloadAndVerify({
    required String storagePath,
    required String fileName,
    required String expectedSha256,
    String? mimeType,
  }) async {
    final normalizedPath = _requireValue(
      storagePath,
      fieldName: 'storagePath',
    );

    final normalizedFileName = _sanitizeFileName(
      fileName,
    );

    final normalizedExpectedHash = _requireValue(
      expectedSha256,
      fieldName: 'expectedSha256',
    ).toLowerCase();

    final bytes = await download(
      storagePath: normalizedPath,
    );

    final actualSha256 = _integrityService.hashBytes(
      bytes,
    );

    final integrityValid =
        actualSha256.toLowerCase() ==
        normalizedExpectedHash;

    debugPrint(
      '[CONTRIBUTION UPLOAD] '
      'Integridade do download: '
      '${integrityValid ? 'OK' : 'FALHOU'}. '
      'SHA-256: '
      '${_integrityService.shortHash(actualSha256)}',
    );

    return ContributionDownloadResult(
      bucketName: bucketName,
      storagePath: normalizedPath,
      fileName: normalizedFileName,
      mimeType: _normalizeMimeType(
        mimeType,
      ),
      bytes: bytes,
      fileSize: bytes.lengthInBytes,
      sha256: actualSha256,
      expectedSha256: normalizedExpectedHash,
      integrityValid: integrityValid,
      downloadedAt: DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // DOWNLOAD VERIFIED
  // ============================================================
  //
  // Variante estrita.
  //
  // Se o SHA-256 não corresponder ao hash registrado, lança erro
  // e não devolve um resultado que a UI possa salvar sem querer.
  //
  // ============================================================

  Future<
    ContributionDownloadResult
  >
  downloadVerified({
    required String storagePath,
    required String fileName,
    required String expectedSha256,
    String? mimeType,
  }) async {
    final result = await downloadAndVerify(
      storagePath: storagePath,
      fileName: fileName,
      expectedSha256: expectedSha256,
      mimeType: mimeType,
    );

    if (!result.integrityValid) {
      throw StateError(
        'A integridade do arquivo baixado não pôde ser confirmada.',
      );
    }

    return result;
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
  // SAFE REMOVE
  // ============================================================
  //
  // Usado como rollback quando:
  //
  // 1. o upload físico termina;
  // 2. mas o registro de contribution_deliveries falha.
  //
  // Neste caso ainda não existe uma entrega oficial, então o
  // arquivo pode ser removido sem deixar um objeto órfão.
  //
  // Diferente de remove(), este método não propaga erro.
  //
  // ============================================================

  Future<
    bool
  >
  safeRemove({
    required String storagePath,
  }) async {
    try {
      await remove(
        storagePath: storagePath,
      );

      return true;
    } catch (
      error
    ) {
      debugPrint(
        '[CONTRIBUTION UPLOAD] '
        'Falha ao remover upload não formalizado: '
        '$error',
      );

      return false;
    }
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
    final normalizedExpectedHash = _requireValue(
      expectedSha256,
      fieldName: 'expectedSha256',
    );

    final bytes = await download(
      storagePath: storagePath,
    );

    return _integrityService.verifyBytes(
      bytes: bytes,

      expectedHash: normalizedExpectedHash,
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
  // REQUIRE AUTHENTICATED USER
  // ============================================================

  String _requireAuthenticatedUser() {
    final userId = _supabase.auth.currentUser?.id.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return userId;
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

  bool get isReadyForDelivery {
    return storagePath.trim().isNotEmpty &&
        fileName.trim().isNotEmpty &&
        fileSize >
            0 &&
        sha256.trim().isNotEmpty &&
        version >
            0 &&
        uploadedBy.trim().isNotEmpty;
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

// ============================================================
// CONTRIBUTION DOWNLOAD RESULT
// ============================================================
//
// Resultado de um download autenticado.
//
// A UI pode usar:
//
// - bytes:
//   para gravar no disco;
// - fileName:
//   como nome sugerido;
// - integrityValid:
//   para confirmar se o conteúdo é o mesmo registrado;
// - sha256:
//   para auditoria/debug.
//
// ============================================================

class ContributionDownloadResult {
  final String bucketName;

  final String storagePath;

  final String fileName;

  final String? mimeType;

  final Uint8List bytes;

  final int fileSize;

  final String sha256;

  final String expectedSha256;

  final bool integrityValid;

  final DateTime downloadedAt;

  const ContributionDownloadResult({
    required this.bucketName,
    required this.storagePath,
    required this.fileName,
    required this.bytes,
    required this.fileSize,
    required this.sha256,
    required this.expectedSha256,
    required this.integrityValid,
    required this.downloadedAt,
    this.mimeType,
  });

  bool get hasMimeType {
    return mimeType?.trim().isNotEmpty ==
        true;
  }

  bool get isReadyToSave {
    return fileName.trim().isNotEmpty &&
        bytes.isNotEmpty &&
        fileSize >
            0 &&
        integrityValid;
  }

  @override
  String toString() {
    return 'ContributionDownloadResult('
        'bucketName: $bucketName, '
        'storagePath: $storagePath, '
        'fileName: $fileName, '
        'fileSize: $fileSize, '
        'integrityValid: $integrityValid'
        ')';
  }
}
