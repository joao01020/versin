import '../data/datasources/dashboard_remote_datasource.dart';
import '../data/datasources/dashboard_local_datasource.dart';
import '../data/models/hardware_status_model.dart';
import '../data/models/appointment_model.dart';

/// [DashboardRepository] coordinates data streams from local and remote sources,
/// converting raw database maps into strongly-typed domain models.
/// [DashboardRepository] coordena os fluxos de dados de fontes locais e remotas,
/// convertendo mapas brutos de banco de dados em modelos de domínio fortemente tipados.
class DashboardRepository {
  // Injecting independent data sources / Injetando as fontes de dados independentes
  final DashboardRemoteDatasource _remoteDatasource = DashboardRemoteDatasource();
  final DashboardLocalDatasource _localDatasource = DashboardLocalDatasource();

  /// Intercepts the raw remote hardware stream and maps it into a robust List of Models.
  /// Intercepta o stream bruto do hardware remoto e o mapeia em uma lista robusta de Models.
  Stream<List<HardwareStatusModel>> getHardwareStatusStream() {
    return _remoteDatasource.getHardwareStatusStream().map((rawList) {
      return rawList.map((map) => HardwareStatusModel.fromMap(map)).toList();
    });
  }

  /// Fetches cached local data and returns structured domains to the controller.
  /// Busca dados locais em cache e retorna domínios estruturados para o controller.
  Future<List<AppointmentModel>> getAppointmentsCache() async {
    try {
      final List<Map<String, dynamic>> rawData = await _localDatasource.getLocalAppointments();
      return rawData.map((map) => AppointmentModel.fromMap(map)).toList();
    } catch (_) {
      // Safe fallback if local table doesn't exist yet / Retorno seguro caso a tabela local não exista ainda
      return [];
    }
  }
}