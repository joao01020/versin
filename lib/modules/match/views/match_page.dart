import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';
import 'package:versin/modules/match/data/repositories/match_repository.dart';
import 'package:versin/modules/match/models/match_user_entity.dart';
import 'package:versin/modules/match/widgets/discovery_card_widget.dart';
import 'package:versin/modules/match/widgets/profile_tile_widget.dart';

import 'package:versin/modules/networking/views/networking_session_view.dart';

import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';
import 'package:versin/modules/profile/views/professional_profile_settings_page.dart';

// ============================================================
// MATCH PAGE
// ============================================================
//
// Responsabilidades:
//
// - exibir cabeçalho do Conectar;
// - pesquisar usuários;
// - exibir configuração profissional;
// - exibir discovery;
// - exibir recomendações;
// - abrir networking;
// - reiniciar busca após alteração profissional.
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

  final TextEditingController _searchController = TextEditingController();

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
  // SEARCH
  // ============================================================

  Timer? _searchDebounce;

  final FocusNode _searchFocusNode = FocusNode();

  // ============================================================
  // ESTADO VISUAL
  // ============================================================

  bool _isConnectionProfileExpanded = true;

  bool _isInitializingMatch = true;

  bool _isSearchPanelOpen = false;

  // ============================================================
  // SEARCH STATE
  // ============================================================

  bool _isSearching = false;

  bool _isSearchActive = false;

  String _searchQuery = '';

  String? _searchError;

  List<
    MatchUserEntity
  >
  _searchResults = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

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

    _matchController.addListener(
      _onControllerUpdate,
    );

    _professionalProfileController.addListener(
      _onControllerUpdate,
    );

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

    _initializeMatch();
  }

  // ============================================================
  // INICIALIZAR MATCH
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
      await _professionalProfileController.load();

      if (!mounted) {
        return;
      }

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

      await _matchController.initMatchSession();

      if (!mounted) {
        return;
      }

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
  // ABRIR / FECHAR PESQUISA
  // ============================================================

  void _toggleSearchPanel() {
    setState(
      () {
        _isSearchPanelOpen = !_isSearchPanelOpen;
      },
    );

    if (_isSearchPanelOpen) {
      Future.delayed(
        const Duration(
          milliseconds: 120,
        ),
        () {
          if (!mounted) {
            return;
          }

          _searchFocusNode.requestFocus();
        },
      );

      return;
    }

    _clearSearch();
  }

  // ============================================================
  // PESQUISA
  // ============================================================

  void _handleSearchChanged(
    String value,
  ) {
    _searchDebounce?.cancel();

    final normalized = value.trim();

    if (normalized.isEmpty) {
      setState(
        () {
          _searchQuery = '';

          _isSearchActive = false;

          _isSearching = false;

          _searchError = null;

          _searchResults = [];
        },
      );

      return;
    }

    setState(
      () {
        _searchQuery = normalized;

        _isSearchActive = true;

        _searchError = null;
      },
    );

    _searchDebounce = Timer(
      const Duration(
        milliseconds: 350,
      ),
      () {
        _searchUsers(
          normalized,
        );
      },
    );
  }

  // ============================================================
  // PESQUISAR USUÁRIOS
  // ============================================================

  Future<
    void
  >
  _searchUsers(
    String query,
  ) async {
    if (query.trim().isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(
      () {
        _isSearching = true;

        _searchError = null;
      },
    );

    try {
      final users = await _matchRepository.searchUsers(
        query: query,
        currentUserId: _matchController.currentUserId,
      );

      if (!mounted) {
        return;
      }

      if (_searchQuery !=
          query.trim()) {
        return;
      }

      setState(
        () {
          _searchResults = users;

          _isSearching = false;
        },
      );
    } catch (
      error
    ) {
      debugPrint(
        '[MATCH PAGE] '
        'Erro ao pesquisar usuários: $error',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _isSearching = false;

          _searchResults = [];

          _searchError = 'Não foi possível pesquisar usuários.';
        },
      );
    }
  }

  // ============================================================
  // LIMPAR PESQUISA
  // ============================================================

  void _clearSearch() {
    _searchDebounce?.cancel();

    _searchController.clear();

    _searchFocusNode.unfocus();

    if (!mounted) {
      return;
    }

    setState(
      () {
        _searchQuery = '';

        _isSearchActive = false;

        _isSearching = false;

        _searchError = null;

        _searchResults = [];
      },
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

    await _professionalProfileController.refresh();

    if (!mounted) {
      return;
    }

    await _restartMatchSearch();
  }

  // ============================================================
  // REINICIAR MATCH
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
  // EXPANDIR CARD
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
    _searchDebounce?.cancel();

    _searchController.dispose();

    _searchFocusNode.dispose();

    _matchSubscription?.cancel();

    _matchSubscription = null;

    _matchController.removeListener(
      _onControllerUpdate,
    );

    _professionalProfileController.removeListener(
      _onControllerUpdate,
    );

    _matchRepository.stopStreaming();

    _matchController.dispose();

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
            // HEADER SUPERIOR
            // ==================================================
            _buildTopHeader(),

            // ==================================================
            // PESQUISA EXPANDIDA
            // ==================================================
            AnimatedSize(
              duration: const Duration(
                milliseconds: 180,
              ),
              curve: Curves.easeOut,
              child: _isSearchPanelOpen
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: 16,
                      ),
                      child: _buildSearchField(),
                    )
                  : const SizedBox.shrink(),
            ),

            // ==================================================
            // RESULTADOS
            // ==================================================
            if (_isSearchPanelOpen &&
                _isSearchActive) ...[
              const SizedBox(
                height: 16,
              ),

              _buildSearchResults(),
            ],

            const SizedBox(
              height: 22,
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
  // HEADER SUPERIOR
  // ============================================================

  Widget _buildTopHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ======================================================
        // TÍTULO
        // ======================================================
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conectar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(
                height: 3,
              ),

              Text(
                'Encontre pessoas para criar com você',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ======================================================
        // BOTÃO PESQUISAR
        // ======================================================
        Tooltip(
          message: _isSearchPanelOpen
              ? 'Fechar pesquisa'
              : 'Pesquisar usuário',
          child: InkWell(
            onTap: _toggleSearchPanel,
            borderRadius: BorderRadius.circular(
              14,
            ),
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 160,
              ),
              height: 42,
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
              ),
              decoration: BoxDecoration(
                color: _isSearchPanelOpen
                    ? _matchController.accentNeon.withValues(
                        alpha: 0.10,
                      )
                    : Colors.white.withValues(
                        alpha: 0.035,
                      ),
                borderRadius: BorderRadius.circular(
                  14,
                ),
                border: Border.all(
                  color: _isSearchPanelOpen
                      ? _matchController.accentNeon.withValues(
                          alpha: 0.30,
                        )
                      : Colors.white.withValues(
                          alpha: 0.07,
                        ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSearchPanelOpen
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                    color: _isSearchPanelOpen
                        ? _matchController.accentNeon
                        : Colors.white60,
                    size: 18,
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Text(
                    _isSearchPanelOpen
                        ? 'FECHAR'
                        : 'PESQUISAR',
                    style: TextStyle(
                      color: _isSearchPanelOpen
                          ? _matchController.accentNeon
                          : Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CAMPO DE PESQUISA
  // ============================================================

  Widget _buildSearchField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(
          0xFF17132D,
        ),
        borderRadius: BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: _isSearchActive
              ? _matchController.accentNeon.withValues(
                  alpha: 0.28,
                )
              : Colors.white.withValues(
                  alpha: 0.07,
                ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _handleSearchChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,

          hintText: 'Pesquisar por nome ou @usuario',

          hintStyle: const TextStyle(
            color: Colors.white24,
            fontSize: 11,
          ),

          prefixIcon: Icon(
            Icons.search_rounded,
            color: _isSearchActive
                ? _matchController.accentNeon
                : Colors.white38,
            size: 20,
          ),

          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Limpar',
                  onPressed: _clearSearch,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ============================================================
  // RESULTADOS DA PESQUISA
  // ============================================================

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 28,
        ),
        decoration: _searchResultDecoration(),
        child: const Center(
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

    if (_searchError !=
        null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          16,
        ),
        decoration: _searchResultDecoration(),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 18,
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child: Text(
                _searchError!,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 24,
          horizontal: 16,
        ),
        decoration: _searchResultDecoration(),
        child: Column(
          children: [
            const Icon(
              Icons.person_search_outlined,
              color: Colors.white24,
              size: 26,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Nenhum usuário encontrado para "$_searchQuery".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Resultados',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: _matchController.accentNeon.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
              child: Text(
                '${_searchResults.length}',
                style: TextStyle(
                  color: _matchController.accentNeon,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        ..._searchResults.map(
          (
            user,
          ) {
            return ProfileTileWidget(
              user: user,
              controller: _matchController,
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // DECORAÇÃO SEARCH
  // ============================================================

  BoxDecoration _searchResultDecoration() {
    return BoxDecoration(
      color:
          const Color(
            0xFF17132D,
          ).withValues(
            alpha: 0.65,
          ),
      borderRadius: BorderRadius.circular(
        16,
      ),
      border: Border.all(
        color: Colors.white.withValues(
          alpha: 0.05,
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

                  IconButton(
                    tooltip: 'Editar perfil profissional',
                    onPressed: _openProfessionalProfileSettings,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: _matchController.accentNeon,
                      size: 18,
                    ),
                  ),

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
  // CARD EXPANDIDO
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
