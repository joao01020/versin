import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// DASHBOARD REMOTE DATASOURCE
// ============================================================
//
// Responsável pelo acesso aos dados remotos utilizados pelo
// Dashboard.
//
// Este datasource conversa diretamente com o Supabase e deve
// permanecer focado apenas em operações de infraestrutura:
//
// - consultas;
// - streams;
// - dados brutos.
//
// Regras de negócio devem permanecer fora deste arquivo.
//
// ============================================================

class DashboardRemoteDatasource {
  // ============================================================
  // SUPABASE CLIENT
  // ============================================================

  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // ============================================================
  // HARDWARE STATUS STREAM
  // ============================================================
  //
  // Retorna um stream em tempo real com o estado do hardware.
  //
  // A tabela monitorada é:
  //
  // status_hardware
  //
  // Atualmente o Dashboard acompanha o registro de ID 1.
  //
  // ============================================================

  Stream<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  getHardwareStatusStream() {
    return _supabaseClient
        .from(
          'status_hardware',
        )
        .stream(
          primaryKey: [
            'id',
          ],
        )
        .eq(
          'id',
          1,
        );
  }
}
