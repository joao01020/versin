import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final _supabase = Supabase.instance.client;

  // Retorna o ID do usuário logado para evitar buscas repetitivas
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // 1. CRIAR OU ATUALIZAR PERFIL
  // O trigger 'on_auth_user_created' no seu SQL já cria o perfil automaticamente.
  // Este método agora serve para completar dados como a wallet.
  Future<void> updateWallet(String username) async {
    if (_currentUserId == null) return;

    final wallet = "wallet@$username";
    await _supabase.from('profiles').update({
      'username': username, // Garante que o username esteja atualizado
      'wallet_address': wallet,
    }).eq('id', _currentUserId!);
  }

  // 2. SALVAR MEMÓRIA DA IA
  // Alterado para usar o ID autenticado, garantindo que um usuário não altere a memória de outro.
  Future<void> updateIAMemory(String newMemory) async {
    if (_currentUserId == null) return;

    await _supabase
        .from('profiles')
        .update({'ia_memory': newMemory})
        .eq('id', _currentUserId!);
  }

  // 3. SALVAR FAVORITO (Pesquisa + Resposta + Data)

  Future<void> saveToFavorites({
    required String query,
    required String response,
  }) async {
    if (_currentUserId == null) return;

    try {
      await _supabase.from('favorites').insert({
        'user_id': _currentUserId, 
        'query': query,
        'response': response,
      });
      print("⭐ Salvo nos favoritos!");
    } catch (e) {
      print("Erro ao favoritar: $e");
    }
  }

  // 4. SALVAR CONFIGURAÇÕES
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    if (_currentUserId == null) return;

    await _supabase
        .from('profiles')
        .update({'settings': newSettings})
        .eq('id', _currentUserId!);
  }

  // 5. BUSCAR DADOS DO PERFIL (Útil para o Header/Drawer)
  Future<Map<String, dynamic>?> getProfileData() async {
    if (_currentUserId == null) return null;

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', _currentUserId!)
        .single();
    return data;
  }
}