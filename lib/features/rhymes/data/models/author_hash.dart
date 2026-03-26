import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthorHash {
  final String? id;
  final String title;
  final String content;
  final String hash;
  final String ownerWallet;

  AuthorHash({
    this.id,
    required this.title,
    required this.content,
    required this.hash,
    required this.ownerWallet,
  });

  // Método para gerar a assinatura digital da rima (Hash SHA-256)
  static String generateSignature(String title, String content) {
    final data = "$title|$content|VERSIN_SECURE_KEY";
    return sha256.convert(utf8.encode(data)).toString();
  }

  // Converte o modelo para o formato JSON do Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'title': title,
      'content': content,
      'original_hash': hash,
      'current_owner_wallet': ownerWallet,
    };
  }

  // Reconstrói o objeto a partir do Map retornado pelo banco de dados
  factory AuthorHash.fromMap(Map<String, dynamic> map) {
    return AuthorHash(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      hash: map['original_hash'] ?? '',
      ownerWallet: map['current_owner_wallet'] ?? '',
    );
  }
}