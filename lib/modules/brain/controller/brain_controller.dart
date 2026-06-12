import 'package:flutter/material.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/brain/data/vault_manager.dart';

/// BrainController: O cérebro central do Versin.
/// Ele herda a infraestrutura de rimas e estende com a gestão do Vault (Conhecimento Infinito).
class BrainController
    extends
        RhymesController {
  BrainController() : super();

  /// Sincroniza o conhecimento bruto do Vault para a Memória Ativa (Buffer).
  /// Útil para carregar grandes bases de conhecimento para uso imediato no Chat.
  Future<
    void
  >
  syncVaultToLibrary() async {
    try {
      // 1. Lê o "Cérebro de Longo Prazo" (Vault)
      final rimasNoVault = await VaultManager.importFromFile();

      // 2. Orquestra a carga para a "Memória Ativa"
      if (rimasNoVault.isNotEmpty) {
        for (var palavra in rimasNoVault) {
          addWord(
            palavra,
            false,
          );
        }
        debugPrint(
          "Sincronização concluída: ${rimasNoVault.length} neurônios ativados.",
        );
      }
      notifyListeners();
    } catch (
      e
    ) {
      debugPrint(
        "Erro ao sincronizar Vault: $e",
      );
    }
  }

  /// Salva o estado atual da memória ativa de volta para o Vault (Persistência).
  /// Transforma sua lista de rimas atual em um arquivo .md estruturado.
  Future<
    void
  >
  persistMemoryToVault() async {
    try {
      final path = await VaultManager.exportToBackup(
        vocabulary,
      );
      if (path !=
          null) {
        debugPrint(
          "Memória ativa persistida no Vault em: $path",
        );
      }
    } catch (
      e
    ) {
      debugPrint(
        "Erro ao persistir memória no Vault: $e",
      );
    }
  }

  /// Método para realizar uma busca profunda (Deep Search) no Vault.
  /// Futuramente, pode ser usado para buscar contextos em notas .md.
  Future<
    String
  >
  searchInVault(
    String query,
  ) async {
    // Exemplo de integração futura
    return await VaultManager.readNote(
      query,
    );
  }
}
