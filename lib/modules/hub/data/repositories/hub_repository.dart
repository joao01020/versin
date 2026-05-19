import '../datasources/hub_remote_datasource.dart';

/// [IHubRepository] define o contrato de tudo o que o Hub é capaz de fazer
/// em nível de dados (ler status e enviar ordens).
abstract class IHubRepository {
  Stream<List<Map<String, dynamic>>> streamHardwareStatus();
  Future<void> dispatchModeCommand(String command, String modeKey);
}

/// [HubRepository] coordena a distribuição de ordens e a captura de telemetria do Hub.
class HubRepository implements IHubRepository {
  final HubRemoteDatasource _remoteDatasource;

  // Injeção de dependência do datasource de infraestrutura
  HubRepository(this._remoteDatasource);

  @override
  /// 📡 LEITURA: Retorna o fluxo contínuo do banco de dados em tempo real para o ID 1
  Stream<List<Map<String, dynamic>>> streamHardwareStatus() {
    try {
      return _remoteDatasource.getHardwareStream(hardwareId: 1);
    } catch (e) {
      print("HubRepository: Erro ao abrir stream de telemetria -> $e");
      rethrow;
    }
  }

  @override
  /// ⚡ ESCRITA: Despacha o comando operacional para o chassi principal (ID 1 fixo)
  Future<void> dispatchModeCommand(String command, String modeKey) async {
    try {
      await _remoteDatasource.updateHardwareCommand(
        hardwareId: 1, // Filtro padrão do seu chassi físico no ecossistema
        modeKey: modeKey,
        command: command,
      );
    } catch (e) {
      print("HubRepository: Falha ao despachar comando operacional -> $e");
      rethrow;
    }
  }
}