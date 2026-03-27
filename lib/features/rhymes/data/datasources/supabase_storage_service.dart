import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/features/rhymes/data/models/author_hash.dart';
// Novo Import para usar o HashHelper real que criamos
import 'package:versin/features/rhymes/data/datasources/utils/hash_helper.dart';

class SupabaseStorageService {
  final _supabase = Supabase.instance.client;

  /// Registra a obra completa, gera o Hash real e salva rimas utilizadas
  Future<void> registerWorkInSupa(String title, String content, String username, {List<String>? usedRhymes}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Usuário não autenticado");

    final wallet = "wallet@$username";
    
    // Geração de Hash Real usando o nosso HashHelper
    final hash = HashHelper.generateVersinHash(
      lyric: content, 
      userWallet: wallet, 
      username: username
    );

    final newWork = {
      'title': title,
      'content': content,
      'original_hash': hash,
      'current_owner_wallet': wallet,
      'author_id': user.id,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'original',
      // Armazena as rimas para análise de tendências futura
      'meta_data': {
        'used_rhymes': usedRhymes ?? [],
        'versin_version': '1.0.0-genesis'
      }
    };

    try {
      await _supabase.from('works').insert(newWork);
      
      // LOGICA REAL: Se houver rimas, incrementamos o score global delas agora
      if (usedRhymes != null && usedRhymes.isNotEmpty) {
        for (var rhyme in usedRhymes) {
          await _supabase.rpc('increment_word_score', params: {'word_param': rhyme.toLowerCase()});
        }
      }

      print("🚀 Obra registrada e assinada: $hash");
    } catch (e) {
      print("❌ Erro ao registrar obra: $e");
      rethrow; 
    }
  }

  /// Salva uma letra isolada e seu hash (utilizado pelo botão Finalizar da ChatPage)
  Future<void> saveLyric(String content, String hash) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('lyrics_history').insert({
        'profile_id': user.id,
        'content': content,
        'hash_signature': hash,
        'created_at': DateTime.now().toIso8601String(),
      });
      print("✅ Letra salva no histórico do Versin.");
    } catch (e) {
      print("⚠️ Erro ao salvar histórico: $e");
    }
  }

  Future<void> transferOwnership(String workHash, String newDestinationWallet) async {
    try {
      await _supabase
          .from('works')
          .update({
            'current_owner_wallet': newDestinationWallet, 
            'status': 'transferred',
            'transferred_at': DateTime.now().toIso8601String(),
          })
          .eq('original_hash', workHash);
      print("✅ Sucesso: Transferido para a carteira $newDestinationWallet");
    } catch (e) {
      print("❌ Falha na transferência: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> listWorksByOwner(String username) async {
    final wallet = "wallet@$username";
    try {
      final response = await _supabase
          .from('works')
          .select()
          .eq('current_owner_wallet', wallet)
          .order('created_at', ascending: false);
      return response as List<dynamic>;
    } catch (e) {
      print("⚠️ Nenhuma obra encontrada ou erro na busca: $e");
      return [];
    }
  }
}