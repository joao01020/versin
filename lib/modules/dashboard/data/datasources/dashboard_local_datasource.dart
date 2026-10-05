import 'package:versin/core/database/database_helper.dart';

// ============================================================
// DASHBOARD LOCAL DATASOURCE
// ============================================================
//
// Responsável pelo acesso aos dados locais do Dashboard.
//
// Utiliza a instância compartilhada do DatabaseHelper para
// acessar o banco SQLite do dispositivo.
//
// ============================================================

class DashboardLocalDatasource {
  // ============================================================
  // DATABASE
  // ============================================================

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // ============================================================
  // LOCAL APPOINTMENTS
  // ============================================================
  //
  // Retorna os compromissos armazenados localmente no SQLite.
  //
  // ============================================================

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  getLocalAppointments() async {
    final database = await _databaseHelper.database;

    return database.query(
      'appointments',
    );
  }
}
