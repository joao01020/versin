import 'package:flutter/material.dart';

// ============================================================
// PRIVATE API SETTINGS PAGE
// ============================================================
//
// Página responsável pela configuração de APIs privadas.
//
// Futuramente pode ser conectada a:
//
// - armazenamento seguro;
// - Supabase;
// - flutter_secure_storage;
// - provedores diferentes;
// - teste real de conexão.
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

  bool _isSaving = false;

  bool _isTesting = false;

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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _apiKeyController.dispose();

    _baseUrlController.dispose();

    _modelController.dispose();

    super.dispose();
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

    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      _showMessage(
        'Informe sua API Key.',
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
      // TODO
      // ========================================================
      //
      // Aqui entra futuramente:
      //
      // PrivateApiService.save(...)
      //
      // ou flutter_secure_storage.
      //
      // ========================================================

      await Future<
        void
      >.delayed(
        const Duration(
          milliseconds: 400,
        ),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Configuração preparada para ser salva.',
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

  Future<
    void
  >
  _testConnection() async {
    if (_isTesting) {
      return;
    }

    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      _showMessage(
        'Informe sua API Key antes de testar.',
        error: true,
      );

      return;
    }

    setState(
      () {
        _isTesting = true;
      },
    );

    try {
      // ========================================================
      // TODO
      // ========================================================
      //
      // Posteriormente fazemos o teste real através de um
      // PrivateApiService.
      //
      // ========================================================

      await Future<
        void
      >.delayed(
        const Duration(
          milliseconds: 700,
        ),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Teste de conexão ainda será conectado ao serviço.',
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
            // ==================================================
            // HEADER
            // ==================================================
            _buildHeader(
              context,
            ),

            // ==================================================
            // CONTEÚDO
            // ==================================================
            Expanded(
              child: SingleChildScrollView(
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
                    // ==========================================
                    // INTRODUÇÃO
                    // ==========================================
                    _buildInformationCard(),

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
                      height: 28,
                    ),

                    // ==========================================
                    // AÇÕES
                    // ==========================================
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
                  'Vincule uma chave de API privada ao Versin para utilizar sua própria conta, modelos e limites de requisição.',

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
          const Text(
            'API Key',

            style: TextStyle(
              color: Colors.white70,

              fontSize: 11,

              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          TextField(
            controller: _apiKeyController,

            obscureText: _obscureApiKey,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 13,

              fontFamily: 'monospace',
            ),

            cursorColor: _accent,

            decoration: _inputDecoration(
              hint: 'Insira sua API Key privada',

              icon: Icons.key_rounded,

              suffix: IconButton(
                tooltip: _obscureApiKey
                    ? 'Mostrar chave'
                    : 'Ocultar chave',

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
              hint: 'Modelo, ex: gpt-5',

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
              hint: 'Base URL personalizada (opcional)',

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
              'Chaves privadas não devem ser expostas em logs, código-fonte ou repositórios Git. O armazenamento seguro será responsável por proteger a credencial.',

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
