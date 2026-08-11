import 'package:flutter/material.dart';

import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/brain/data/vault_manager.dart';
import 'package:versin/modules/brain/services/creative_vision_service.dart';

/// BrainController:
/// O cérebro central do Versin.
///
/// Ele herda toda a infraestrutura do RhymesController
/// e adiciona:
///
/// - interpretação criativa local;
/// - visão atual da música;
/// - integração com o Vault;
/// - memória criativa da sessão.
class BrainController
    extends
        RhymesController {
  // ============================================================
  // SERVIÇOS
  // ============================================================

  final CreativeVisionService _creativeVisionService = CreativeVisionService();

  // ============================================================
  // VISÃO CRIATIVA ATUAL
  // ============================================================

  CreativeVision? _currentVision;

  CreativeVision? get currentVision => _currentVision;

  bool get hasCreativeVision =>
      _currentVision !=
          null &&
      !_currentVision!.isEmpty;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  BrainController() : super();

  // ============================================================
  // ANALISAR IMAGINAÇÃO / ENTRADA CRIATIVA
  // ============================================================

  CreativeVision analyzeCreativeInput(
    String text,
  ) {
    final normalizedText = text.trim();

    if (normalizedText.isEmpty) {
      _currentVision = null;

      notifyListeners();

      return const CreativeVision(
        originalWords: [],
        emotions: [],
        themes: [],
        images: [],
        states: [],
        summary: 'Ainda não tenho material suficiente para enxergar um caminho.',
      );
    }

    final vision = _creativeVisionService.analyze(
      normalizedText,
    );

    _currentVision = vision;

    notifyListeners();

    return vision;
  }

  // ============================================================
  // ATUALIZAR VISÃO COM NOVO TEXTO
  // ============================================================

  CreativeVision updateCreativeVision(
    String text,
  ) {
    return analyzeCreativeInput(
      text,
    );
  }

  // ============================================================
  // LIMPAR VISÃO CRIATIVA
  // ============================================================

  void clearCreativeVision() {
    _currentVision = null;

    notifyListeners();
  }

  // ============================================================
  // PALAVRAS ORIGINAIS DA VISÃO
  // ============================================================

  List<
    String
  >
  get creativeOriginalWords {
    return _currentVision?.originalWords ??
        [];
  }

  // ============================================================
  // EMOÇÕES DETECTADAS
  // ============================================================

  List<
    String
  >
  get creativeEmotions {
    return _currentVision?.emotions ??
        [];
  }

  // ============================================================
  // TEMAS DETECTADOS
  // ============================================================

  List<
    String
  >
  get creativeThemes {
    return _currentVision?.themes ??
        [];
  }

  // ============================================================
  // IMAGENS DETECTADAS
  // ============================================================

  List<
    String
  >
  get creativeImages {
    return _currentVision?.images ??
        [];
  }

  // ============================================================
  // ESTADOS DETECTADOS
  // ============================================================

  List<
    String
  >
  get creativeStates {
    return _currentVision?.states ??
        [];
  }

  // ============================================================
  // RESUMO DA VISÃO
  // ============================================================

  String get creativeSummary {
    return _currentVision?.summary ??
        '';
  }

  // ============================================================
  // TODAS AS DESCOBERTAS CRIATIVAS
  // ============================================================

  List<
    String
  >
  get creativeDiscoveries {
    final result =
        <
          String
        >[];

    void addUnique(
      Iterable<
        String
      >
      values,
    ) {
      for (final value in values) {
        final normalized = value.trim();

        if (normalized.isEmpty) {
          continue;
        }

        if (!result.contains(
          normalized,
        )) {
          result.add(
            normalized,
          );
        }
      }
    }

    addUnique(
      creativeEmotions,
    );

    addUnique(
      creativeThemes,
    );

    addUnique(
      creativeImages,
    );

    addUnique(
      creativeStates,
    );

    return result;
  }

  // ============================================================
  // ADICIONAR DESCOBERTA À BIBLIOTECA
  // ============================================================

  Future<
    void
  >
  addCreativeDiscovery(
    String word, {
    bool priority = false,
  }) async {
    final normalized = word.trim();

    if (normalized.isEmpty) {
      return;
    }

    await addWord(
      normalized,
      priority,
    );
  }

  // ============================================================
  // ADICIONAR VÁRIAS DESCOBERTAS À BIBLIOTECA
  // ============================================================

  Future<
    int
  >
  addCreativeDiscoveries(
    Iterable<
      String
    >
    words, {
    bool priority = false,
  }) async {
    return await addWords(
      words,
      priority: priority,
    );
  }

  // ============================================================
  // SINCRONIZAR VAULT COM A BIBLIOTECA
  // ============================================================

  /// Sincroniza o conhecimento bruto do Vault
  /// para a memória ativa.
  ///
  /// Útil para carregar grandes bases de conhecimento
  /// para uso imediato no Chat.
  Future<
    void
  >
  syncVaultToLibrary() async {
    try {
      final rimasNoVault = await VaultManager.importFromFile();

      if (rimasNoVault.isEmpty) {
        debugPrint(
          'Vault vazio. Nenhuma palavra para sincronizar.',
        );

        return;
      }

      final addedCount = await addWords(
        rimasNoVault,
      );

      debugPrint(
        'Sincronização concluída: '
        '$addedCount de ${rimasNoVault.length} '
        'neurônios novos ativados.',
      );
    } catch (
      e
    ) {
      debugPrint(
        'Erro ao sincronizar Vault: $e',
      );
    }
  }

  // ============================================================
  // PERSISTIR MEMÓRIA NO VAULT
  // ============================================================

  /// Salva o estado atual da memória ativa
  /// de volta para o Vault.
  ///
  /// Transforma a lista de rimas atual
  /// em um arquivo .md estruturado.
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
          'Memória ativa persistida no Vault em: $path',
        );
      }
    } catch (
      e
    ) {
      debugPrint(
        'Erro ao persistir memória no Vault: $e',
      );
    }
  }

  // ============================================================
  // BUSCA PROFUNDA NO VAULT
  // ============================================================

  /// Busca conteúdo dentro do Vault.
  ///
  /// Futuramente pode ser usado para:
  ///
  /// - recuperar contextos;
  /// - consultar letras antigas;
  /// - encontrar padrões;
  /// - buscar conceitos;
  /// - conectar composições passadas.
  Future<
    String
  >
  searchInVault(
    String query,
  ) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return '';
    }

    try {
      return await VaultManager.readNote(
        normalizedQuery,
      );
    } catch (
      e
    ) {
      debugPrint(
        'Erro ao pesquisar no Vault: $e',
      );

      return '';
    }
  }
}
