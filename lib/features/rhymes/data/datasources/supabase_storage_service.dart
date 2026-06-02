import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/features/rhymes/data/datasources/utils/hash_helper.dart';

class SupabaseStorageService {
  final _supabase = Supabase.instance.client;

  /// Registra a obra completa, gera o Hash real e salva rimas utilizadas
  Future<
    void
  >
  registerWorkInSupa(
    String title,
    String content,
    String username, {
    List<
      String
    >?
    usedRhymes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user ==
        null)
      throw Exception(
        "Usuário não autenticado",
      );

    final wallet = "wallet@$username";

    // Geração de Hash Real usando o nosso HashHelper
    final hash = HashHelper.generateVersinHash(
      lyric: content,
      userWallet: wallet,
      username: username,
    );

    final newWork = {
      'title': title,
      'content': content,
      'original_hash': hash,
      'current_owner_wallet': wallet,
      'author_id': user.id,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'original',
      'meta_data': {
        'used_rhymes':
            usedRhymes ??
            [],
        'versin_version': '2.8.0-production',
      },
    };

    try {
      await _supabase
          .from(
            'works',
          )
          .insert(
            newWork,
          );

      if (usedRhymes !=
              null &&
          usedRhymes.isNotEmpty) {
        for (var rhyme in usedRhymes) {
          await _supabase.rpc(
            'increment_word_score',
            params: {
              'word_param': rhyme.toLowerCase(),
            },
          );
        }
      }

      debugPrint(
        "🚀 Obra registrada e assinada: $hash",
      );
    } catch (
      e
    ) {
      debugPrint(
        "❌ Erro ao registrar obra: $e",
      );
      rethrow;
    }
  }

  /// Salva uma letra no histórico (Utilizado pelo botão Finalizar)
  Future<
    void
  >
  saveLyric({
    required String content,
    required String hash,
    int bpm = 120,
    String? vibe,
    String? theme,
    String? structure,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user ==
        null)
      return;

    try {
      await _supabase
          .from(
            'lyrics_history',
          )
          .insert(
            {
              'user_id': user.id, // Corrigido: valor do ID adicionado
              'content': content,
              'hash_signature': hash,
              'bpm': bpm,
              'vibe': vibe,
              'theme': theme,
              'structure': structure,
              'created_at': DateTime.now().toIso8601String(),
            },
          );
      debugPrint(
        "✅ Letra salva no histórico do Versin.",
      );
    } catch (
      e
    ) {
      debugPrint(
        "⚠️ Erro ao salvar histórico: $e",
      );
    }
  }

  /// Transfere a posse de uma obra assinada
  Future<
    void
  >
  transferOwnership(
    String workHash,
    String newDestinationWallet,
  ) async {
    try {
      await _supabase
          .from(
            'works',
          )
          .update(
            {
              'current_owner_wallet': newDestinationWallet,
              'status': 'transferred',
              'transferred_at': DateTime.now().toIso8601String(),
            },
          )
          .eq(
            'original_hash',
            workHash,
          );
      debugPrint(
        "✅ Sucesso: Transferido para a carteira $newDestinationWallet",
      );
    } catch (
      e
    ) {
      debugPrint(
        "❌ Falha na transferência: $e",
      );
      rethrow;
    }
  }

  /// Lista obras por carteira do proprietário
  Future<
    List<
      dynamic
    >
  >
  listWorksByOwner(
    String username,
  ) async {
    final wallet = "wallet@$username";
    try {
      final response = await _supabase
          .from(
            'works',
          )
          .select()
          .eq(
            'current_owner_wallet',
            wallet,
          )
          .order(
            'created_at',
            ascending: false,
          );
      return response
          as List<
            dynamic
          >;
    } catch (
      e
    ) {
      debugPrint(
        "⚠️ Nenhuma obra encontrada ou erro na busca: $e",
      );
      return [];
    }
  }
}
