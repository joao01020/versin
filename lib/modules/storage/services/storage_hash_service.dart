import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

// ============================================================
// STORAGE HASH SERVICE
// ============================================================
//
// Responsabilidades:
//
// - normalizar letras;
// - gerar SHA-256 de letras;
// - gerar SHA-256 de textos;
// - gerar SHA-256 de bytes;
// - gerar SHA-256 de arquivos;
// - verificar integridade de letras;
// - verificar integridade de arquivos.
//
// NÃO é responsabilidade deste service:
//
// - salvar no banco;
// - salvar arquivo;
// - alterar StoredWorkModel;
// - controlar UI;
// - transferir autoria.
//
// ============================================================

class StorageHashService {
  // ==========================================================
  // ALGORITMO
  // ==========================================================

  static const String algorithm = 'SHA-256';

  // ==========================================================
  // NORMALIZAR LETRA
  // ==========================================================
  //
  // É importante gerar o hash sempre sobre uma forma
  // previsível do texto.
  //
  // Exemplo:
  //
  // Windows:
  // \r\n
  //
  // Linux:
  // \n
  //
  // Visualmente podem representar a mesma letra,
  // mas os bytes seriam diferentes.
  //
  // Por isso normalizamos as quebras de linha antes
  // de gerar o SHA-256.
  //
  // ==========================================================

  String normalizeLyrics(
    String content,
  ) {
    var normalized = content;

    // ========================================================
    // NORMALIZAR QUEBRA DE LINHA
    // ========================================================

    normalized = normalized.replaceAll(
      '\r\n',
      '\n',
    );

    normalized = normalized.replaceAll(
      '\r',
      '\n',
    );

    // ========================================================
    // REMOVER ESPAÇOS NO FIM DAS LINHAS
    // ========================================================

    final lines = normalized
        .split(
          '\n',
        )
        .map(
          (
            line,
          ) => line.replaceFirst(
            RegExp(
              r'\s+$',
            ),
            '',
          ),
        )
        .toList();

    normalized = lines.join(
      '\n',
    );

    // ========================================================
    // REMOVER QUEBRAS EXTRAS NO INÍCIO/FIM
    // ========================================================

    normalized = normalized.trim();

    return normalized;
  }

  // ==========================================================
  // GERAR HASH DE LETRA
  // ==========================================================

  String hashLyrics(
    String content,
  ) {
    final normalized = normalizeLyrics(
      content,
    );

    if (normalized.isEmpty) {
      throw ArgumentError(
        'O conteúdo da letra não pode ser vazio.',
      );
    }

    final bytes = utf8.encode(
      normalized,
    );

    final digest = sha256.convert(
      bytes,
    );

    return digest.toString();
  }

  // ==========================================================
  // GERAR HASH DE TEXTO PARA REGISTRO
  // ==========================================================
  //
  // Método usado pela interface de registro de letra.
  //
  // Mantemos este nome para deixar a API do service
  // mais clara na camada de UI:
  //
  // hashService.generateTextHash(...)
  //
  // Para letras, reutilizamos hashLyrics() porque ele
  // já faz a normalização correta do conteúdo.
  //
  // ==========================================================

  String generateTextHash(
    String content,
  ) {
    return hashLyrics(
      content,
    );
  }

  // ==========================================================
  // GERAR HASH DE STRING GENÉRICA
  // ==========================================================
  //
  // Diferente de hashLyrics():
  //
  // Este método NÃO normaliza a string.
  //
  // É útil quando queremos que qualquer diferença no texto,
  // inclusive espaços ou quebras, altere o hash.
  //
  // ==========================================================

  String hashText(
    String content,
  ) {
    if (content.isEmpty) {
      throw ArgumentError(
        'O conteúdo não pode ser vazio.',
      );
    }

    final bytes = utf8.encode(
      content,
    );

    return sha256
        .convert(
          bytes,
        )
        .toString();
  }

  // ==========================================================
  // GERAR HASH DE BYTES
  // ==========================================================

  String hashBytes(
    List<
      int
    >
    bytes,
  ) {
    if (bytes.isEmpty) {
      throw ArgumentError(
        'Os bytes não podem estar vazios.',
      );
    }

    return sha256
        .convert(
          bytes,
        )
        .toString();
  }

  // ==========================================================
  // GERAR HASH DE UINT8LIST
  // ==========================================================

  String hashUint8List(
    Uint8List bytes,
  ) {
    return hashBytes(
      bytes,
    );
  }

  // ==========================================================
  // GERAR HASH DE ARQUIVO
  // ==========================================================
  //
  // Útil para:
  //
  // .wav
  // .mp3
  // .flac
  // .aiff
  // etc.
  //
  // Para arquivos grandes, usamos stream.
  //
  // Isso evita carregar o beat inteiro na RAM.
  //
  // ==========================================================

  Future<
    String
  >
  hashFile(
    String filePath,
  ) async {
    final normalizedPath = filePath.trim();

    if (normalizedPath.isEmpty) {
      throw ArgumentError(
        'O caminho do arquivo não pode ser vazio.',
      );
    }

    final file = File(
      normalizedPath,
    );

    final exists = await file.exists();

    if (!exists) {
      throw FileSystemException(
        'Arquivo não encontrado.',
        normalizedPath,
      );
    }

    final length = await file.length();

    if (length <=
        0) {
      throw ArgumentError(
        'O arquivo está vazio.',
      );
    }

    final digest = await sha256
        .bind(
          file.openRead(),
        )
        .first;

    return digest.toString();
  }

  // ==========================================================
  // VERIFICAR HASH DE LETRA
  // ==========================================================

  bool verifyLyrics({
    required String content,
    required String expectedHash,
  }) {
    final normalizedExpectedHash = _normalizeHash(
      expectedHash,
    );

    if (normalizedExpectedHash.isEmpty) {
      return false;
    }

    final generatedHash = hashLyrics(
      content,
    );

    return generatedHash ==
        normalizedExpectedHash;
  }

  // ==========================================================
  // VERIFICAR HASH DE TEXTO
  // ==========================================================

  bool verifyText({
    required String content,
    required String expectedHash,
  }) {
    final normalizedExpectedHash = _normalizeHash(
      expectedHash,
    );

    if (normalizedExpectedHash.isEmpty) {
      return false;
    }

    final generatedHash = hashText(
      content,
    );

    return generatedHash ==
        normalizedExpectedHash;
  }

  // ==========================================================
  // VERIFICAR HASH DE BYTES
  // ==========================================================

  bool verifyBytes({
    required List<
      int
    >
    bytes,
    required String expectedHash,
  }) {
    final normalizedExpectedHash = _normalizeHash(
      expectedHash,
    );

    if (normalizedExpectedHash.isEmpty) {
      return false;
    }

    final generatedHash = hashBytes(
      bytes,
    );

    return generatedHash ==
        normalizedExpectedHash;
  }

  // ==========================================================
  // VERIFICAR HASH DE ARQUIVO
  // ==========================================================

  Future<
    bool
  >
  verifyFile({
    required String filePath,
    required String expectedHash,
  }) async {
    final normalizedExpectedHash = _normalizeHash(
      expectedHash,
    );

    if (normalizedExpectedHash.isEmpty) {
      return false;
    }

    final generatedHash = await hashFile(
      filePath,
    );

    return generatedHash ==
        normalizedExpectedHash;
  }

  // ==========================================================
  // VALIDAR SHA-256
  // ==========================================================
  //
  // SHA-256 hexadecimal:
  //
  // 64 caracteres.
  //
  // ==========================================================

  bool isValidSha256(
    String hash,
  ) {
    final normalized = _normalizeHash(
      hash,
    );

    final regex = RegExp(
      r'^[a-f0-9]{64}$',
    );

    return regex.hasMatch(
      normalized,
    );
  }

  // ==========================================================
  // HASH CURTO PARA INTERFACE
  // ==========================================================
  //
  // O banco sempre guarda o hash completo.
  //
  // Na interface podemos mostrar:
  //
  // 68f84d34...9e21
  //
  // ==========================================================

  String shortenHash(
    String hash, {
    int startLength = 8,
    int endLength = 4,
  }) {
    final normalized = _normalizeHash(
      hash,
    );

    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.length <=
        startLength +
            endLength) {
      return normalized;
    }

    final start = normalized.substring(
      0,
      startLength,
    );

    final end = normalized.substring(
      normalized.length -
          endLength,
    );

    return '$start...$end';
  }

  // ==========================================================
  // COMPARAR DOIS HASHES
  // ==========================================================

  bool hashesMatch(
    String first,
    String second,
  ) {
    final firstNormalized = _normalizeHash(
      first,
    );

    final secondNormalized = _normalizeHash(
      second,
    );

    if (firstNormalized.isEmpty ||
        secondNormalized.isEmpty) {
      return false;
    }

    return firstNormalized ==
        secondNormalized;
  }

  // ==========================================================
  // NORMALIZAR HASH
  // ==========================================================

  String _normalizeHash(
    String hash,
  ) {
    return hash.trim().toLowerCase();
  }
}
