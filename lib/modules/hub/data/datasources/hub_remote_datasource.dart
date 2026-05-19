import 'package:supabase_flutter/supabase_flutter.dart';

/// [HubRemoteDatasource] lida diretamente com as mutações de dados na nuvem.
class HubRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  /// Atualiza a coluna de status e comando no banco remoto para o ID do hardware correspondente.
  Future<void> updateHardwareCommand({
    required int hardwareId,
    required String modeKey,
    required String command,
  }) async {
    await _client
        .from('status_hardware')
        .update({
          'status': modeKey,
          'last_command': command,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', hardwareId);
  }
}