import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _defaultMemory = 'O usuário prefere rimas de Trap.';

  // =========================================================
  // BUSCAR MEMÓRIA
  // =========================================================

  Future<
    String
  >
  retrieveMemory(
    String username,
  ) async {
    final normalizedUsername = username.trim();

    if (normalizedUsername.isEmpty) {
      return _defaultMemory;
    }

    try {
      final data = await _supabase
          .from(
            'profiles',
          )
          .select(
            'ia_memory',
          )
          .eq(
            'username',
            normalizedUsername,
          )
          .maybeSingle();

      if (data ==
          null) {
        return _defaultMemory;
      }

      final memory = data['ia_memory']?.toString().trim();

      if (memory ==
              null ||
          memory.isEmpty) {
        return _defaultMemory;
      }

      return memory;
    } catch (
      e
    ) {
      debugPrint(
        'Erro ao recuperar memória da IA: $e',
      );

      return _defaultMemory;
    }
  }

  // =========================================================
  // APRENDER NOVO PADRÃO
  // =========================================================

  Future<
    void
  >
  learnNewPattern(
    String username,
    String newKnowledge,
  ) async {
    final normalizedUsername = username.trim();
    final normalizedKnowledge = newKnowledge.trim();

    if (normalizedUsername.isEmpty ||
        normalizedKnowledge.isEmpty) {
      return;
    }

    try {
      final oldMemory = await retrieveMemory(
        normalizedUsername,
      );

      final updatedMemory = '$oldMemory | $normalizedKnowledge';

      await _supabase
          .from(
            'profiles',
          )
          .update(
            {
              'ia_memory': updatedMemory,
            },
          )
          .eq(
            'username',
            normalizedUsername,
          );

      debugPrint(
        '🧠 Versin evoluiu: $normalizedKnowledge',
      );
    } catch (
      e
    ) {
      debugPrint(
        'Erro ao atualizar memória da IA: $e',
      );

      rethrow;
    }
  }
}
