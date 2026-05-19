import 'package:flutter/material.dart';
import '../data/models/hub_mode_model.dart';
import '../data/repositories/hub_repository.dart'; // <-- NOVO IMPORT

class HubController {
  // Instanciando o repositório do módulo
  final HubRepository _repository = HubRepository(); // <-- INSTÂNCIA REAL

  final ValueNotifier<String> currentActiveMode = ValueNotifier<String>("IDLE");
  final ValueNotifier<bool> isSendingCommand = ValueNotifier<bool>(false);
  final TextEditingController walletController = TextEditingController();

  final List<HubModeModel> hubModes = const [
    HubModeModel(
      title: "Studio Mode",
      subtitle: "Interface minimalista ativa - Ícone Vinil",
      icon: Icons.album_outlined,
      modeKey: "STUDIO",
      command: "CMD_SET_MODE:STUDIO",
    ),
    HubModeModel(
      title: "Modo Contrato",
      subtitle: "Trava display em modo de assinatura e business",
      icon: Icons.description_outlined,
      modeKey: "CONTRACT",
      command: "CMD_SET_MODE:CONTRACT",
    ),
    HubModeModel(
      title: "Vincular Artista",
      subtitle: "Varredura local e ondas de pareamento RF",
      icon: Icons.sensors,
      modeKey: "ARTIST_LINK",
      command: "CMD_SET_MODE:ARTIST_LINK",
    ),
  ];

  /// Transmite a instrução serial para o chassi via Supabase real
  Future<void> sendCommandToHub(String command, String modeName) async {
    if (isSendingCommand.value) return;

    isSendingCommand.value = true;

    try {
      debugPrint("Transmitindo barramento serial para o chassi: $command");
      
      // 🔥 AGORA CONECTADO À INFRAESTRUTURA REAL
      await _repository.dispatchModeCommand(command, modeName);
      
      currentActiveMode.value = modeName;
    } catch (e) {
      debugPrint("Falha ao comunicar modo com barramento local: $e");
    } finally {
      isSendingCommand.value = false;
    }
  }

  void dispose() {
    currentActiveMode.dispose();
    isSendingCommand.dispose();
    walletController.dispose();
  }
}