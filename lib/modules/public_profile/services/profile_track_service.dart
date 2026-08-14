import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// PROFILE TRACK SERVICE
// ============================================================
//
// Responsável pelos arquivos de áudio do perfil público.
//
// Banco:
//
// public.profile_tracks
//
// Arquivo:
//
// Supabase Storage
//
// Este service NÃO cria linha em profile_tracks.
// Essa responsabilidade pertence ao Repository.
//
// ============================================================

class ProfileTrackService {
  // ============================================================
  // BUCKET
  // ============================================================

  static const String bucketName = 'profile-tracks';

  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  ProfileTrackService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // ============================================================
  // UPLOAD
  // ============================================================

  Future<String> uploadTrack({
    required String userId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final normalizedUserId = userId.trim();

    final normalizedFileName = _sanitizeFileName(fileName);

    if (normalizedUserId.isEmpty) {
      throw ArgumentError('userId não pode ser vazio.');
    }

    if (normalizedFileName.isEmpty) {
      throw ArgumentError('fileName não pode ser vazio.');
    }

    if (bytes.isEmpty) {
      throw ArgumentError('O arquivo está vazio.');
    }

    // ==========================================================
    // PATH
    // ==========================================================

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final storagePath =
        '$normalizedUserId/'
        '$timestamp-$normalizedFileName';

    // ==========================================================
    // UPLOAD
    // ==========================================================

    await _supabase.storage
        .from(bucketName)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(upsert: false, contentType: contentType),
        );

    debugPrint(
      '[PROFILE TRACK] '
      'Upload concluído: '
      '$storagePath',
    );

    return storagePath;
  }

  // ============================================================
  // REMOVER
  // ============================================================

  Future<void> deleteTrackFile({required String storagePath}) async {
    final normalizedPath = storagePath.trim();

    if (normalizedPath.isEmpty) {
      return;
    }

    await _supabase.storage.from(bucketName).remove([normalizedPath]);

    debugPrint(
      '[PROFILE TRACK] '
      'Arquivo removido: '
      '$normalizedPath',
    );
  }

  // ============================================================
  // URL PÚBLICA
  // ============================================================
  //
  // Use somente se o bucket for público.
  //
  // ============================================================

  String getPublicUrl({required String storagePath}) {
    final normalizedPath = storagePath.trim();

    if (normalizedPath.isEmpty) {
      return '';
    }

    return _supabase.storage.from(bucketName).getPublicUrl(normalizedPath);
  }

  // ============================================================
  // SIGNED URL
  // ============================================================
  //
  // Preferível se o bucket permanecer privado.
  //
  // ============================================================

  Future<String> createSignedUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  }) async {
    final normalizedPath = storagePath.trim();

    if (normalizedPath.isEmpty) {
      return '';
    }

    return _supabase.storage
        .from(bucketName)
        .createSignedUrl(normalizedPath, expiresInSeconds);
  }

  // ============================================================
  // SANITIZAR NOME
  // ============================================================

  String _sanitizeFileName(String value) {
    return value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }
}
