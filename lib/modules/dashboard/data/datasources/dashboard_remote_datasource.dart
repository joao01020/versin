import 'package:supabase_flutter/supabase_flutter.dart';

/// [DashboardRemoteDatasource] directly requests raw queries from the cloud infrastructure.
class DashboardRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  /// Emits the raw pipeline stream of maps directly from the Supabase hardware table.
  Stream<List<Map<String, dynamic>>> getHardwareStatusStream() {
    return _client
        .from('status_hardware')
        .stream(primaryKey: ['id'])
        .eq('id', 1);
  }
}