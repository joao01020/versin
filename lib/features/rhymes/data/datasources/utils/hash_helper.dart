import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashHelper {
  /// Gera uma assinatura digital única (Hash SHA-256) para a letra.
  /// O objetivo é criar um selo de autoria imutável no Versin Genesis.
  static String generateVersinHash({
    required String lyric,
    required String userWallet,
    required String username,
  }) {
    // 1. Criamos um "payload" combinando a letra, o autor e a carteira.
    // Isso garante que se uma vírgula mudar na letra, o hash muda.
    final String rawData = "$userWallet|$username|$lyric";

    // 2. Convertemos o texto em bytes UTF-8.
    final List<int> bytes = utf8.encode(rawData);

    // 3. Geramos o hash SHA-256.
    final Digest hash = sha256.convert(bytes);

    // 4. Retornamos a representação em Hexadecimal.
    return hash.toString();
  }

  /// Verifica se uma letra corresponde a um hash específico.
  static bool verifyAutorship({
    required String lyric,
    required String userWallet,
    required String username,
    required String existingHash,
  }) {
    final String newHash = generateVersinHash(
      lyric: lyric,
      userWallet: userWallet,
      username: username,
    );
    return newHash == existingHash;
  }

  /// Formata o hash para exibição curta (Ex: 0x7a2...f4e)
  static String formatShortHash(String hash) {
    if (hash.length < 10) return hash;
    return "0x${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}";
  }
}