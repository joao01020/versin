import 'package:flutter/material.dart';

import 'package:versin/modules/chat/models/private_api_config.dart';
import 'package:versin/modules/chat/services/ai_provider_service.dart';
import 'package:versin/modules/chat/services/private_ai_client.dart';
import 'package:versin/modules/chat/services/private_api_service.dart';

// ============================================================
// PRIVATE API SETTINGS PAGE
// ============================================================
//
// Configuração segura da API privada do usuário.
//
// SEGURANÇA:
//
// - a chave NÃO fica em PrivateApiConfig;
// - a chave NÃO é carregada novamente para a UI;
// - a chave é salva apenas no PrivateApiService;
// - PrivateApiService usa flutter_secure_storage;
// - a chave não vai para Supabase;
// - a chave não vai para logs;
// - o teste usa a chave digitada apenas em memória.
//
// ============================================================

class PrivateApiSettingsPage
    extends
        StatefulWidget {
  const PrivateApiSettingsPage({
    super.key,
  });

  @override
  State<
    PrivateApiSettingsPage
  >
  createState() => _PrivateApiSettingsPageState();
}

// ============================================================
// STATE
// ============================================================

class _PrivateApiSettingsPageState
    extends
        State<
          PrivateApiSettingsPage
        > {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFF0D0B1F,
  );

  static const Color _cardColor = Color(
    0xFF17132D,
  );

  static const Color _purple = Color(
    0xFF6A1B9A,
  );

  static const Color _accent = Color(
    0xFFE040FB,
  );

  static const Color _green = Color(
    0xFF00E676,
  );

  static const Color _red = Color(
    0xFFFF5252,
  );

  // ============================================================
  // SERVICES
  // ============================================================

  late final PrivateApiService _privateApiService;

  late final PrivateAiClient _privateAiClient;

  late final AiProviderService _aiProviderService;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _apiKeyController = TextEditingController();

  final TextEditingController _baseUrlController = TextEditingController();

  final TextEditingController _modelController = TextEditingController();

  // ============================================================
  // ESTADO
  // ============================================================

  bool _obscureApiKey = true;

  bool _isLoading = true;

  bool _isSaving = false;

  bool _isTesting = false;

  bool _isRemoving = false;

  bool _isToggling = false;

  bool _hasStoredApiKey = false;

  bool _privateApiEnabled = false;

  String _selectedProvider = 'OpenAI';

  // ============================================================
  // PROVIDERS
  // ============================================================

  static const List<
    String
  >
  _providers = [
    'OpenAI',
    'Anthropic',
    'Google Gemini',
    'Groq',
    'OpenRouter',
    'Custom',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _privateApiService = PrivateApiService();

    _privateAiClient = PrivateAiClient();

    _aiProviderService = AiProviderService(
      privateApiService: _privateApiService,
    );

    _loadConfiguration();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _apiKeyController.dispose();

    _baseUrlController.dispose();

    _modelController.dispose();

    _privateAiClient.dispose();

    super.dispose();
  }

  // ============================================================
  // CARREGAR CONFIGURAÇÃO
  // ============================================================
  //
  // IMPORTANTE:
  //
  // A API Key NÃO é carregada para o TextField.
  //
  // Apenas:
  //
  // - provider;
  // - model;
  // - baseUrl;
  // - enabled;
  // - hasApiKey.
  //
  // ============================================================

  Future<
    void
  >
  _loadConfiguration() async {
    try {
      final config = await _privateApiService.loadConfig();

      if (!mounted) {
        return;
      }

      setState(
        () {
          _selectedProvider = config.providerLabel;

          _modelController.text =
              config.normalizedModel ??
              '';

          _baseUrlController.text =
              config.normalizedBaseUrl ??
              '';

          _hasStoredApiKey = config.hasApiKey;

          _privateApiEnabled = config.canUsePrivateApi;

          _isLoading = false;
        },
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _isLoading = false;
        },
      );

      _showMessage(
        'Não foi possível carregar a configuração.',
        error: true,
      );
    }
  }

  // ============================================================
  // CRIAR CONFIG
  // ============================================================

  PrivateApiConfig _buildConfig({
    required bool enabled,
    required bool hasApiKey,
  }) {
    return PrivateApiConfig(
      provider: _selectedProvider,

      model: _normalizeNullable(
        _modelController.text,
      ),

      baseUrl: _normalizeNullable(
        _baseUrlController.text,
      ),

      enabled: enabled,

      hasApiKey: hasApiKey,
    );
  }

  // ============================================================
  // SALVAR
  // ============================================================

  Future<
    void
  >
  _save() async {
    if (_isSaving) {
      return;
    }

    final typedApiKey = _apiKeyController.text.trim();

    // ==========================================================
    // NOVA CHAVE
    // ==========================================================
    //
    // Se não existe chave armazenada, o usuário precisa
    // informar uma.
    //
    // Se já existe, deixar o campo vazio significa:
    //
    // "manter a chave atual".
    //
    // ==========================================================

    if (!_hasStoredApiKey &&
        typedApiKey.isEmpty) {
      _showMessage(
        'Informe sua API Key.',
        error: true,
      );

      return;
    }

    final willHaveApiKey =
        _hasStoredApiKey ||
        typedApiKey.isNotEmpty;

    final config = _buildConfig(
      enabled: _privateApiEnabled,

      hasApiKey: willHaveApiKey,
    );

    if (!config.hasValidProvider) {
      _showMessage(
        'Provider não suportado.',
        error: true,
      );

      return;
    }

    if (config.isCustom &&
        !config.hasBaseUrl) {
      _showMessage(
        'Informe a Base URL para o provider Custom.',
        error: true,
      );

      return;
    }

    setState(
      () {
        _isSaving = true;
      },
    );

    try {
      // ========================================================
      // NOVA API KEY INFORMADA
      // ========================================================

      if (typedApiKey.isNotEmpty) {
        await _privateApiService.saveConfig(
          config: config,

          apiKey: typedApiKey,
        );
      } else {
        // ======================================================
        // MANTER CHAVE JÁ SALVA
        // ======================================================

        await _privateApiService.saveMetadata(
          config,
        );
      }

      // ========================================================
      // LIMPAR CAMPO
      // ========================================================
      //
      // Depois de salvar, a chave não permanece visível na UI.
      //
      // ========================================================

      _apiKeyController.clear();

      final refreshed = await _privateApiService.loadConfig();

      if (!mounted) {
        return;
      }

      setState(
        () {
          _hasStoredApiKey = refreshed.hasApiKey;

          _privateApiEnabled = refreshed.canUsePrivateApi;
        },
      );

      _showMessage(
        refreshed.canUsePrivateApi
            ? 'API privada salva e ativa.'
            : 'Configuração salva com segurança.',
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível salvar: $error',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isSaving = false;
          },
        );
      }
    }
  }

  // ============================================================
  // TESTAR CONEXÃO
  // ============================================================
  //
  // O teste pode usar:
  //
  // 1. chave digitada agora;
  // 2. chave já salva no secure storage.
  //
  // Nenhuma nova chave é persistida pelo teste.
  //
  // ============================================================

  Future<
    void
  >
  _testConnection() async {
    if (_isTesting) {
      return;
    }

    setState(
      () {
        _isTesting = true;
      },
    );

    try {
      final typedApiKey = _apiKeyController.text.trim();

      String? apiKey;

      if (typedApiKey.isNotEmpty) {
        apiKey = typedApiKey;
      } else {
        apiKey = await _privateApiService.readApiKey();
      }

      if (apiKey ==
              null ||
          apiKey.trim().isEmpty) {
        throw StateError(
          'Informe uma API Key para testar.',
        );
      }

      final config = _buildConfig(
        enabled: true,

        hasApiKey: true,
      );

      if (!config.hasValidProvider) {
        throw StateError(
          'Provider não suportado.',
        );
      }

      if (config.isCustom &&
          !config.hasBaseUrl) {
        throw StateError(
          'Informe a Base URL para o provider Custom.',
        );
      }

      final request = PrivateAiRequest(
        prompt: 'Responda apenas com: OK',

        provider: config.normalizedProvider,

        apiKey: apiKey,

        model: config.normalizedModel,

        baseUrl: config.normalizedBaseUrl,
      );

      final response = await _privateAiClient.generate(
        request,
      );

      if (!mounted) {
        return;
      }

      final normalizedResponse = response.trim();

      _showMessage(
        normalizedResponse.isEmpty
            ? 'Conexão realizada.'
            : 'Conexão com ${config.providerLabel} funcionando.',
      );
    } on PrivateAiException catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      String message = error.message;

      if (error.isUnauthorized) {
        message = 'Credencial recusada pelo provider.';
      } else if (error.isRateLimited) {
        message = 'O provider informou limite de requisições.';
      } else if (error.isServerError) {
        message = 'O provider está indisponível no momento.';
      }

      _showMessage(
        message,
        error: true,
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.toString().replaceFirst(
          'Bad state: ',
          '',
        ),

        error: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isTesting = false;
          },
        );
      }
    }
  }

  // ============================================================
  // ATIVAR / DESATIVAR
  // ============================================================

  Future<
    void
  >
  _togglePrivateApi(
    bool value,
  ) async {
    if (_isToggling) {
      return;
    }

    if (value &&
        !_hasStoredApiKey) {
      _showMessage(
        'Salve uma API Key antes de ativar.',
        error: true,
      );

      return;
    }

    setState(
      () {
        _isToggling = true;
      },
    );

    try {
      if (value) {
        // ======================================================
        // SALVAR METADADOS ANTES DE ATIVAR
        // ======================================================

        final config = _buildConfig(
          enabled: false,

          hasApiKey: _hasStoredApiKey,
        );

        await _privateApiService.saveMetadata(
          config,
        );

        await _aiProviderService.enablePrivateApi();
      } else {
        await _aiProviderService.disablePrivateApi();
      }

      final refreshed = await _privateApiService.loadConfig();

      if (!mounted) {
        return;
      }

      setState(
        () {
          _privateApiEnabled = refreshed.canUsePrivateApi;

          _hasStoredApiKey = refreshed.hasApiKey;
        },
      );

      _showMessage(
        refreshed.canUsePrivateApi
            ? 'API privada ativada.'
            : 'IA Versin ativada.',
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível alterar a fonte da IA: $error',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isToggling = false;
          },
        );
      }
    }
  }

  // ============================================================
  // REMOVER API KEY
  // ============================================================

  Future<
    void
  >
  _removeApiKey() async {
    if (!_hasStoredApiKey ||
        _isRemoving) {
      return;
    }

    final confirmed =
        await showDialog<
          bool
        >(
          context: context,

          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  backgroundColor: _cardColor,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      18,
                    ),
                  ),

                  icon: const Icon(
                    Icons.delete_outline_rounded,

                    color: _red,

                    size: 30,
                  ),

                  title: const Text(
                    'Remover API Key?',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Colors.white,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  content: const Text(
                    'A credencial será removida deste dispositivo e a IA Versin voltará a ser utilizada.',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Colors.white54,

                      fontSize: 12,

                      height: 1.4,
                    ),
                  ),

                  actionsAlignment: MainAxisAlignment.center,

                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          false,
                        );
                      },

                      child: const Text(
                        'CANCELAR',

                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    ),

                    FilledButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },

                      style: FilledButton.styleFrom(
                        backgroundColor: _red,

                        foregroundColor: Colors.white,
                      ),

                      child: const Text(
                        'REMOVER',
                      ),
                    ),
                  ],
                );
              },
        );

    if (confirmed !=
            true ||
        !mounted) {
      return;
    }

    setState(
      () {
        _isRemoving = true;
      },
    );

    try {
      await _privateApiService.removeApiKey();

      _apiKeyController.clear();

      if (!mounted) {
        return;
      }

      setState(
        () {
          _hasStoredApiKey = false;

          _privateApiEnabled = false;
        },
      );

      _showMessage(
        'API Key removida deste dispositivo.',
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível remover a credencial.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isRemoving = false;
          },
        );
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              context,
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _accent,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),

                      padding: const EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        32,
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          _buildInformationCard(),

                          const SizedBox(
                            height: 22,
                          ),

                          _buildStatusCard(),

                          const SizedBox(
                            height: 22,
                          ),

                          _buildSectionTitle(
                            'PROVEDOR',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _buildProviderSelector(),

                          const SizedBox(
                            height: 22,
                          ),

                          _buildSectionTitle(
                            'CREDENCIAIS',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _buildCredentialsCard(),

                          const SizedBox(
                            height: 22,
                          ),

                          _buildSectionTitle(
                            'CONFIGURAÇÃO OPCIONAL',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _buildAdvancedCard(),

                          const SizedBox(
                            height: 22,
                          ),

                          _buildSecurityCard(),

                          const SizedBox(
                            height: 22,
                          ),

                          if (_hasStoredApiKey) _buildRemoveCredentialCard(),

                          if (_hasStoredApiKey)
                            const SizedBox(
                              height: 22,
                            ),

                          _buildActions(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        8,
      ),

      child: Row(
        children: [
          Material(
            color: Colors.transparent,

            child: InkWell(
              onTap: () {
                Navigator.of(
                  context,
                ).maybePop();
              },

              borderRadius: BorderRadius.circular(
                12,
              ),

              child: Container(
                width: 42,

                height: 42,

                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.05,
                  ),

                  borderRadius: BorderRadius.circular(
                    12,
                  ),

                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),

                child: const Icon(
                  Icons.arrow_back_rounded,

                  color: Colors.white,

                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'API PRIVADA',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 18,

                    fontWeight: FontWeight.w800,

                    letterSpacing: 1,
                  ),
                ),

                SizedBox(
                  height: 2,
                ),

                Text(
                  'Credenciais e serviços externos',

                  style: TextStyle(
                    color: Colors.white38,

                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 38,

            height: 38,

            decoration: BoxDecoration(
              color: _accent.withValues(
                alpha: 0.08,
              ),

              borderRadius: BorderRadius.circular(
                11,
              ),
            ),

            child: const Icon(
              Icons.vpn_key_outlined,

              color: _accent,

              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMAÇÃO
  // ============================================================

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        18,
      ),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [
            _purple.withValues(
              alpha: 0.18,
            ),

            _cardColor,

            _accent.withValues(
              alpha: 0.04,
            ),
          ],
        ),

        borderRadius: BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color: _accent.withValues(
            alpha: 0.12,
          ),
        ),
      ),

      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.auto_awesome_rounded,

            color: _accent,

            size: 22,
          ),

          SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Use sua própria infraestrutura',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 14,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(
                  height: 6,
                ),

                Text(
                  'A credencial privada fica protegida no armazenamento seguro deste dispositivo. Ela não é enviada ao banco do Versin.',

                  style: TextStyle(
                    color: Colors.white54,

                    fontSize: 11,

                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusCard() {
    final active =
        _privateApiEnabled &&
        _hasStoredApiKey;

    final color = active
        ? _green
        : _accent;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        16,
      ),

      decoration: _cardDecoration(),

      child: Row(
        children: [
          Container(
            width: 40,

            height: 40,

            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),

              borderRadius: BorderRadius.circular(
                12,
              ),
            ),

            child: Icon(
              active
                  ? Icons.check_circle_outline_rounded
                  : Icons.auto_awesome_outlined,

              color: color,

              size: 20,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  active
                      ? 'API privada ativa'
                      : 'IA Versin ativa',

                  style: TextStyle(
                    color: color,

                    fontWeight: FontWeight.w700,

                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  active
                      ? '$_selectedProvider • cota Versin não consumida'
                      : _hasStoredApiKey
                      ? 'Credencial salva, mas API privada desativada'
                      : 'Nenhuma credencial privada configurada',

                  style: const TextStyle(
                    color: Colors.white38,

                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          if (_hasStoredApiKey)
            Switch(
              value: active,

              activeThumbColor: _green,

              activeTrackColor: _green.withValues(
                alpha: 0.28,
              ),

              onChanged: _isToggling
                  ? null
                  : _togglePrivateApi,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PROVIDER
  // ============================================================

  Widget _buildProviderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),

      decoration: _cardDecoration(),

      child: DropdownButtonHideUnderline(
        child:
            DropdownButton<
              String
            >(
              value: _selectedProvider,

              isExpanded: true,

              dropdownColor: _cardColor,

              iconEnabledColor: _accent,

              style: const TextStyle(
                color: Colors.white,

                fontSize: 13,
              ),

              items: _providers.map(
                (
                  provider,
                ) {
                  return DropdownMenuItem<
                    String
                  >(
                    value: provider,

                    child: Row(
                      children: [
                        const Icon(
                          Icons.hub_outlined,

                          color: _accent,

                          size: 17,
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Text(
                          provider,
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),

              onChanged:
                  (
                    value,
                  ) {
                    if (value ==
                        null) {
                      return;
                    }

                    setState(
                      () {
                        _selectedProvider = value;
                      },
                    );
                  },
            ),
      ),
    );
  }

  // ============================================================
  // CREDENCIAIS
  // ============================================================

  Widget _buildCredentialsCard() {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),

      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'API Key',

                  style: TextStyle(
                    color: Colors.white70,

                    fontSize: 11,

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (_hasStoredApiKey)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,

                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color: _green.withValues(
                      alpha: 0.08,
                    ),

                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: const Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      Icon(
                        Icons.lock_outline_rounded,

                        color: _green,

                        size: 12,
                      ),

                      SizedBox(
                        width: 4,
                      ),

                      Text(
                        'SALVA',

                        style: TextStyle(
                          color: _green,

                          fontSize: 8,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          TextField(
            controller: _apiKeyController,

            obscureText: _obscureApiKey,

            enableSuggestions: false,

            autocorrect: false,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 13,

              fontFamily: 'monospace',
            ),

            cursorColor: _accent,

            decoration: _inputDecoration(
              hint: _hasStoredApiKey
                  ? 'Digite somente para substituir a chave salva'
                  : 'Insira sua API Key privada',

              icon: Icons.key_rounded,

              suffix: IconButton(
                tooltip: _obscureApiKey
                    ? 'Mostrar chave digitada'
                    : 'Ocultar chave digitada',

                onPressed: () {
                  setState(
                    () {
                      _obscureApiKey = !_obscureApiKey;
                    },
                  );
                },

                icon: Icon(
                  _obscureApiKey
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,

                  color: Colors.white30,

                  size: 18,
                ),
              ),
            ),
          ),

          if (_hasStoredApiKey) ...[
            const SizedBox(
              height: 9,
            ),

            const Text(
              'A chave salva não é recarregada nem exibida. Deixe o campo vazio para mantê-la.',

              style: TextStyle(
                color: Colors.white30,

                fontSize: 9,

                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // AVANÇADO
  // ============================================================

  Widget _buildAdvancedCard() {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),

      decoration: _cardDecoration(),

      child: Column(
        children: [
          TextField(
            controller: _modelController,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 13,
            ),

            cursorColor: _accent,

            decoration: _inputDecoration(
              hint: 'Modelo (opcional)',

              icon: Icons.memory_rounded,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller: _baseUrlController,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 13,
            ),

            cursorColor: _accent,

            decoration: _inputDecoration(
              hint:
                  _selectedProvider ==
                      'Custom'
                  ? 'Base URL obrigatória'
                  : 'Base URL personalizada (opcional)',

              icon: Icons.link_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEGURANÇA
  // ============================================================

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        14,
      ),

      decoration: BoxDecoration(
        color: _green.withValues(
          alpha: 0.035,
        ),

        borderRadius: BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color: _green.withValues(
            alpha: 0.10,
          ),
        ),
      ),

      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.shield_outlined,

            color: _green,

            size: 18,
          ),

          SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              'A chave de API fica no armazenamento seguro do sistema. O Versin não salva essa credencial e não a inclui em logs.',

              style: TextStyle(
                color: Colors.white54,

                fontSize: 10,

                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REMOVER CREDENCIAL
  // ============================================================

  Widget _buildRemoveCredentialCard() {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: _isRemoving
            ? null
            : _removeApiKey,

        borderRadius: BorderRadius.circular(
          14,
        ),

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.all(
            14,
          ),

          decoration: BoxDecoration(
            color: _red.withValues(
              alpha: 0.035,
            ),

            borderRadius: BorderRadius.circular(
              14,
            ),

            border: Border.all(
              color: _red.withValues(
                alpha: 0.12,
              ),
            ),
          ),

          child: Row(
            children: [
              _isRemoving
                  ? const SizedBox(
                      width: 18,

                      height: 18,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,

                        color: _red,
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline_rounded,

                      color: _red,

                      size: 18,
                    ),

              const SizedBox(
                width: 10,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Remover chave deste dispositivo',

                      style: TextStyle(
                        color: _red,

                        fontSize: 11,

                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(
                      height: 2,
                    ),

                    Text(
                      'A API privada será desativada automaticamente.',

                      style: TextStyle(
                        color: Colors.white30,

                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,

                color: Colors.white24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AÇÕES
  // ============================================================

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isTesting
                ? null
                : _testConnection,

            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,

              side: BorderSide(
                color: _accent.withValues(
                  alpha: 0.30,
                ),
              ),

              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
            ),

            icon: _isTesting
                ? const SizedBox(
                    width: 16,

                    height: 16,

                    child: CircularProgressIndicator(
                      color: _accent,

                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.network_check_rounded,

                    size: 17,
                  ),

            label: const Text(
              'TESTAR',
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: FilledButton.icon(
            onPressed: _isSaving
                ? null
                : _save,

            style: FilledButton.styleFrom(
              backgroundColor: _accent,

              foregroundColor: Colors.black,

              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
            ),

            icon: _isSaving
                ? const SizedBox(
                    width: 16,

                    height: 16,

                    child: CircularProgressIndicator(
                      color: Colors.black,

                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.save_outlined,

                    size: 17,
                  ),

            label: const Text(
              'SALVAR',

              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,

      style: const TextStyle(
        color: Colors.white38,

        fontSize: 9,

        fontWeight: FontWeight.w700,

        letterSpacing: 1,
      ),
    );
  }

  // ============================================================
  // DECORAÇÃO CARD
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(
        alpha: 0.035,
      ),

      borderRadius: BorderRadius.circular(
        16,
      ),

      border: Border.all(
        color: Colors.white.withValues(
          alpha: 0.07,
        ),
      ),
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(
        color: Colors.white24,

        fontSize: 12,
      ),

      prefixIcon: Icon(
        icon,

        color: _accent.withValues(
          alpha: 0.65,
        ),

        size: 18,
      ),

      suffixIcon: suffix,

      filled: true,

      fillColor: Colors.black.withValues(
        alpha: 0.15,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          12,
        ),

        borderSide: BorderSide(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          12,
        ),

        borderSide: BorderSide(
          color: _accent.withValues(
            alpha: 0.40,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STRING OPCIONAL
  // ============================================================

  String? _normalizeNullable(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,

          backgroundColor: error
              ? const Color(
                  0xFF33151C,
                )
              : const Color(
                  0xFF18152D,
                ),

          content: Text(
            message,
          ),
        ),
      );
  }
}
