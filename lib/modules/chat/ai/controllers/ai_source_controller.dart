import 'package:flutter/foundation.dart';

import '../services/provider/ai_provider_service.dart';

// ============================================================
// AI SOURCE CONTROLLER
// ============================================================
//
// Responsável pelo estado da fonte atual de IA.
//
// Exemplos:
//
// VERSIN
//
// ou:
//
// API PRIVADA
// OpenAI
// gpt-4o-mini
//
// Este controller NÃO:
//
// - salva API Key;
// - conhece FlutterSecureStorage;
// - faz requisições HTTP;
// - desconta quota.
//
// ============================================================

class AiSourceController
    extends
        ChangeNotifier {
  // ============================================================
  // ESTADO
  // ============================================================

  AiProviderSource _source = AiProviderSource.versin;

  String _provider = 'versin';

  String? _model;

  // ============================================================
  // GETTERS
  // ============================================================

  AiProviderSource get source => _source;

  String get provider => _provider;

  String? get model => _model;

  // ============================================================
  // HELPERS
  // ============================================================

  bool get usingVersinApi =>
      _source ==
      AiProviderSource.versin;

  bool get usingPrivateApi =>
      _source ==
      AiProviderSource.privateApi;

  bool get hasModel =>
      _model !=
          null &&
      _model!.trim().isNotEmpty;

  // ============================================================
  // LABEL
  // ============================================================

  String get sourceLabel {
    if (usingPrivateApi) {
      return 'API própria';
    }

    return 'IA Versin';
  }

  // ============================================================
  // PROVIDER LABEL
  // ============================================================

  String get providerLabel {
    if (usingVersinApi) {
      return 'Versin';
    }

    final normalized = _provider.trim();

    if (normalized.isEmpty) {
      return 'API privada';
    }

    return normalized;
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  String get description {
    if (usingVersinApi) {
      return 'Utilizando a infraestrutura de IA Versin.';
    }

    if (hasModel) {
      return '$providerLabel • $_model';
    }

    return 'Utilizando sua API privada.';
  }

  // ============================================================
  // ATIVAR VERSIN
  // ============================================================

  void activateVersin({
    bool notify = true,
  }) {
    final changed =
        _source !=
            AiProviderSource.versin ||
        _provider !=
            'versin' ||
        _model !=
            null;

    _source = AiProviderSource.versin;

    _provider = 'versin';

    _model = null;

    if (notify &&
        changed) {
      notifyListeners();
    }
  }

  // ============================================================
  // ATIVAR API PRIVADA
  // ============================================================

  void activatePrivate({
    required String provider,
    String? model,
    bool notify = true,
  }) {
    final normalizedProvider = provider.trim();

    final normalizedModel = _normalizeNullable(
      model,
    );

    final finalProvider = normalizedProvider.isEmpty
        ? 'private'
        : normalizedProvider;

    final changed =
        _source !=
            AiProviderSource.privateApi ||
        _provider !=
            finalProvider ||
        _model !=
            normalizedModel;

    _source = AiProviderSource.privateApi;

    _provider = finalProvider;

    _model = normalizedModel;

    if (notify &&
        changed) {
      notifyListeners();
    }
  }

  // ============================================================
  // APLICAR RESULTADO DO PROVIDER
  // ============================================================
  //
  // Esse é o método principal depois que AiProviderService
  // retornar uma resposta.
  //
  // Exemplo:
  //
  // final result = await aiProviderService.generate(...);
  //
  // aiSourceController.applyResult(result);
  //
  // ============================================================

  void applyResult(
    AiProviderResult result,
  ) {
    switch (result.source) {
      // ========================================================
      // VERSIN
      // ========================================================

      case AiProviderSource.versin:
        activateVersin();

        break;

      // ========================================================
      // API PRIVADA
      // ========================================================

      case AiProviderSource.privateApi:
        activatePrivate(
          provider:
              result.provider ??
              'private',

          model: result.model,
        );

        break;
    }
  }

  // ============================================================
  // APLICAR METADATA
  // ============================================================
  //
  // Útil quando recebemos:
  //
  // {
  //   source: privateApi,
  //   provider: OpenAI,
  //   model: gpt-4o-mini
  // }
  //
  // ============================================================

  void applyMetadata(
    Map<
      String,
      dynamic
    >?
    metadata,
  ) {
    if (metadata ==
        null) {
      return;
    }

    final source = metadata['source']?.toString().trim().toLowerCase();

    final provider = metadata['provider']?.toString().trim();

    final model = _normalizeNullable(
      metadata['model']?.toString(),
    );

    final usedPrivateApi = _parseBool(
      metadata['used_private_api'],
    );

    final usedVersinApi = _parseBool(
      metadata['used_versin_api'],
    );

    // ==========================================================
    // PRIVATE EXPLÍCITO
    // ==========================================================

    if (usedPrivateApi ==
        true) {
      activatePrivate(
        provider:
            provider?.isNotEmpty ==
                true
            ? provider!
            : 'private',

        model: model,
      );

      return;
    }

    // ==========================================================
    // VERSIN EXPLÍCITO
    // ==========================================================

    if (usedVersinApi ==
        true) {
      activateVersin();

      return;
    }

    // ==========================================================
    // SOURCE
    // ==========================================================

    if (source ==
            'privateapi' ||
        source ==
            'private_api' ||
        source ==
            'private' ||
        source ==
            'user') {
      activatePrivate(
        provider:
            provider?.isNotEmpty ==
                true
            ? provider!
            : 'private',

        model: model,
      );

      return;
    }

    if (source ==
            'versin' ||
        source ==
            'official') {
      activateVersin();
    }
  }

  // ============================================================
  // SINCRONIZAR COM AI PROVIDER SERVICE
  // ============================================================
  //
  // Permite descobrir a fonte ANTES de enviar uma mensagem.
  //
  // ============================================================

  Future<
    void
  >
  syncWithProvider(
    AiProviderService service,
  ) async {
    try {
      final config = await service.getPrivateConfig();

      if (config.canUsePrivateApi) {
        activatePrivate(
          provider: config.provider,

          model: config.model,
        );

        return;
      }

      activateVersin();
    } catch (
      error
    ) {
      debugPrint(
        '[AI SOURCE] '
        'Erro ao sincronizar fonte: $error',
      );

      activateVersin();
    }
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    activateVersin();
  }

  // ============================================================
  // NORMALIZAR STRING
  // ============================================================

  String? _normalizeNullable(
    String? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // PARSE BOOL
  // ============================================================

  bool? _parseBool(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is bool) {
      return value;
    }

    if (value
        is num) {
      return value !=
          0;
    }

    final normalized = value.toString().trim().toLowerCase();

    if (normalized ==
            'true' ||
        normalized ==
            '1') {
      return true;
    }

    if (normalized ==
            'false' ||
        normalized ==
            '0') {
      return false;
    }

    return null;
  }
}
