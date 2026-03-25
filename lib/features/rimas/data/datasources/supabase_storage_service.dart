import 'package:supabase_flutter/supabase_flutter.dart';
// Importação absoluta - substitui o '../models' que estava falhando
import 'package:versin/features/rimas/data/models/obra_reg_model.dart';

class SupabaseStorageService {
  final _supabase = Supabase.instance.client;

  Future<void> registrarObraNoSupa(String titulo, String conteudo, String username) async {
    final wallet = "wallet@$username";
    
    // Se o VS Code sublinhar 'ObraRegModel' em vermelho, 
    // passe o mouse em cima para ver se ele sugere um "Quick Fix"
    final hash = ObraRegModel.gerarAssinatura(titulo, conteudo);

    final novaObra = ObraRegModel(
      titulo: titulo,
      conteudo: conteudo,
      hash: hash,
      donoWallet: wallet,
    );

    try {
      await _supabase.from('obras').insert(novaObra.toSupabase());
      print("🚀 Obra registrada: $hash");
    } catch (e) {
      print("❌ Erro ao registrar: $e");
      rethrow; 
    }
  }

  Future<void> transferirPropriedade(String hashObra, String novaWalletDestino) async {
    try {
      await _supabase
          .from('obras')
          .update({
            'dono_atual_wallet': novaWalletDestino, 
            'status': 'transferido'
          })
          .eq('hash_original', hashObra);
      print("✅ Sucesso: Transferido para $novaWalletDestino");
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> listarObrasPorDono(String username) async {
    final wallet = "wallet@$username";
    try {
      final response = await _supabase
          .from('obras')
          .select()
          .eq('dono_atual_wallet', wallet)
          .order('criado_em', ascending: false);
      return response as List<dynamic>;
    } catch (e) {
      return [];
    }
  }
}