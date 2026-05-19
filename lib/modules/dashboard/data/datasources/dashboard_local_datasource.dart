import 'package:versin/core/database/database_helper.dart';

/// [DashboardLocalDatasource] accesses internal device storage when network nodes are dark.
class DashboardLocalDatasource {
  // ⚡ ACESSO CORRIGIDO: Invocando a instância unificada (Singleton) do chassi SQLite
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Fetches local cached appointments from device's SQLite partition.
  Future<List<Map<String, dynamic>>> getLocalAppointments() async {
    final db = await _dbHelper.database;
    // 'appointments' seria o nome da sua tabela local no SQFlite
    return await db.query('appointments'); 
  }
}