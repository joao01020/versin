import 'package:supabase_flutter/supabase_flutter.dart';
// Importação absoluta - substitui o '../models' que estava falhando
import 'package:versin/features/rimas/data/models/author_hash.dart';

class SupabaseStorageService {
  final _supabase = Supabase.instance.client;

  Future<void> registerWorkInSupa(String title, String content, String username) async {
    final wallet = "wallet@$username";
    
    // Se o VS Code sublinhar 'AuthorHash' em vermelho, 
    // passe o mouse em cima para ver se ele sugere um "Quick Fix"
    final hash = AuthorHash.generateSignature(title, content);

    final newWork = AuthorHash(
      title: title,
      content: content,
      hash: hash,
      ownerWallet: wallet,
    );

    try {
      await _supabase.from('works').insert(newWork.toSupabase());
      print("🚀 Obra registrada com sucesso: $hash");
    } catch (e) {
      print("❌ Erro ao registrar obra: $e");
      rethrow; 
    }
  }

  Future<void> transferOwnership(String workHash, String newDestinationWallet) async {
    try {
      await _supabase
          .from('works')
          .update({
            'current_owner_wallet': newDestinationWallet, 
            'status': 'transferred'
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