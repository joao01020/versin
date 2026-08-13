import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';
import 'package:versin/modules/match/data/repositories/match_repository.dart';
import 'package:versin/modules/match/widgets/discovery_card_widget.dart';
import 'package:versin/modules/match/widgets/profile_tile_widget.dart';

import 'package:versin/modules/networking/views/networking_session_view.dart';

import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';
import 'package:versin/modules/profile/views/professional_profile_settings_page.dart';

// ============================================================
// MATCH PAGE
// ============================================================
//
// Fluxo:
//
// MatchPage
//    ↓
// ProfessionalProfileController
//    ↓
// carrega:
//
// - roles
// - primaryRole
// - lookingForRoles
//
//    ↓
//
// MatchController
//
//    ↓
//
// MatchRepository
//
//    ↓
//
// busca candidatos cujas roles combinam com:
//
// lookingForRoles
//
// ============================================================

class MatchPage
    extends
        StatefulWidget {
  static const String routeName = '/match';

  const MatchPage({
    super.key,
  });

  @override
  State<
    MatchPage
  >
  createState() => _MatchPageState();
}

// ============================================================
// STATE
// ============================================================

class _MatchPageState
    extends
        State<
          MatchPage
        > {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final MatchController _matchController;

  late final ProfessionalProfileController _professionalProfileController;

  // ============================================================
  // REPOSITORY
  // ============================================================

  late final MatchRepository _matchRepository;

  // ============================================================
  // STREAM
  // ============================================================

  StreamSubscription<
    String
  >?
  _matchSubscription;

  // ============================================================
  // ESTADO VISUAL
  // ============================================================

  bool _isConnectionProfileExpanded = true;

  bool _isInitializingMatch = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // DEPENDÊNCIAS
    // ==========================================================

    _matchController =
        sl<
          MatchController
        >();

    _professionalProfileController =
        sl<
          ProfessionalProfileController
        >();

    _matchRepository =
        sl<
          MatchRepository
        >();

    // ==========================================================
    // LISTENERS
    // ==========================================================

    _matchController.addListener(
      _onControllerUpdate,
    );

    _professionalProfileController.addListener(
      _onControllerUpdate,
    );

    // ==========================================================
    // STREAM DE MATCH MÚTUO
    // ==========================================================

    _matchSubscription = _matchController.matchEventStream.listen(
      (
        projectId,
      ) {
        debugPrint(
          '[MATCH PAGE] '
          'Match recebido. Projeto: $projectId',
        );

        if (!mounted) {
          return;
        }

        navigateToNetworkingSession(
          projectId,
        );
      },
      onError:
          (
            error,
          ) {
            debugPrint(
              '[MATCH PAGE] '
              'Erro no stream de match: $error',
            );
          },
    );

    // ==========================================================
    // INICIALIZAÇÃO ASSÍNCRONA
    // ==========================================================

    _initializeMatch();
  }

  // ============================================================
  // INICIALIZAR MATCH
  // ============================================================
  //
  // Ordem importante:
  //
  // 1. carregar perfil profissional;
  // 2. obter primaryRole;
  // 3. obter lookingForRoles;
  // 4. iniciar MatchController;
  // 5. iniciar MatchRepository.
  //
  // Dessa forma o repository nunca inicia antes de saber
  // quem o usuário procura.
  //
  // ============================================================

  Future<
    void
  >
  _initializeMatch() async {
    if (mounted) {
      setState(
        () {
          _isInitializingMatch = true;
        },
      );
    }

    try {
      // ========================================================
      // PERFIL PROFISSIONAL
      // ========================================================

      await _professionalProfileController.load();

      if (!mounted) {
        return;
      }

      // ========================================================
      // LOG
      // ========================================================

      debugPrint(
        '[MATCH PAGE] ========================================',
      );

      debugPrint(
        '[MATCH PAGE] Inicializando Match.',
      );

      debugPrint(
        '[MATCH PAGE] Função principal: '
        '${_professionalProfileController.primaryRole?.key ?? "não informado"}',
      );

      debugPrint(
        '[MATCH PAGE] Funções: '
        '${_professionalProfileController.selectedRoles.map((role) => role.key).toList()}',
      );

      debugPrint(
        '[MATCH PAGE] Procura: '
        '${_professionalProfileController.lookingForRoles.map((role) => role.key).toList()}',
      );

      // ========================================================
      // MATCH CONTROLLER
      // ========================================================

      await _matchController.initMatchSession();

      if (!mounted) {
        return;
      }

      // ========================================================
      // REPOSITORY
      // ========================================================

      _matchRepository.streamCrossRoleMatches(
        _matchController,
      );

      debugPrint(
        '[MATCH PAGE] Match inicializado.',
      );

      debugPrint(
        '[MATCH PAGE] ========================================',
      );
    } catch (
      error
    ) {
      debugPrint(
        '[MATCH PAGE] '
        'Erro ao inicializar Match: $error',
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isInitializingMatch = false;
          },
        );
      }
    }
  }

  // ============================================================
  // CONTROLLER UPDATE
  // ============================================================

  void _onControllerUpdate() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // NETWORKING SESSION
  // ============================================================

  void navigateToNetworkingSession(
    String projectId,
  ) {
    debugPrint(
      '[MATCH PAGE] '
      'Abrindo NetworkingSession: $projectId',
    );

    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              _,
            ) => NetworkingSessionView(
              projectId: projectId,
            ),
      ),
    );
  }

  // ============================================================
  // ABRIR CONFIGURAÇÕES PROFISSIONAIS
  // ============================================================

  Future<
    void
  >
  _openProfessionalProfileSettings() async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const ProfessionalProfileSettingsPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    // ==========================================================
    // RECARREGAR PERFIL
    // ==========================================================

    await _professionalProfileController.refresh();

    if (!mounted) {
      return;
    }

    // ==========================================================
    // REINICIAR MATCH
    // ==========================================================
    //
    // Se o usuário mudou:
    //
    // Beatmaker
    //
    // procura:
    // Artista
    //
    // para:
    //
    // Beatmaker
    //
    // procura:
    // Artista + Compositor
    //
    // precisamos recalcular os candidatos.
    //
    // ==========================================================

    await _restartMatchSearch();
  }

  // ============================================================
  // REINICIAR BUSCA
  // ============================================================

  Future<
    void
  >
  _restartMatchSearch() async {
    await _matchRepository.stopStreaming();

    if (!mounted) {
      return;
    }

    await _matchController.initMatchSession();

    if (!mounted) {
      return;
    }

    _matchRepository.streamCrossRoleMatches(
      _matchController,
    );
  }

  // ============================================================
  // EXPANDIR / RECOLHER
  // ============================================================

  void _toggleConnectionProfileCard() {
    setState(
      () {
        _isConnectionProfileExpanded = !_isConnectionProfileExpanded;
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _matchSubscription?.cancel();

    _matchSubscription = null;

    _matchController.removeListener(
      _onControllerUpdate,
    );

    _professionalProfileController.removeListener(
      _onControllerUpdate,
    );

    // ==========================================================
    // PARAR STREAM DE PERFIS
    // ==========================================================

    _matchRepository.stopStreaming();

    // ==========================================================
    // MATCH CONTROLLER
    // ==========================================================
    //
    // MatchController está registrado como Factory.
    //
    // Portanto essa instância pertence a esta página.
    //
    // ==========================================================

    _matchController.dispose();

    // ==========================================================
    // PROFESSIONAL PROFILE CONTROLLER
    // ==========================================================
    //
    // NÃO fazer:
    //
    // _professionalProfileController.dispose();
    //
    // Ele é LazySingleton compartilhado.
    //
    // ==========================================================

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final hasNoDiscovery =
        _matchController.discoveryUser ==
        null;

    final hasNoRecommendations = _matchController.recommendedUsers.isEmpty;

    return Scaffold(
      backgroundColor: const Color(
        0xFF0D0B1F,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // PERFIL DE CONEXÃO
            // ==================================================
            _buildConnectionProfileCard(),

            const SizedBox(
              height: 26,
            ),

            // ==================================================
            // NOVAS CONEXÕES
            // ==================================================
            _buildDiscoveryHeader(),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // DISCOVERY
            // ==================================================
            _buildDiscoverySection(
              hasNoDiscovery: hasNoDiscovery,
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // RECOMENDADOS
            // ==================================================
            const Text(
              'Recomendados para você',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            _buildRecommendationsSection(
              hasNoRecommendations: hasNoRecommendations,
            ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD — PERFIL DE CONEXÃO
  // ============================================================

  Widget _buildConnectionProfileCard() {
    final controller = _professionalProfileController;

    final lookingFor = controller.lookingForRoleLabels;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            const Color(
              0xFF17132D,
            ).withValues(
              alpha: 0.90,
            ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.07,
          ),
        ),
      ),
      child: Column(
        children: [
          // ====================================================
          // HEADER
          // ====================================================
          InkWell(
            onTap: _toggleConnectionProfileCard,
            borderRadius: BorderRadius.circular(
              22,
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                16,
              ),
              child: Row(
                children: [
                  // ============================================
                  // PERFIL
                  // ============================================
                  Tooltip(
                    message: 'Editar perfil profissional',
                    child: InkWell(
                      onTap: _openProfessionalProfileSettings,
                      borderRadius: BorderRadius.circular(
                        50,
                      ),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _matchController.accentNeon.withValues(
                            alpha: 0.10,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _matchController.accentNeon.withValues(
                              alpha: 0.30,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.person_search_rounded,
                          color: _matchController.accentNeon,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 13,
                  ),

                  // ============================================
                  // TEXTO
                  // ============================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Você quer se conectar com',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          controller.isLoading ||
                                  _isInitializingMatch
                              ? 'Carregando perfil...'
                              : lookingFor.isEmpty
                              ? 'Não informado'
                              : lookingFor.length ==
                                    1
                              ? '1 tipo de profissional'
                              : '${lookingFor.length} tipos de profissionais',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ============================================
                  // EDITAR
                  // ============================================
                  IconButton(
                    tooltip: 'Editar perfil profissional',
                    onPressed: _openProfessionalProfileSettings,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: _matchController.accentNeon,
                      size: 18,
                    ),
                  ),

                  // ============================================
                  // EXPANDIR
                  // ============================================
                  Icon(
                    _isConnectionProfileExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white54,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // ====================================================
          // EXPANDIDO
          // ====================================================
          AnimatedCrossFade(
            duration: const Duration(
              milliseconds: 180,
            ),
            crossFadeState: _isConnectionProfileExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildConnectionProfileExpandedContent(),
            secondChild: const SizedBox(
              width: double.infinity,
              height: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTEÚDO EXPANDIDO
  // ============================================================

  Widget _buildConnectionProfileExpandedContent() {
    final controller = _professionalProfileController;

    if (controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          18,
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.purpleAccent,
            ),
          ),
        ),
      );
    }

    final lookingForRoles = controller.lookingForRoles.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // FUNÇÃO PRINCIPAL
          // ====================================================
          Row(
            children: [
              const Text(
                'Sua função principal:',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),

              const SizedBox(
                width: 6,
              ),

              Flexible(
                child: Text(
                  controller.primaryRoleLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _matchController.accentNeon,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // QUEM PROCURA
          // ====================================================
          const Text(
            'PROFISSIONAIS PROCURADOS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          if (lookingForRoles.isEmpty)
            _buildEmptyLookingFor()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lookingForRoles.map(
                (
                  role,
                ) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _matchController.accentNeon.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                      border: Border.all(
                        color: _matchController.accentNeon.withValues(
                          alpha: 0.20,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          color: _matchController.accentNeon,
                          size: 13,
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Text(
                          role.label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // EDITAR
          // ====================================================
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openProfessionalProfileSettings,
              style: OutlinedButton.styleFrom(
                foregroundColor: _matchController.accentNeon,
                side: BorderSide(
                  color: _matchController.accentNeon.withValues(
                    alpha: 0.25,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.tune_rounded,
                size: 16,
              ),
              label: const Text(
                'EDITAR PERFIL PROFISSIONAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NÃO INFORMADO
  // ============================================================

  Widget _buildEmptyLookingFor() {
    return InkWell(
      onTap: _openProfessionalProfileSettings,
      borderRadius: BorderRadius.circular(
        12,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: 0.025,
          ),
          borderRadius: BorderRadius.circular(
            12,
          ),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white24,
              size: 17,
            ),

            const SizedBox(
              width: 9,
            ),

            const Expanded(
              child: Text(
                'Não informado. Toque para escolher '
                'com quem você deseja se conectar.',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: _matchController.accentNeon,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER — NOVAS CONEXÕES
  // ============================================================

  Widget _buildDiscoveryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Novas Conexões',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(
                height: 2,
              ),

              Text(
                'Encontre sua parceria profissional',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Filtros',
          icon: Icon(
            Icons.tune,
            color: _matchController.accentNeon,
          ),
          onPressed: _matchController.openFilters,
        ),
      ],
    );
  }

  // ============================================================
  // DISCOVERY
  // ============================================================

  Widget _buildDiscoverySection({
    required bool hasNoDiscovery,
  }) {
    if (_matchController.isLoading ||
        _isInitializingMatch) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: 0.02,
          ),
          borderRadius: BorderRadius.circular(
            24,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.purple,
          ),
        ),
      );
    }

    if (!hasNoDiscovery) {
      return DiscoveryCardWidget(
        controller: _matchController,
        user: _matchController.discoveryUser!,
      );
    }

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.02,
        ),
        borderRadius: BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_tethering,
            color: Colors.white24,
            size: 32,
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            'Nenhum profissional compatível encontrado.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECOMENDAÇÕES
  // ============================================================

  Widget _buildRecommendationsSection({
    required bool hasNoRecommendations,
  }) {
    if (_matchController.isLoading ||
        _isInitializingMatch) {
      return const Center(
        child: Text(
          'Procurando profissionais compatíveis...',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
      );
    }

    if (!hasNoRecommendations) {
      return Column(
        children: _matchController.recommendedUsers.map(
          (
            user,
          ) {
            return ProfileTileWidget(
              user: user,
              controller: _matchController,
            );
          },
        ).toList(),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 20,
      ),
      child: Center(
        child: Text(
          'Nenhuma recomendação disponível.',
          style: TextStyle(
            color: Colors.white24,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
