import 'package:flutter/material.dart';
import 'package:versin/app/routes/app_routes.dart';
import 'package:versin/app/locator.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/login/data/repositories/auth_repository_impl.dart';
import 'package:versin/modules/login/domain/repositories/auth_repository.dart';
import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:versin/modules/profile/views/account_information_page.dart';
import 'package:versin/modules/profile/views/professional_profile_settings_page.dart';
import 'package:versin/modules/settings/widgets/settings_tile.dart';

class SettingsPage
    extends
        StatefulWidget {
  static const String routeName = AppRoutes.settings;

  const SettingsPage({
    super.key,
  });

  @override
  State<
    SettingsPage
  >
  createState() => _SettingsPageState();
}

class _SettingsPageState
    extends
        State<
          SettingsPage
        > {
  final RhymesController _rhymesController =
      sl<
        RhymesController
      >();
  final AuthRepository _authRepository = AuthRepositoryImpl();

  final DashboardController _dashboardController =
      sl<
        DashboardController
      >();

  bool _isLoggingOut = false;

  final Color primaryPurple = const Color(
    0xFF6A1B9A,
  );
  final Color accentNeon = const Color(
    0xFFE040FB,
  );
  final Color deepBg = const Color(
    0xFF0D0B1F,
  );

  bool _syncCloud = true;
  bool _autoSave = true;

  bool _isApiExpanded = false;
  bool _obscureApiKey = true;
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0D0B1F,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),

            _buildSectionTitle(
              "Perfil do Produtor",
            ),
            _buildSettingsContainer(
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: "Informações da Conta",
                    subtitle: "Editar e-mail, nome artístico e avatar",
                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(
                        MaterialPageRoute(
                          builder:
                              (
                                _,
                              ) => const AccountInformationPage(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  SettingsTile(
                    icon: Icons.groups_2_outlined,
                    title: "Configurações do Conectar",
                    subtitle: "Definir funções, habilidades e preferências profissionais",
                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(
                        MaterialPageRoute(
                          builder:
                              (
                                _,
                              ) => const ProfessionalProfileSettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            _buildSectionTitle(
              "IA mensal",
            ),

            AnimatedBuilder(
              animation: _rhymesController,
              builder:
                  (
                    context,
                    _,
                  ) {
                    return _buildAiQuotaCard();
                  },
            ),

            const SizedBox(
              height: 24,
            ),

            _buildSectionTitle(
              "Preferências do Sistema",
            ),
            _buildSettingsContainer(
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: "Sincronização",
                    subtitle: "Manter banco de dados local e nuvem em tempo real",
                    value: _syncCloud,
                    onChanged:
                        (
                          val,
                        ) => setState(
                          () => _syncCloud = val,
                        ),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    title: "Auto-Salvar Rascunhos",
                    subtitle: "Salvar rimas e composições automaticamente ao digitar",
                    value: _autoSave,
                    onChanged:
                        (
                          val,
                        ) => setState(
                          () => _autoSave = val,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            _buildSectionTitle(
              "Integrações & Hardware",
            ),
            _buildSettingsContainer(
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.settings_input_component,
                    title: "Versin Hub Config",
                    subtitle: "Gerenciar conexões de hardware externo",
                    onTap: () {},
                  ),
                  _buildDivider(),

                  Theme(
                    data:
                        Theme.of(
                          context,
                        ).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                    child: ExpansionTile(
                      onExpansionChanged:
                          (
                            expanded,
                          ) {
                            setState(
                              () => _isApiExpanded = expanded,
                            );
                          },
                      leading: Icon(
                        Icons.vpn_key_outlined,
                        color: accentNeon,
                        size: 22,
                      ),
                      title: const Text(
                        "Configurar API Privada",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      subtitle: const Text(
                        "Gerenciar credenciais e chaves externas de IA/Serviços",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        _isApiExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white24,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 20,
                            top: 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(
                                    alpha: 0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: 0.02,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "Esta opção opcional concede autonomia para vincular sua própria chave de API ao ecossistema Versin. "
                                  "Recomendado para contornar limitações padrão de cota de requisições ou para aplicar modelos neurais customizados dedicados.",
                                  style: TextStyle(
                                    color: Colors.white.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 14,
                              ),
                              TextField(
                                controller: _apiKeyController,
                                obscureText: _obscureApiKey,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Insira sua API Key privada",
                                  hintStyle: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.02,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
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
                                      color: accentNeon.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureApiKey
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white30,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _obscureApiKey = !_obscureApiKey,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            _buildSectionTitle(
              "Segurança & Criptografia",
            ),
            _buildSettingsContainer(
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.vpn_key_outlined,
                    title: "Gerenciar Par de Chaves",
                    subtitle: "Backup e rotação das chaves públicas e privadas da rede",
                    iconColor: Colors.white60,
                    iconBackgroundColor: Colors.white10,
                    onTap: () {},
                  ),
                  _buildDivider(),
                  ListTile(
                    enabled: !_isLoggingOut,
                    leading: _isLoggingOut
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.redAccent,
                            ),
                          )
                        : const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                    title: Text(
                      _isLoggingOut
                          ? "Saindo..."
                          : "Sair da Conta",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      "Encerrar esta sessão do Versin",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    onTap: _isLoggingOut
                        ? null
                        : _confirmLogout,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            Center(
              child: Text(
                "Versin Genesis v0.0.1",
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.2,
                  ),
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<
    void
  >
  _confirmLogout() async {
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
                  backgroundColor: const Color(
                    0xFF17132D,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 32,
                  ),
                  title: const Text(
                    'Sair da conta?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    'Sua sessão será encerrada neste dispositivo.',
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
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 17,
                      ),
                      label: const Text(
                        'SAIR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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

    await _logout();
  }

  Future<
    void
  >
  _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(
      () {
        _isLoggingOut = true;
      },
    );

    try {
      await _authRepository.signOut();

      _dashboardController.resetNavigation();

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (
          route,
        ) => false,
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _isLoggingOut = false;
        },
      );

      ScaffoldMessenger.of(
          context,
        )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(
              0xFF211216,
            ),
            content: Text(
              'Não foi possível sair da conta: $error',
            ),
          ),
        );
    }
  }

  // ============================================================
  // IA MENSAL
  // ============================================================

  Widget _buildAiQuotaCard() {
    final percentage = _rhymesController.aiUsagePercentage.clamp(
      0.0,
      100.0,
    );

    final progress = _rhymesController.aiUsageProgress.clamp(
      0.0,
      1.0,
    );

    final level = _rhymesController.aiUsageLevel;

    final message = _rhymesController.aiUsageMessage;

    final usedTokens = _rhymesController.aiUsedTokens;

    final remainingTokens = _rhymesController.aiRemainingTokens;

    final limitTokens = _rhymesController.aiLimitTokens;

    final accent = _aiQuotaColor(
      level,
      percentage,
    );

    final statusText = _aiQuotaStatusText(
      level,
      percentage,
    );

    return _buildSettingsContainer(
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // HEADER
            // ====================================================
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                    border: Border.all(
                      color: accent.withValues(
                        alpha: 0.22,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IA mensal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(
                        height: 2,
                      ),

                      Text(
                        'Uso da sua cota mensal de inteligência artificial',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                    border: Border.all(
                      color: accent.withValues(
                        alpha: 0.22,
                      ),
                    ),
                  ),
                  child: Text(
                    '${_formatPercentage(percentage)}%',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            // ====================================================
            // STATUS
            // ====================================================
            Row(
              children: [
                Icon(
                  _aiQuotaIcon(
                    level,
                    percentage,
                  ),
                  color: accent,
                  size: 15,
                ),

                const SizedBox(
                  width: 7,
                ),

                Text(
                  statusText,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 9,
            ),

            // ====================================================
            // BARRA
            // ====================================================
            ClipRRect(
              borderRadius: BorderRadius.circular(
                20,
              ),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white.withValues(
                  alpha: 0.07,
                ),
                valueColor:
                    AlwaysStoppedAnimation<
                      Color
                    >(
                      accent,
                    ),
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            // ====================================================
            // MARCADORES
            // ====================================================
            const Row(
              children: [
                Text(
                  '0%',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 9,
                  ),
                ),

                Spacer(),

                Text(
                  '70%',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 9,
                  ),
                ),

                SizedBox(
                  width: 24,
                ),

                Text(
                  '90%',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 9,
                  ),
                ),

                SizedBox(
                  width: 18,
                ),

                Text(
                  '100%',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 9,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            // ====================================================
            // MENSAGEM
            // ====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(
                  alpha: 0.06,
                ),
                borderRadius: BorderRadius.circular(
                  10,
                ),
                border: Border.all(
                  color: accent.withValues(
                    alpha: 0.12,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: accent.withValues(
                      alpha: 0.90,
                    ),
                    size: 15,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      _normalizeAiMessage(
                        message,
                        percentage,
                      ),
                      style: TextStyle(
                        color: accent.withValues(
                          alpha: 0.92,
                        ),
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // ====================================================
            // TOKENS
            // ====================================================
            Row(
              children: [
                Expanded(
                  child: _buildAiQuotaMetric(
                    label: 'USADOS',
                    value: _formatTokens(
                      usedTokens,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: _buildAiQuotaMetric(
                    label: 'RESTANTES',
                    value: _formatTokens(
                      remainingTokens,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: _buildAiQuotaMetric(
                    label: 'LIMITE',
                    value: _formatTokens(
                      limitTokens,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MÉTRICA DA QUOTA
  // ============================================================

  Widget _buildAiQuotaMetric({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.18,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.04,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.7,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COR DA QUOTA
  // ============================================================

  Color _aiQuotaColor(
    String level,
    double percentage,
  ) {
    final normalizedLevel = level.toLowerCase();

    if (percentage >=
            100 ||
        normalizedLevel ==
            'blocked') {
      return Colors.redAccent;
    }

    if (percentage >=
            90 ||
        normalizedLevel ==
            'critical') {
      return Colors.orangeAccent;
    }

    if (percentage >=
            70 ||
        normalizedLevel ==
            'warning') {
      return Colors.amberAccent;
    }

    return accentNeon;
  }

  // ============================================================
  // ÍCONE DA QUOTA
  // ============================================================

  IconData _aiQuotaIcon(
    String level,
    double percentage,
  ) {
    final normalizedLevel = level.toLowerCase();

    if (percentage >=
            100 ||
        normalizedLevel ==
            'blocked') {
      return Icons.block_rounded;
    }

    if (percentage >=
            90 ||
        normalizedLevel ==
            'critical') {
      return Icons.warning_amber_rounded;
    }

    if (percentage >=
            70 ||
        normalizedLevel ==
            'warning') {
      return Icons.info_outline_rounded;
    }

    return Icons.check_circle_outline_rounded;
  }

  // ============================================================
  // STATUS DA QUOTA
  // ============================================================

  String _aiQuotaStatusText(
    String level,
    double percentage,
  ) {
    final normalizedLevel = level.toLowerCase();

    if (percentage >=
            100 ||
        normalizedLevel ==
            'blocked') {
      return 'Limite atingido';
    }

    if (percentage >=
            90 ||
        normalizedLevel ==
            'critical') {
      return 'Limite próximo';
    }

    if (percentage >=
            70 ||
        normalizedLevel ==
            'warning') {
      return 'Uso elevado';
    }

    return 'Uso normal';
  }

  // ============================================================
  // MENSAGEM DA QUOTA
  // ============================================================

  String _normalizeAiMessage(
    String message,
    double percentage,
  ) {
    final normalized = message.trim();

    if (percentage >=
        100) {
      return 'Limite mensal de IA atingido.';
    }

    if (percentage >=
        90) {
      return 'Seu limite mensal está próximo.';
    }

    if (percentage >=
        70) {
      return 'Você já utilizou boa parte da sua IA este mês.';
    }

    if (normalized.isNotEmpty) {
      return normalized;
    }

    return 'Uso normal da IA.';
  }

  // ============================================================
  // FORMATAR PERCENTUAL
  // ============================================================

  String _formatPercentage(
    double percentage,
  ) {
    if (percentage ==
        percentage.roundToDouble()) {
      return percentage.toInt().toString();
    }

    return percentage.toStringAsFixed(
      1,
    );
  }

  // ============================================================
  // FORMATAR TOKENS
  // ============================================================

  String _formatTokens(
    int value,
  ) {
    if (value >=
        1000000) {
      final millions =
          value /
          1000000;

      if (millions ==
          millions.roundToDouble()) {
        return '${millions.toInt()}M';
      }

      return '${millions.toStringAsFixed(1)}M';
    }

    if (value >=
        1000) {
      final thousands =
          value /
          1000;

      if (thousands ==
          thousands.roundToDouble()) {
        return '${thousands.toInt()}k';
      }

      return '${thousands.toStringAsFixed(1)}k';
    }

    return value.toString();
  }

  Widget _buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: accentNeon.withValues(
            alpha: 0.8,
          ),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.04,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<
      bool
    >
    onChanged,
  }) {
    return SwitchListTile(
      activeColor: accentNeon,
      activeTrackColor: primaryPurple.withValues(
        alpha: 0.4,
      ),
      inactiveThumbColor: Colors.white54,
      inactiveTrackColor: Colors.white12,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(
        alpha: 0.05,
      ),
      indent: 16,
      endIndent: 16,
    );
  }
}
