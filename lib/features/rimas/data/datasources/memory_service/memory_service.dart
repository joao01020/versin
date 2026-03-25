import 'package:supabase_flutter/supabase_flutter.dart';

class MemoryService {
  final _supabase = Supabase.instance.client;

  // 1. BUSCAR O QUE A IA JÁ SABE SOBRE O JOÃO
  Future<String> recuperarMemoria(String username) async {
    final data = await _supabase
        .from('profiles')
        .select('ia_memory')
        .eq('username', username)
        .single();
    
    return data['ia_memory'] ?? "O usuário prefere rimas de Trap.";
  }

  // 2. ATUALIZAR A MEMÓRIA (O "APRENDIZADO")
  // Exemplo: "Usuário gosta de BPM 140 e rimas sobre a vida em Osasco"
  Future<void> aprenderNovoPadrao(String username, String novoConhecimento) async {
    // Primeiro pegamos a memória atual
    String memoriaAntiga = await recuperarMemoria(username);

    // Criamos a nova memória somando o que ele já sabia + o novo
    String memoriaAtualizada = "$memoriaAntiga | $novoConhecimento";

    // Salvamos de volta no Supabase
    await _supabase
        .from('profiles')
        .update({'ia_memory': memoriaAtualizada})
        .eq('username', username);
    
    print("🧠 Versin evoluiu: $novoConhecimento");
  }
}