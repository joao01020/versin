import '../datasources/hub_remote_datasource.dart';

/// [HubRepository] coordena a distribuição de ordens de comando para o Hub.
class HubRepository {
  final HubRemoteDatasource _remoteDatasource = HubRemoteDatasource();

  /// Despacha o comando operacional para o chassi principal (ID 1 fixo do sistema)
  Future<void> dispatchModeCommand(String command, String modeKey) async {
    await _remoteDatasource.updateHardwareCommand(
      hardwareId: 1, // Filtro padrão do seu chassi físico
      modeKey: modeKey,
      command: command,
    );
  }
}