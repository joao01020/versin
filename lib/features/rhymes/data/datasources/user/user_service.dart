import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final _supabase = Supabase.instance.client;

  // 1. CRIAR CONTA E WALLET
  Future<void> createUser(String username) async {
    final wallet = "wallet@$username";
    await _supabase.from('profiles').insert({
      'username': username,
      'wallet_address': wallet,
    });
  }

  // 2. SALVAR MEMÓRIA DA IA (O estilo do João, as gírias, etc)
  Future<void> updateIAMemory(String username, String newMemory) async {
    await _supabase
        .from('profiles')
        .update({'ia_memory': newMemory})
        .eq('username', username);
  }

  // 3. SALVAR FAVORITO (Pesquisa + Resposta + Data)
  Future<void> saveToFavorites(
    String username,
    String query,
    String response,
  ) async {
    // Primeiro pegamos o ID do perfil pelo username
    final profile = await _supabase
        .from('profiles')
        .select('id')
        .eq('username', username)
        .single();

    await _supabase.from('favorites').insert({
      'profile_id': profile['id'],
      'query': query,
      'response': response,
    });
    print("⭐ Salvo nos favoritos!");
  }

  // 4. SALVAR CONFIGURAÇÕES
  Future<void> updateSettings(
    String username,
    Map<String, dynamic> newSettings,
  ) async {
    await _supabase
        .from('profiles')
        .update({'settings': newSettings})
        .eq('username', username);
  }
}
