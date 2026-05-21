import 'package:flutter/foundation.dart'; // Necessário para o debugPrint
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

  /// Injeção de dependência do datasource de infraestrutura
  HubRepository(this._remoteDatasource);

  @override
  /// 📡 LEITURA: Retorna o fluxo contínuo do banco de dados em tempo real.
  /// O hardwareId é injetado ou fixado conforme a necessidade do sistema.
  Stream<List<Map<String, dynamic>>> streamHardwareStatus() {
    try {
      // Garantimos que a fonte de dados seja consultada com o ID padrão 1
      return _remoteDatasource.getHardwareStream(hardwareId: 1);
    } catch (e, stackTrace) {
      debugPrint("HubRepository: Erro ao abrir stream de telemetria: $e");
      // Caso não consiga retornar o stream, lançamos o erro para ser tratado na camada superior
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  @override
  /// ⚡ ESCRITA: Despacha o comando operacional para o chassi principal.
  Future<void> dispatchModeCommand(String command, String modeKey) async {
    try {
      await _remoteDatasource.updateHardwareCommand(
        hardwareId: 1, 
        modeKey: modeKey,
        command: command,
      );
    } catch (e, stackTrace) {
      debugPrint("HubRepository: Falha ao despachar comando operacional: $e");
      // Propagamos o erro para a UI ou camada de controle saber que a ação falhou
      Error.throwWithStackTrace(e, stackTrace);
    }
  }
}