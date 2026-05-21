import 'package:supabase_flutter/supabase_flutter.dart';

/// [HubRemoteDatasource] lida diretamente com as mutações e fluxos de dados na nuvem.
class HubRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  /// 📡 SÊNIOR: Captura o fluxo contínuo de dados (Stream) do Supabase filtrado por ID.
  Stream<List<Map<String, dynamic>>> getHardwareStream({required int hardwareId}) {
    return _client
        .from('status_hardware')
        .stream(primaryKey: ['id'])
        .eq('id', hardwareId);
  }

  /// ⚡ Atualiza a coluna de status e comando no banco remoto para o ID do hardware correspondente.
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
          'updated_at': DateTime.now().toUtc().toIso8601String(), // SÊNIOR: Forçando UTC para bater com a telemetria do app
        })
        .eq('id', hardwareId);
  }
}