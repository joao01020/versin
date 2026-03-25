import 'dart:convert';
import 'package:crypto/crypto.dart';

class ObraRegModel {
  final String? id;
  final String titulo;
  final String conteudo;
  final String hash;
  final String donoWallet;

  ObraRegModel({
    this.id,
    required this.titulo,
    required this.conteudo,
    required this.hash,
    required this.donoWallet,
  });

  static String gerarAssinatura(String titulo, String conteudo) {
    final dados = "$titulo|$conteudo|VERSIN_SECURE_KEY";
    return sha256.convert(utf8.encode(dados)).toString();
  }

  Map<String, dynamic> toSupabase() {
    return {
      'titulo': titulo,
      'conteudo': conteudo,
      'hash_original': hash,
      'dono_atual_wallet': donoWallet,
    };
  }

  factory ObraRegModel.fromMap(Map<String, dynamic> map) {
    return ObraRegModel(
      id: map['id'],
      titulo: map['titulo'] ?? '',
      conteudo: map['conteudo'] ?? '',
      hash: map['hash_original'] ?? '',
      donoWallet: map['dono_atual_wallet'] ?? '',
    );
  }
}