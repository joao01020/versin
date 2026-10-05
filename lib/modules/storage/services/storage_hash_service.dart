import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

// ============================================================
// STORAGE HASH SERVICE
// ============================================================
//
// Responsável por:
//
// - normalizar letras;
// - gerar SHA-256 de obras;
// - gerar SHA-256 de letras;
// - gerar SHA-256 de textos;
// - gerar SHA-256 de bytes;
// - gerar SHA-256 de arquivos;
// - verificar integridade de letras;
// - verificar integridade de beats;
// - validar hashes SHA-256;
// - comparar hashes.
//
// IMPORTANTE:
//
// O contentHash de StoredWorkModel deve representar o conteúdo
// original da obra:
//
// LETRA
//   conteúdo normalizado da letra
//       ↓
//   SHA-256
//
// BEAT
//   bytes exatos do arquivo original
//       ↓
//   SHA-256
//
// NÃO entram no hash:
//
// - título;
// - BPM;
// - ownerUserId;
// - originalAuthorUserId;
// - data;
// - nome do arquivo;
// - filePath.
//
// Dessa forma, transferência de propriedade ou alteração de
// metadados NÃO altera a identidade criptográfica da obra.
//
// NÃO é responsabilidade deste service:
//
// - salvar no banco;
// - enviar arquivo ao R2;
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

  static const int sha256HexLength = 64;

  // ==========================================================
  // NORMALIZAR LETRA
  // ==========================================================
  //
  // A mesma letra precisa produzir o mesmo hash em diferentes
  // sistemas operacionais.
  //
  // Por isso:
  //
  // \r\n → \n
  // \r   → \n
  //
  // Também removemos espaços no final das linhas e espaços /
  // quebras extras no começo e final do documento.
  //
  // ==========================================================

  String normalizeLyrics(
    String content,
  ) {
    var normalized = content;

    // ========================================================
    // NORMALIZAR QUEBRAS DE LINHA
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
              r'[ \t]+$',
            ),
            '',
          ),
        )
        .toList(
          growable: false,
        );

    normalized = lines.join(
      '\n',
    );

    // ========================================================
    // REMOVER ESPAÇO / QUEBRAS EXTRAS NAS EXTREMIDADES
    // ========================================================

    normalized = normalized.trim();

    return normalized;
  }

  // ==========================================================
  // HASH DA OBRA — LETRA
  // ==========================================================
  //
  // Este é o método recomendado para preencher:
  //
  // StoredWorkModel.contentHash
  //
  // quando:
  //
  // type == StoredWorkType.lyrics
  //
  // ==========================================================

  String generateLyricsWorkHash(
    String lyrics,
  ) {
    return hashLyrics(
      lyrics,
    );
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

    return _digestBytes(
      bytes,
    );
  }

  // ==========================================================
  // COMPATIBILIDADE — REGISTRO DE LETRA
  // ==========================================================
  //
  // Mantido porque RegisterLyricsPage já utiliza:
  //
  // generateTextHash(...)
  //
  // ==========================================================

  String generateTextHash(
    String content,
  ) {
    return generateLyricsWorkHash(
      content,
    );
  }

  // ==========================================================
  // HASH DE STRING GENÉRICA
  // ==========================================================
  //
  // NÃO normaliza o conteúdo.
  //
  // Qualquer diferença de espaço, quebra de linha ou caractere
  // produz outro hash.
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

    return _digestBytes(
      utf8.encode(
        content,
      ),
    );
  }

  // ==========================================================
  // HASH DA OBRA — BEAT EM BYTES
  // ==========================================================
  //
  // Este é o método recomendado quando os bytes já estiverem
  // carregados em memória.
  //
  // ==========================================================

  String generateBeatWorkHashFromBytes(
    Uint8List bytes,
  ) {
    return hashUint8List(
      bytes,
    );
  }

  // ==========================================================
  // HASH DE BYTES
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

    return _digestBytes(
      bytes,
    );
  }

  // ==========================================================
  // HASH DE UINT8LIST
  // ==========================================================

  String hashUint8List(
    Uint8List bytes,
  ) {
    return hashBytes(
      bytes,
    );
  }

  // ==========================================================
  // HASH DA OBRA — BEAT EM ARQUIVO
  // ==========================================================
  //
  // Este é o método recomendado para preencher:
  //
  // StoredWorkModel.contentHash
  //
  // quando:
  //
  // type == StoredWorkType.beat
  //
  // ==========================================================

  Future<
    String
  >
  generateBeatWorkHashFromFile(
    String filePath,
  ) {
    return hashFile(
      filePath,
    );
  }

  // ==========================================================
  // HASH DE ARQUIVO
  // ==========================================================
  //
  // Usa stream para não carregar arquivos grandes inteiros na
  // memória apenas para calcular o SHA-256.
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

    return normalizeHash(
      digest.toString(),
    );
  }

  // ==========================================================
  // VERIFICAR OBRA — LETRA
  // ==========================================================

  bool verifyLyricsWork({
    required String lyrics,
    required String expectedHash,
  }) {
    return verifyLyrics(
      content: lyrics,
      expectedHash: expectedHash,
    );
  }

  // ==========================================================
  // VERIFICAR HASH DE LETRA
  // ==========================================================

  bool verifyLyrics({
    required String content,
    required String expectedHash,
  }) {
    final normalizedExpectedHash = normalizeHash(
      expectedHash,
    );

    if (!isValidSha256(
      normalizedExpectedHash,
    )) {
      return false;
    }

    final generatedHash = hashLyrics(
      content,
    );

    return constantTimeEquals(
      generatedHash,
      normalizedExpectedHash,
    );
  }

  // ==========================================================
  // VERIFICAR TEXTO GENÉRICO
  // ==========================================================

  bool verifyText({
    required String content,
    required String expectedHash,
  }) {
    final normalizedExpectedHash = normalizeHash(
      expectedHash,
    );

    if (!isValidSha256(
      normalizedExpectedHash,
    )) {
      return false;
    }

    final generatedHash = hashText(
      content,
    );

    return constantTimeEquals(
      generatedHash,
      normalizedExpectedHash,
    );
  }

  // ==========================================================
  // VERIFICAR OBRA — BEAT EM BYTES
  // ==========================================================

  bool verifyBeatWorkBytes({
    required Uint8List bytes,
    required String expectedHash,
  }) {
    return verifyBytes(
      bytes: bytes,
      expectedHash: expectedHash,
    );
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
    final normalizedExpectedHash = normalizeHash(
      expectedHash,
    );

    if (!isValidSha256(
      normalizedExpectedHash,
    )) {
      return false;
    }

    final generatedHash = hashBytes(
      bytes,
    );

    return constantTimeEquals(
      generatedHash,
      normalizedExpectedHash,
    );
  }

  // ==========================================================
  // VERIFICAR OBRA — BEAT EM ARQUIVO
  // ==========================================================

  Future<
    bool
  >
  verifyBeatWorkFile({
    required String filePath,
    required String expectedHash,
  }) {
    return verifyFile(
      filePath: filePath,
      expectedHash: expectedHash,
    );
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
    final normalizedExpectedHash = normalizeHash(
      expectedHash,
    );

    if (!isValidSha256(
      normalizedExpectedHash,
    )) {
      return false;
    }

    final generatedHash = await hashFile(
      filePath,
    );

    return constantTimeEquals(
      generatedHash,
      normalizedExpectedHash,
    );
  }

  // ==========================================================
  // VALIDAR SHA-256
  // ==========================================================
  //
  // SHA-256 hexadecimal:
  //
  // 64 caracteres
  // 0-9
  // a-f
  //
  // ==========================================================

  bool isValidSha256(
    String hash,
  ) {
    final normalized = normalizeHash(
      hash,
    );

    if (normalized.length !=
        sha256HexLength) {
      return false;
    }

    return RegExp(
      r'^[a-f0-9]{64}$',
    ).hasMatch(
      normalized,
    );
  }

  // ==========================================================
  // EXIGIR SHA-256 VÁLIDO
  // ==========================================================
  //
  // Útil antes de persistir dados recebidos de outra camada.
  //
  // ==========================================================

  String requireValidSha256(
    String hash, {
    String fieldName = 'contentHash',
  }) {
    final normalized = normalizeHash(
      hash,
    );

    if (!isValidSha256(
      normalized,
    )) {
      throw ArgumentError(
        '$fieldName não contém um SHA-256 válido.',
      );
    }

    return normalized;
  }

  // ==========================================================
  // HASH CURTO PARA INTERFACE
  // ==========================================================

  String shortenHash(
    String hash, {
    int startLength = 8,
    int endLength = 4,
  }) {
    final normalized = normalizeHash(
      hash,
    );

    if (normalized.isEmpty) {
      return '';
    }

    if (startLength <
            0 ||
        endLength <
            0) {
      throw ArgumentError(
        'Os tamanhos do hash curto não podem ser negativos.',
      );
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
  // COMPARAR HASHES
  // ==========================================================

  bool hashesMatch(
    String first,
    String second,
  ) {
    final firstNormalized = normalizeHash(
      first,
    );

    final secondNormalized = normalizeHash(
      second,
    );

    if (!isValidSha256(
          firstNormalized,
        ) ||
        !isValidSha256(
          secondNormalized,
        )) {
      return false;
    }

    return constantTimeEquals(
      firstNormalized,
      secondNormalized,
    );
  }

  // ==========================================================
  // COMPARAÇÃO EM TEMPO CONSTANTE
  // ==========================================================
  //
  // Não é estritamente necessário para comparação de hash de
  // conteúdo público, mas evita comparação caractere-a-caractere
  // com retorno antecipado e mantém o helper robusto.
  //
  // ==========================================================

  bool constantTimeEquals(
    String first,
    String second,
  ) {
    final a = utf8.encode(
      first,
    );

    final b = utf8.encode(
      second,
    );

    if (a.length !=
        b.length) {
      return false;
    }

    var difference = 0;

    for (
      var index = 0;
      index <
          a.length;
      index++
    ) {
      difference |=
          a[index] ^
          b[index];
    }

    return difference ==
        0;
  }

  // ==========================================================
  // NORMALIZAR HASH
  // ==========================================================
  //
  // Público porque repository/services podem precisar garantir
  // que o valor persistido esteja sempre em lowercase.
  //
  // ==========================================================

  String normalizeHash(
    String hash,
  ) {
    return hash.trim().toLowerCase();
  }

  // ==========================================================
  // DIGEST INTERNO
  // ==========================================================

  String _digestBytes(
    List<
      int
    >
    bytes,
  ) {
    return normalizeHash(
      sha256
          .convert(
            bytes,
          )
          .toString(),
    );
  }
}
