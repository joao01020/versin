import 'package:supabase_flutter/supabase_flutter.dart';

class MemoryService {
  final _supabase = Supabase.instance.client;

  // 1. BUSCAR O QUE A IA JÁ SABE SOBRE O USUÁRIO
  Future<String> retrieveMemory(String username) async {
    final data = await _supabase
        .from('profiles')
        .select('ia_memory')
        .eq('username', username)
        .single();
    
    // Retorno padrão caso a memória esteja vazia no banco
    return data['ia_memory'] ?? "O usuário prefere rimas de Trap.";
  }

  // 2. ATUALIZAR A MEMÓRIA (O "APRENDIZADO")
  // Exemplo: "Usuário gosta de BPM 140 e rimas sobre a vida em Osasco"
  Future<void> learnNewPattern(String username, String newKnowledge) async {
    // Primeiro recuperamos a memória existente
    String oldMemory = await retrieveMemory(username);

    // Concatenamos a memória antiga com o novo aprendizado
    String updatedMemory = "$oldMemory | $newKnowledge";

    // Salvamos a atualização no banco de dados Supabase
    await _supabase
        .from('profiles')
        .update({'ia_memory': updatedMemory})
        .eq('username', username);
    
    // Log técnico para o terminal do Linux no seu Dell
    print("🧠 Versin evoluiu: $newKnowledge");
  }
}