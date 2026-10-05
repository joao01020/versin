import 'package:flutter/material.dart';

import 'package:versin/modules/settings/views/private_api_settings_page.dart';

import 'widgets/private_api_mission_step.dart';

// ============================================================
// PRIVATE API ONBOARDING MODE
// ============================================================

enum PrivateApiOnboardingMode { free, premium, existing }

// ============================================================
// PRIVATE API ONBOARDING PAGE
// ============================================================
//
// Missão guiada para ajudar o usuário a continuar usando IA com
// uma API própria.
//
// Objetivos:
//
// - não assustar;
// - não obrigar pagamento;
// - explicar que podem existir opções gratuitas;
// - oferecer caminho premium;
// - ensinar mesmo quem nunca usou API;
// - terminar na tela real de configuração.
//
// ============================================================

class PrivateApiOnboardingPage extends StatefulWidget {
  const PrivateApiOnboardingPage({super.key});

  @override
  State<PrivateApiOnboardingPage> createState() {
    return _PrivateApiOnboardingPageState();
  }
}

// ============================================================
// STATE
// ============================================================

class _PrivateApiOnboardingPageState extends State<PrivateApiOnboardingPage> {
  // ============================================================
  // TOTAL DE ETAPAS
  // ============================================================

  static const int _totalSteps = 6;

  // ============================================================
  // ETAPA ATUAL
  // ============================================================

  int _currentStep = 1;

  // ============================================================
  // MODO
  // ============================================================

  PrivateApiOnboardingMode? _selectedMode;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Continuar com sua própria IA')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                // ==================================================
                // INTRODUÇÃO
                // ==================================================
                Text(
                  'Você tem outras formas de continuar',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Você pode conectar uma API própria ao Versin. '
                  'Alguns provedores podem oferecer cotas gratuitas '
                  'ou acesso sem custo, enquanto outros possuem '
                  'opções premium com mais capacidade.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'A disponibilidade de planos gratuitos '
                          'depende de cada provedor e pode mudar. '
                          'Você sempre poderá escolher qual opção '
                          'faz sentido para você.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // PROGRESSO
                // ==================================================
                _buildProgressHeader(context),

                const SizedBox(height: 18),

                // ==================================================
                // CONTEÚDO DA ETAPA
                // ==================================================
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentStep),
                    child: _buildCurrentStep(context),
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // NAVEGAÇÃO
                // ==================================================
                _buildNavigation(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROGRESSO
  // ============================================================

  Widget _buildProgressHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Missão de configuração',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            Text(
              '$_currentStep/$_totalSteps',
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: _currentStep / _totalSteps,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ETAPA ATUAL
  // ============================================================

  Widget _buildCurrentStep(BuildContext context) {
    switch (_currentStep) {
      case 1:
        return _buildStepChooseMode(context);

      case 2:
        return _buildStepChooseProvider(context);

      case 3:
        return _buildStepCreateAccount(context);

      case 4:
        return _buildStepFindApiKey(context);

      case 5:
        return _buildStepCreateKey(context);

      case 6:
      default:
        return _buildStepConnectToVersin(context);
    }
  }

  // ============================================================
  // ETAPA 1
  // ============================================================

  Widget _buildStepChooseMode(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrivateApiMissionStep(
          stepNumber: 1,
          totalSteps: _totalSteps,
          title: 'Escolha como quer continuar',
          description:
              'Você pode tentar uma opção sem custo, '
              'usar uma alternativa premium ou conectar '
              'uma API que já possui.',
          isActive: true,
          icon: Icons.route_rounded,
        ),

        const SizedBox(height: 18),

        Text(
          'Qual caminho faz mais sentido agora?',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 12),

        _buildModeOption(
          context: context,
          mode: PrivateApiOnboardingMode.free,
          icon: Icons.volunteer_activism_outlined,
          title: 'Quero tentar sem custo',
          description:
              'Vamos procurar uma opção que possa oferecer '
              'cota gratuita ou acesso sem custo.',
        ),

        const SizedBox(height: 10),

        _buildModeOption(
          context: context,
          mode: PrivateApiOnboardingMode.premium,
          icon: Icons.workspace_premium_outlined,
          title: 'Quero uma opção premium',
          description:
              'Ideal se você quer mais capacidade, '
              'estabilidade ou limites maiores.',
        ),

        const SizedBox(height: 10),

        _buildModeOption(
          context: context,
          mode: PrivateApiOnboardingMode.existing,
          icon: Icons.key_outlined,
          title: 'Já tenho uma API',
          description:
              'Se você já possui uma chave, pode pular '
              'direto para a configuração no Versin.',
        ),
      ],
    );
  }

  // ============================================================
  // OPÇÃO DE MODO
  // ============================================================

  Widget _buildModeOption({
    required BuildContext context,
    required PrivateApiOnboardingMode mode,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    final selected = _selectedMode == mode;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.26)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            if (selected)
              Icon(Icons.check_circle_rounded, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ETAPA 2
  // ============================================================

  Widget _buildStepChooseProvider(BuildContext context) {
    return _buildGenericStep(
      context: context,
      stepNumber: 2,
      icon: Icons.hub_outlined,
      title: 'Escolha um provedor',
      description: _selectedMode == PrivateApiOnboardingMode.premium
          ? 'Escolha o provedor de IA que deseja usar. '
                'Você pode comparar preço, limites e modelos.'
          : 'Escolha um provedor que ofereça uma opção '
                'compatível com o que você procura. Alguns '
                'podem disponibilizar cotas gratuitas.',
      children: [
        _buildTip(
          context,
          'Você não precisa escolher para sempre. '
          'Pode trocar de provedor depois.',
        ),
        _buildTip(
          context,
          'O Versin já possui suporte a diferentes '
          'provedores através da configuração de API privada.',
        ),
      ],
    );
  }

  // ============================================================
  // ETAPA 3
  // ============================================================

  Widget _buildStepCreateAccount(BuildContext context) {
    return _buildGenericStep(
      context: context,
      stepNumber: 3,
      icon: Icons.person_add_alt_1_outlined,
      title: 'Crie sua conta',
      description:
          'Abra o site do provedor escolhido e crie uma conta. '
          'Depois volte para o Versin para continuar.',
      children: [
        _buildTip(
          context,
          'Alguns provedores podem pedir confirmação '
          'de e-mail ou outras verificações.',
        ),
        _buildTip(
          context,
          'Se você já possui conta nesse provedor, '
          'pode seguir para a próxima etapa.',
        ),
      ],
    );
  }

  // ============================================================
  // ETAPA 4
  // ============================================================

  Widget _buildStepFindApiKey(BuildContext context) {
    return _buildGenericStep(
      context: context,
      stepNumber: 4,
      icon: Icons.search_rounded,
      title: 'Encontre a área de API Keys',
      description:
          'No painel do provedor, procure uma seção relacionada '
          'a chaves ou credenciais de API.',
      children: [
        _buildKeywordBox(context, [
          'API Keys',
          'Developers',
          'Credentials',
          'Keys',
        ]),
        _buildTip(
          context,
          'Os nomes variam entre provedores, '
          'mas normalmente ficam nas configurações '
          'da conta ou área de desenvolvedor.',
        ),
      ],
    );
  }

  // ============================================================
  // ETAPA 5
  // ============================================================

  Widget _buildStepCreateKey(BuildContext context) {
    return _buildGenericStep(
      context: context,
      stepNumber: 5,
      icon: Icons.key_rounded,
      title: 'Crie e copie sua chave',
      description:
          'Crie uma nova API Key e copie o valor exibido. '
          'Essa chave funciona como uma senha para acessar '
          'a sua conta de IA.',
      children: [
        _buildKeywordBox(context, [
          'Create API Key',
          'New Key',
          'Generate Key',
        ]),
        _buildSecurityNotice(context),
      ],
    );
  }

  // ============================================================
  // ETAPA 6
  // ============================================================

  Widget _buildStepConnectToVersin(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrivateApiMissionStep(
          stepNumber: 6,
          totalSteps: _totalSteps,
          title: 'Conecte ao Versin',
          description:
              'Agora basta escolher o provedor, colar sua chave '
              'e testar a conexão.',
          isActive: true,
          icon: Icons.link_rounded,
        ),

        const SizedBox(height: 18),

        Text(
          'Pronto para conectar',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'A próxima tela é a configuração real da API privada '
          'do Versin. Sua chave será cadastrada por lá.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),

        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _openPrivateApiSettings,
            icon: const Icon(Icons.key_rounded),
            label: const Text('Abrir configuração da API'),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GENERIC STEP
  // ============================================================

  Widget _buildGenericStep({
    required BuildContext context,
    required int stepNumber,
    required IconData icon,
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrivateApiMissionStep(
          stepNumber: stepNumber,
          totalSteps: _totalSteps,
          title: title,
          description: description,
          isActive: true,
          icon: icon,
        ),

        if (children.isNotEmpty) ...[const SizedBox(height: 18), ...children],
      ],
    );
  }

  // ============================================================
  // TIP
  // ============================================================

  Widget _buildTip(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KEYWORD BOX
  // ============================================================

  Widget _buildKeywordBox(BuildContext context, List<String> values) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: values.map((value) => Chip(label: Text(value))).toList(),
      ),
    );
  }

  // ============================================================
  // SEGURANÇA
  // ============================================================

  Widget _buildSecurityNotice(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 19,
            color: colorScheme.primary,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              'Não compartilhe sua API Key com outras pessoas '
              'e evite colá-la em chats, mensagens ou locais públicos.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  Widget _buildNavigation(BuildContext context) {
    final canContinue = _canContinueCurrentStep();

    return Row(
      children: [
        if (_currentStep > 1)
          Expanded(
            child: OutlinedButton(
              onPressed: _goBack,
              child: const Text('Voltar'),
            ),
          ),

        if (_currentStep > 1) const SizedBox(width: 10),

        if (_currentStep < _totalSteps)
          Expanded(
            child: FilledButton(
              onPressed: canContinue ? _goNext : null,
              child: const Text('Continuar'),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // PODE CONTINUAR?
  // ============================================================

  bool _canContinueCurrentStep() {
    if (_currentStep == 1) {
      return _selectedMode != null;
    }

    return true;
  }

  // ============================================================
  // PRÓXIMA
  // ============================================================

  void _goNext() {
    if (!_canContinueCurrentStep()) {
      return;
    }

    // ==========================================================
    // JÁ POSSUI API
    // ==========================================================

    if (_currentStep == 1 &&
        _selectedMode == PrivateApiOnboardingMode.existing) {
      setState(() {
        _currentStep = _totalSteps;
      });

      return;
    }

    if (_currentStep >= _totalSteps) {
      return;
    }

    setState(() {
      _currentStep++;
    });
  }

  // ============================================================
  // VOLTAR
  // ============================================================

  void _goBack() {
    if (_currentStep <= 1) {
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  // ============================================================
  // ABRIR CONFIGURAÇÃO
  // ============================================================

  void _openPrivateApiSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return const PrivateApiSettingsPage();
        },
      ),
    );
  }
}
