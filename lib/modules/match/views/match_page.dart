import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/app/locator.dart';

// ============================================================
// MATCH - CONSENTIMENTO
// ============================================================
import 'package:versin/modules/match/views/location_privacy_page.dart';
import 'package:versin/modules/match/services/match_location_consent_service.dart';
// ============================================================
// MATCH
// ============================================================

import 'package:versin/modules/match/controllers/match_controllers.dart';
import 'package:versin/modules/match/search/controllers/match_search_controller.dart';
import 'package:versin/modules/match/data/repositories/match_repository.dart';
import 'package:versin/modules/match/models/match_discovery_mode.dart';
import 'package:versin/modules/match/models/match_filter_state.dart';
// ============================================================
// MATCH - AVAILABILITY
// ============================================================

import 'package:versin/modules/match/availability/controllers/match_availability_controller.dart';
import 'package:versin/modules/match/availability/services/match_availability_service.dart';
import 'package:versin/modules/match/availability/widgets/match_availability_card.dart';
import 'package:versin/modules/match/availability/widgets/match_availability_duration_sheet.dart';

// ============================================================
// MATCH - TEAM EXPANSION
// ============================================================

import 'package:versin/modules/match/team_expansion/controllers/match_team_expansion_controller.dart';
import 'package:versin/modules/match/team_expansion/services/match_team_invitation_service.dart';
import 'package:versin/modules/match/team_expansion/widgets/team_expansion_notice.dart';

import 'package:versin/modules/match/services/match_session_service.dart';
import 'package:versin/modules/match/views/match_projects_view.dart';

// ============================================================
// MATCH WIDGETS
// ============================================================

import 'package:versin/modules/match/widgets/connection_profile_card_widget.dart';
import 'package:versin/modules/match/widgets/discovery_section_widget.dart';
import 'package:versin/modules/match/widgets/match_filter_sheet.dart';
import 'package:versin/modules/match/search/widgets/match_search_panel_widget.dart';
import 'package:versin/modules/match/search/widgets/match_search_results_widget.dart';
// ============================================================
// MATCH - DEMO
// ============================================================

import 'package:versin/modules/match/demo/controllers/match_demo_controller.dart';
import 'package:versin/modules/match/demo/widgets/profile_track_player_sheet.dart';

// ============================================================
// NETWORKING
// ============================================================

// ============================================================
// PROFESSIONAL PROFILE
// ============================================================

import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';
import 'package:versin/modules/profile/services/presence/user_presence_service.dart';
import 'package:versin/modules/profile/views/professional_profile_settings_page.dart';

// ============================================================
// PUBLIC PROFILE
// ============================================================

import 'package:versin/modules/public_profile/controllers/public_profile_controller.dart';
import 'package:versin/modules/public_profile/data/repositories/public_profile_repository_impl.dart';
import 'package:versin/modules/public_profile/services/profile_track_service.dart';
import 'package:versin/modules/public_profile/views/public_profile_page.dart';

// ============================================================
// MATCH PAGE
// ============================================================
//
// Responsável por:
//
// - inicializar Match;
// - controlar busca;
// - controlar filtros;
// - controlar modo de descoberta;
// - abrir perfis;
// - abrir Networking;
// - buscar uma demo;
// - obter UMA playback URL;
// - abrir o player.
//
// NÃO:
//
// - acessa R2 diretamente;
// - assina URL;
// - reproduz áudio diretamente.
//
// ============================================================

class MatchPage
    extends
        StatefulWidget {
  static const String routeName = '/match';

  // ============================================================
  // EXPANSÃO DE EQUIPE
  // ============================================================
  //
  // null:
  // -> Match normal;
  // -> match mútuo cria uma nova Studio Session.
  //
  // preenchido:
  // -> Match aberto a partir de uma Studio Session;
  // -> objetivo é procurar profissionais para convidar;
  // -> NÃO deve criar outro projeto automaticamente.
  //
  // ============================================================

  final String? targetProjectId;

  final String? targetProjectTitle;

  const MatchPage({
    super.key,
    this.targetProjectId,
    this.targetProjectTitle,
  });

  bool get isTeamExpansionMode {
    final projectId = targetProjectId?.trim();

    return projectId !=
            null &&
        projectId.isNotEmpty;
  }

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

  late final MatchSearchController _matchSearchController;

  late final ProfessionalProfileController _professionalProfileController;

  late final PublicProfileController _publicProfileController;

  late final MatchTeamExpansionController _teamExpansionController;

  late final MatchDemoController _demoController;

  // ============================================================
  // SERVICES
  // ============================================================

  late final MatchRepository _matchRepository;

  late final MatchSessionService _sessionService;

  late final MatchLocationConsentService _locationConsentService;

  late final MatchAvailabilityController _availabilityController;

  late final UserPresenceService _presenceService;

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController _searchTextController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  // ============================================================
  // USERNAME ONBOARDING
  // ============================================================

  final TextEditingController _usernameController = TextEditingController();

  final FocusNode _usernameFocusNode = FocusNode();

  Timer? _usernameDebounce;

  bool _isSearchPanelOpen = false;

  // ============================================================
  // CONFIRMAR MODO POR PROXIMIDADE
  // ============================================================

  Future<
    void
  >
  _confirmNearbyDiscovery() async {
    if (!mounted ||
        _isInitializingMatch ||
        _sessionService.isRestarting) {
      return;
    }

    // ==========================================================
    // VERIFICAR SE JÁ EXISTE CONSENTIMENTO
    // ==========================================================

    try {
      final alreadyAccepted = await _locationConsentService.hasAcceptedNearbyLocation();

      if (!mounted) {
        return;
      }

      if (alreadyAccepted) {
        debugPrint(
          '[MATCH PAGE] '
          'Consentimento de localização já registrado.',
        );

        await _changeDiscoveryMode(
          MatchDiscoveryMode.nearby,
        );

        return;
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH PAGE] '
        'Erro ao consultar consentimento: $error',
      );

      debugPrint(
        '[MATCH PAGE] '
        'Stack trace: $stackTrace',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
          context,
        )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível verificar a confirmação de localização.',
            ),
          ),
        );

      return;
    }

    // ==========================================================
    // MOSTRAR AVISO
    // ==========================================================

    bool accepted = false;

    debugPrint(
      '[MATCH PAGE] '
      'Exibindo confirmação inicial de localização.',
    );

    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          barrierDismissible: false,

          builder:
              (
                dialogContext,
              ) {
                return StatefulBuilder(
                  builder:
                      (
                        context,
                        setDialogState,
                      ) {
                        return AlertDialog(
                          backgroundColor: const Color(
                            0xFF17132D,
                          ),

                          surfaceTintColor: Colors.transparent,

                          title: const Text(
                            'Encontrar profissionais próximos',

                            style: TextStyle(
                              color: Colors.white,

                              fontSize: 16,

                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          content: Column(
                            mainAxisSize: MainAxisSize.min,

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              const Text(
                                'Usamos sua localização apenas para '
                                'encontrar profissionais próximos de você.\n\n'
                                'Sua posição é usada para calcular a '
                                'distância entre perfis e melhorar os '
                                'resultados do modo Próximos.',

                                style: TextStyle(
                                  color: Colors.white60,

                                  fontSize: 12,

                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(
                                height: 16,
                              ),
                              Align(
                                alignment: Alignment.centerLeft,

                                child: TextButton.icon(
                                  onPressed: () async {
                                    await Navigator.of(
                                      dialogContext,
                                    ).push(
                                      MaterialPageRoute(
                                        builder:
                                            (
                                              _,
                                            ) {
                                              return const LocationPrivacyPage();
                                            },
                                      ),
                                    );
                                  },

                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 15,
                                  ),

                                  label: const Text(
                                    'Como usamos sua localização',
                                  ),
                                ),
                              ),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,

                                controlAffinity: ListTileControlAffinity.leading,

                                value: accepted,

                                activeColor: _matchController.accentNeon,

                                checkColor: Colors.black,

                                title: const Text(
                                  'Confirmo que entendi e permito '
                                  'o uso da minha localização para '
                                  'encontrar profissionais próximos.',

                                  style: TextStyle(
                                    color: Colors.white70,

                                    fontSize: 11,

                                    height: 1.4,
                                  ),
                                ),

                                onChanged:
                                    (
                                      value,
                                    ) {
                                      setDialogState(
                                        () {
                                          accepted =
                                              value ??
                                              false;
                                        },
                                      );
                                    },
                              ),
                            ],
                          ),

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
                              ),
                            ),

                            FilledButton(
                              onPressed: accepted
                                  ? () {
                                      Navigator.of(
                                        dialogContext,
                                      ).pop(
                                        true,
                                      );
                                    }
                                  : null,

                              child: const Text(
                                'CONTINUAR',
                              ),
                            ),
                          ],
                        );
                      },
                );
              },
        );

    // ==========================================================
    // CANCELADO
    // ==========================================================

    if (!mounted ||
        confirmed !=
            true) {
      debugPrint(
        '[MATCH PAGE] '
        'Consentimento de localização não confirmado.',
      );

      return;
    }

    // ==========================================================
    // SALVAR CONSENTIMENTO
    // ==========================================================

    try {
      await _locationConsentService.acceptNearbyLocation();

      debugPrint(
        '[MATCH PAGE] '
        'Consentimento de localização salvo.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH PAGE] '
        'Erro ao salvar consentimento: $error',
      );

      debugPrint(
        '[MATCH PAGE] '
        'Stack trace: $stackTrace',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
          context,
        )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar sua confirmação.',
            ),
          ),
        );

      return;
    }

    if (!mounted) {
      return;
    }

    // ==========================================================
    // ENTRAR NO MODO PRÓXIMOS
    // ==========================================================

    await _changeDiscoveryMode(
      MatchDiscoveryMode.nearby,
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  MatchFilterState _filterState = const MatchFilterState.initial();

  // ============================================================
  // STATE
  // ============================================================

  bool _isInitializingMatch = true;

  bool _usernameWasSeeded = false;

  // ============================================================
  // STREAM
  // ============================================================

  StreamSubscription<
    String
  >?
  _matchSubscription;

  // ============================================================
  // PAGE MODE
  // ============================================================

  bool get _isTeamExpansionMode => widget.isTeamExpansionMode;

  String? get _targetProjectId {
    final value = widget.targetProjectId?.trim();

    if (value ==
            null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  String get _targetProjectTitle {
    final value = widget.targetProjectTitle?.trim();

    if (value !=
            null &&
        value.isNotEmpty) {
      return value;
    }

    return 'Studio Session';
  }

  // ============================================================
  // AUTH
  // ============================================================

  String? get _authenticatedUserId {
    final id = Supabase.instance.client.auth.currentUser?.id.trim();

    if (id ==
            null ||
        id.isEmpty) {
      return null;
    }

    return id;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _setupDependencies();

    _setupListeners();

    debugPrint(
      '[MATCH PAGE] '
      'Modo: '
      '${_isTeamExpansionMode ? "expansão de equipe" : "match normal"}'
      '${_targetProjectId != null ? " | projeto: $_targetProjectId" : ""}',
    );

    unawaited(
      _initializeMatch(),
    );
  }

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  void _setupDependencies() {
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

    _matchSearchController = MatchSearchController(
      repository: _matchRepository,
      currentUserIdProvider: () {
        return _matchController.currentUserId;
      },
    );

    _sessionService = MatchSessionService(
      matchController: _matchController,
      matchRepository: _matchRepository,
      professionalProfileController: _professionalProfileController,
    );

    _locationConsentService = MatchLocationConsentService();

    _availabilityController = MatchAvailabilityController(
      availabilityService: MatchAvailabilityService(),
    );

    _teamExpansionController = MatchTeamExpansionController(
      invitationService: MatchTeamInvitationService(),
      projectId: _targetProjectId,
      projectTitle: _targetProjectTitle,
    );

    _presenceService =
        sl<
          UserPresenceService
        >();

    _publicProfileController = PublicProfileController(
      repository: PublicProfileRepositoryImpl(),
      trackService: ProfileTrackService(),
    );

    _demoController = MatchDemoController(
      publicProfileController: _publicProfileController,
    );
  }

  // ============================================================
  // LISTENERS
  // ============================================================

  void _setupListeners() {
    _matchController.addListener(
      _handleStateChange,
    );

    _professionalProfileController.addListener(
      _handleStateChange,
    );

    _matchSearchController.addListener(
      _handleStateChange,
    );

    _publicProfileController.addListener(
      _handleStateChange,
    );

    _availabilityController.addListener(
      _handleStateChange,
    );

    _teamExpansionController.addListener(
      _handleStateChange,
    );

    _demoController.addListener(
      _handleStateChange,
    );

    _matchSubscription = _matchController.matchEventStream.listen(
      _handleMatchEvent,
      onError:
          (
            error,
          ) {
            debugPrint(
              '[MATCH PAGE] '
              'Erro no stream: '
              '$error',
            );
          },
    );
  }

  // ============================================================
  // STATE CHANGE
  // ============================================================

  void _handleStateChange() {
    if (!mounted) {
      return;
    }

    _syncUsernameFieldFromController();

    setState(
      () {},
    );
  }

  // ============================================================
  // SINCRONIZAR USERNAME NO CAMPO
  // ============================================================

  void _syncUsernameFieldFromController() {
    final username = _matchController.currentUsername.trim();

    if (username.isEmpty) {
      return;
    }

    if (_usernameFocusNode.hasFocus) {
      return;
    }

    if (_usernameWasSeeded &&
        _usernameController.text.trim() ==
            username) {
      return;
    }

    _usernameWasSeeded = true;

    _usernameController.value = TextEditingValue(
      text: username,
      selection: TextSelection.collapsed(
        offset: username.length,
      ),
    );
  }

  // ============================================================
  // INITIALIZE
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
      await _sessionService.initialize();

      _syncUsernameFieldFromController();

      await _loadPublicProfile();

      await _availabilityController.initialize();
    } catch (
      error
    ) {
      debugPrint(
        '[MATCH PAGE] '
        'Erro ao inicializar: '
        '$error',
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
  // LOAD PUBLIC PROFILE
  // ============================================================

  Future<
    void
  >
  _loadPublicProfile() async {
    final userId = _authenticatedUserId;

    if (userId ==
        null) {
      debugPrint(
        '[PUBLIC PROFILE] '
        'Usuário não autenticado.',
      );

      return;
    }

    await _publicProfileController.load(
      userId: userId,
    );

    final profile = _publicProfileController.profile;

    if (profile ==
        null) {
      debugPrint(
        '[PUBLIC PROFILE] '
        'Perfil não encontrado.',
      );

      return;
    }

    debugPrint(
      '[PUBLIC PROFILE] '
      'Perfil carregado: '
      '${profile.resolvedDisplayName}',
    );
  }

  // ============================================================
  // GUARD DE ONBOARDING
  // ============================================================
  //
  // Enquanto faltar username:
  //
  // - o bloco "Complete seu perfil" é obrigatório.
  //
  // Depois do username:
  //
  // - se faltar função principal, o único caminho permitido
  //   é "EDITAR PERFIL PROFISSIONAL".
  //
  // Qualquer tentativa de usar outra área solicita atenção ao
  // botão profissional através do MatchController.
  //
  // ============================================================

  bool _ensureMatchUnlockedForInteraction() {
    if (_matchController.isMatchUnlocked) {
      return true;
    }

    if (_matchController.requiresUsername) {
      _usernameFocusNode.requestFocus();

      return false;
    }

    if (_matchController.requiresProfessionalProfile) {
      _matchController.requestProfessionalProfileAttention();

      return false;
    }

    return false;
  }

  // ============================================================
  // USERNAME CHANGED
  // ============================================================

  void _handleUsernameChanged(
    String value,
  ) {
    _usernameDebounce?.cancel();

    _matchController.resetUsernameCheck();

    final validationError = _matchController.validateUsername(
      value,
    );

    if (validationError !=
        null) {
      // O próprio controller já exibirá o erro assim que
      // checkUsernameAvailability() for chamado.
      //
      // Fazemos a chamada imediatamente apenas para manter
      // a mensagem visual consistente.
      unawaited(
        _matchController.checkUsernameAvailability(
          value,
        ),
      );

      return;
    }

    _usernameDebounce = Timer(
      const Duration(
        milliseconds: 450,
      ),
      () {
        if (!mounted) {
          return;
        }

        unawaited(
          _matchController.checkUsernameAvailability(
            value,
          ),
        );
      },
    );
  }

  // ============================================================
  // SALVAR USERNAME
  // ============================================================

  Future<
    void
  >
  _saveUsername() async {
    if (!mounted ||
        !_matchController.canSubmitUsername) {
      return;
    }

    final saved = await _matchController.saveUsername(
      _usernameController.text,
    );

    if (!mounted) {
      return;
    }

    if (!saved) {
      return;
    }

    _usernameFocusNode.unfocus();

    // Depois do username, o próximo passo obrigatório passa a
    // ser o perfil profissional.
    _matchController.requestProfessionalProfileAttention();

    setState(
      () {},
    );
  }

  // ============================================================
  // OPEN PUBLIC PROFILE
  // ============================================================

  Future<
    void
  >
  _openPublicProfile({
    bool highlightOnlineOnOpen = false,
  }) async {
    if (!_ensureMatchUnlockedForInteraction()) {
      return;
    }

    final userId = _authenticatedUserId;

    if (userId ==
            null ||
        !mounted) {
      return;
    }

    if (_publicProfileController.loadedUserId !=
        userId) {
      await _publicProfileController.load(
        userId: userId,
      );
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              _,
            ) {
              return PublicProfilePage(
                userId: userId,
                controller: _publicProfileController,
                highlightOnlineOnOpen: highlightOnlineOnOpen,
              );
            },
      ),
    );

    if (!mounted) {
      return;
    }

    await _publicProfileController.refresh();
  }

  // ============================================================
  // OPEN MATCH PROJECTS
  // ============================================================

  Future<
    void
  >
  _openMatchProjects() async {
    if (!mounted ||
        !_ensureMatchUnlockedForInteraction()) {
      return;
    }

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute<
        void
      >(
        builder:
            (
              _,
            ) {
              return const MatchProjectsView();
            },
      ),
    );
  }

  // ============================================================
  // OPEN USER DEMO
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Esta é a ÚNICA entrada de demo desta página.
  //
  // DiscoveryCard
  //      ↓
  // DiscoverySection
  //      ↓
  // _openUserDemo()
  //      ↓
  // getFirstTrackPlaybackForUser()
  //      ↓
  // UMA chamada para create-track-playback-url
  //      ↓
  // ProfileTrackPlayerSheet
  //
  // ============================================================

  Future<
    void
  >
  _openUserDemo(
    String userId,
  ) async {
    if (!_ensureMatchUnlockedForInteraction()) {
      return;
    }

    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty ||
        !mounted) {
      return;
    }

    if (_demoController.isLoading) {
      debugPrint(
        '[MATCH DEMO] '
        'Solicitação ignorada: '
        'demo já está carregando.',
      );

      return;
    }

    final discoveryUser = _matchController.discoveryUser;

    final displayName =
        discoveryUser !=
                null &&
            discoveryUser.id ==
                normalizedUserId &&
            discoveryUser.name.trim().isNotEmpty
        ? discoveryUser.name.trim()
        : 'Profissional';

    try {
      final demo = await _demoController.load(
        userId: normalizedUserId,
      );

      if (!mounted ||
          demo ==
              null) {
        return;
      }

      await ProfileTrackPlayerSheet.show(
        context: context,
        track: demo.track,
        playbackUrl: demo.playbackUrl,
        displayName: displayName,
        accentColor: _matchController.accentNeon,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH DEMO] '
        'Erro ao abrir demo: '
        '$error',
      );

      debugPrint(
        '[MATCH DEMO] '
        'Stack trace: '
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
          context,
        )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _demoController.errorMessage ??
                  'Não foi possível carregar a demo.',
            ),
          ),
        );
    }
  }

  // ============================================================
  // INVITE USER TO PROJECT
  // ============================================================

  Future<
    bool
  >
  _inviteUserToProject(
    String userId,
  ) async {
    if (!_ensureMatchUnlockedForInteraction()) {
      return false;
    }

    if (!mounted ||
        !_isTeamExpansionMode) {
      return false;
    }

    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    final discoveryUser = _matchController.discoveryUser;

    final displayName =
        discoveryUser !=
                null &&
            discoveryUser.id.trim() ==
                normalizedUserId
        ? discoveryUser.name.trim()
        : '';

    final resolvedName = displayName.isNotEmpty
        ? displayName
        : 'Profissional';

    try {
      final result = await _teamExpansionController.invite(
        userId: normalizedUserId,
      );

      if (!mounted) {
        return result.wasCreated;
      }

      switch (result.status) {
        case MatchTeamInvitationStatus.invited:
          _showInvitationMessage(
            'Convite enviado para $resolvedName.',
          );

          return true;

        case MatchTeamInvitationStatus.alreadyPending:
          _showInvitationMessage(
            'Este usuário já possui um convite pendente.',
            isError: true,
          );

          return false;

        case MatchTeamInvitationStatus.alreadyMember:
          _showInvitationMessage(
            'Este usuário já faz parte da equipe.',
            isError: true,
          );

          return false;
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH PAGE] '
        'Erro ao convidar usuário para a equipe: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return false;
      }

      final controllerMessage = _teamExpansionController.errorMessage?.trim();

      _showInvitationMessage(
        controllerMessage !=
                    null &&
                controllerMessage.isNotEmpty
            ? controllerMessage
            : 'Não foi possível enviar o convite.',
        isError: true,
      );

      return false;
    }
  }

  // ============================================================
  // INVITATION MESSAGE
  // ============================================================

  void _showInvitationMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),

          backgroundColor: isError
              ? Colors.red.shade900
              : const Color(
                  0xFF4C1D95,
                ),
        ),
      );
  }

  // ============================================================
  // MATCH EVENT
  // ============================================================
  //
  // O evento de Match não abre mais o projeto automaticamente.
  //
  // O projeto continua sendo criado/encontrado normalmente pelo
  // fluxo do Match. O usuário escolhe quando deseja entrar através
  // da página "Meus projetos".
  //
  // ============================================================

  void _handleMatchEvent(
    String projectId,
  ) {
    if (!mounted) {
      return;
    }

    final normalizedProjectId = projectId.trim();

    if (normalizedProjectId.isEmpty) {
      return;
    }

    // ==========================================================
    // MODO EXPANSÃO
    // ==========================================================

    if (_isTeamExpansionMode) {
      debugPrint(
        '[MATCH PAGE] '
        'Evento de Match ignorado no modo de expansão. '
        'Projeto recebido: '
        '$normalizedProjectId',
      );

      return;
    }

    // ==========================================================
    // MATCH NORMAL
    // ==========================================================

    debugPrint(
      '[MATCH PAGE] '
      'Match recebido. '
      'Projeto disponível em Meus projetos: '
      '$normalizedProjectId',
    );
  }

  // ============================================================
  // SEARCH TOGGLE
  // ============================================================

  void _toggleSearchPanel() {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _isSearchPanelOpen = !_isSearchPanelOpen;
      },
    );

    if (_isSearchPanelOpen) {
      _focusSearchField();

      return;
    }

    _clearSearch();
  }

  // ============================================================
  // SEARCH FOCUS
  // ============================================================

  void _focusSearchField() {
    Future.delayed(
      const Duration(
        milliseconds: 120,
      ),
      () {
        if (!mounted ||
            !_isSearchPanelOpen) {
          return;
        }

        _searchFocusNode.requestFocus();
      },
    );
  }

  // ============================================================
  // SEARCH CHANGED
  // ============================================================

  void _handleSearchChanged(
    String value,
  ) {
    _matchSearchController.onQueryChanged(
      value,
    );
  }

  // ============================================================
  // SEARCH CLEAR
  // ============================================================

  void _clearSearch() {
    _searchTextController.clear();

    _searchFocusNode.unfocus();

    _matchSearchController.clear();
  }

  // ============================================================
  // DISPONÍVEIS AGORA
  // ============================================================
  //
  // A feature de disponibilidade vive em:
  //
  // match/availability/
  //
  // A MatchPage mantém somente a orquestração que depende de:
  //
  // - presença online;
  // - navegação;
  // - modo de descoberta.
  //
  // Estado, timer, persistência e UI pertencem ao módulo
  // MatchAvailability.
  //
  // ============================================================

  Future<
    bool
  >
  _ensureAvailabilityBeforeEntering() async {
    // ==========================================================
    // 1. EXIGIR PRESENÇA REAL
    // ==========================================================

    final reallyOnline = await _presenceService.ensureReallyOnline();

    if (!mounted) {
      return false;
    }

    if (!reallyOnline) {
      _presenceService.requestOnlineAttention();

      ScaffoldMessenger.of(
          context,
        )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Fique online primeiro para usar Disponíveis agora.',
            ),
          ),
        );

      await _openPublicProfile(
        highlightOnlineOnOpen: true,
      );

      if (!mounted) {
        return false;
      }

      final onlineAfterProfile = await _presenceService.ensureReallyOnline();

      if (!mounted ||
          !onlineAfterProfile) {
        return false;
      }
    }

    // ==========================================================
    // 2. JÁ ESTÁ DISPONÍVEL
    // ==========================================================

    if (_availabilityController.isActive) {
      return true;
    }

    // ==========================================================
    // 3. ESCOLHER DURAÇÃO
    // ==========================================================

    final selectedMinutes = await MatchAvailabilityDurationSheet.show(
      context: context,
      accentColor: _matchController.accentNeon,
    );

    if (!mounted ||
        selectedMinutes ==
            null) {
      return false;
    }

    // ==========================================================
    // 4. ATIVAR
    // ==========================================================

    final activated = await _availabilityController.activate(
      minutes: selectedMinutes,
    );

    if (!mounted) {
      return false;
    }

    if (!activated) {
      ScaffoldMessenger.of(
          context,
        )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Não foi possível ativar sua disponibilidade.',
            ),
          ),
        );

      return false;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Disponível agora por '
            '${_availabilityController.durationLabel(selectedMinutes)}.',
          ),
        ),
      );

    return true;
  }

  // ============================================================
  // ENCERRAR DISPONIBILIDADE
  // ============================================================

  Future<
    void
  >
  _clearAvailability() async {
    if (!mounted ||
        _availabilityController.isLoading) {
      return;
    }

    final cleared = await _availabilityController.clear();

    if (!mounted) {
      return;
    }

    if (!cleared) {
      ScaffoldMessenger.of(
          context,
        )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Não foi possível encerrar sua disponibilidade.',
            ),
          ),
        );

      return;
    }

    if (_matchController.discoveryMode ==
        MatchDiscoveryMode.global) {
      await _sessionService.changeDiscoveryMode(
        MatchDiscoveryMode.compatible,
      );
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Disponibilidade encerrada.',
          ),
        ),
      );
  }

  // ============================================================
  // DISCOVERY MODE
  // ============================================================

  Future<
    void
  >
  _changeDiscoveryMode(
    MatchDiscoveryMode mode,
  ) async {
    if (!_ensureMatchUnlockedForInteraction()) {
      return;
    }

    if (!mounted ||
        _isInitializingMatch ||
        _sessionService.isRestarting) {
      return;
    }

    if (mode ==
        MatchDiscoveryMode.global) {
      final canEnter = await _ensureAvailabilityBeforeEntering();

      if (!mounted ||
          !canEnter) {
        return;
      }
    }

    if (_matchController.discoveryMode ==
        mode) {
      return;
    }

    setState(
      () {
        _isInitializingMatch = true;
      },
    );

    try {
      await _sessionService.changeDiscoveryMode(
        mode,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH PAGE] '
        'Erro ao alterar modo de descoberta: '
        '$error',
      );

      debugPrint(
        '[MATCH PAGE] '
        'Stack trace: '
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
          context,
        )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível alterar o modo de descoberta.',
            ),
          ),
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
  // FILTERS
  // ============================================================

  Future<
    void
  >
  _openFilters() async {
    if (!_ensureMatchUnlockedForInteraction()) {
      return;
    }

    final result = await MatchFilterSheet.show(
      context: context,
      initialState: _filterState,
      accentColor: _matchController.accentNeon,
    );

    if (!mounted ||
        result ==
            null) {
      return;
    }

    setState(
      () {
        _filterState = result;
      },
    );
  }

  // ============================================================
  // PROFESSIONAL PROFILE
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
            ) {
              return const ProfessionalProfileSettingsPage();
            },
      ),
    );

    if (!mounted) {
      return;
    }

    setState(
      () {
        _isInitializingMatch = true;
      },
    );

    try {
      await _matchController.refreshMatchOnboarding();

      if (!mounted) {
        return;
      }

      if (_matchController.isMatchUnlocked) {
        await _sessionService.refreshProfileAndRestart();
      }

      await _loadPublicProfile();
    } catch (
      error
    ) {
      debugPrint(
        '[MATCH PAGE] '
        'Erro ao atualizar perfil: '
        '$error',
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final searchState = _matchSearchController.state;

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
              height: 2,
            ),

            // ==================================================
            // TEAM EXPANSION CONTEXT
            // ==================================================
            if (_isTeamExpansionMode) ...[
              TeamExpansionNotice(
                projectTitle: _teamExpansionController.displayProjectTitle,
                accentColor: _matchController.accentNeon,
              ),

              const SizedBox(
                height: 12,
              ),
            ],

            // ==================================================
            // SEARCH
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

                      child: MatchSearchPanelWidget(
                        textController: _searchTextController,

                        focusNode: _searchFocusNode,

                        isActive: searchState.isActive,

                        accentColor: _matchController.accentNeon,

                        onChanged: _handleSearchChanged,

                        onClear: _clearSearch,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // ==================================================
            // SEARCH RESULTS
            // ==================================================
            if (_isSearchPanelOpen &&
                searchState.isActive) ...[
              const SizedBox(
                height: 16,
              ),

              MatchSearchResultsWidget(
                controller: _matchController,

                isSearching: searchState.isSearching,

                query: searchState.query,

                errorMessage: searchState.errorMessage,

                results: searchState.results,
              ),
            ],

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // NOVAS CONEXÕES
            // ==================================================
            //
            // Esta passa a ser a área principal da tela.
            //
            // O perfil profissional fica logo abaixo do título
            // e pode recolher automaticamente para ocupar o
            // mínimo possível de espaço.
            //
            // ==================================================
            _buildDiscoveryHeader(),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // USERNAME ONBOARDING
            // ==================================================
            if (!_isInitializingMatch &&
                _matchController.requiresUsername) ...[
              _buildUsernameOnboardingCard(),

              const SizedBox(
                height: 10,
              ),
            ],

            // ==================================================
            // PROFESSIONAL PROFILE
            // ==================================================
            ConnectionProfileCardWidget(
              matchController: _matchController,

              profileController: _professionalProfileController,

              isInitializingMatch: _isInitializingMatch,

              onEditProfile: _openProfessionalProfileSettings,
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // DISCOVERY MODE
            // ==================================================
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _matchController.isMatchUnlocked
                  ? null
                  : () {
                      _ensureMatchUnlockedForInteraction();
                    },
              child: IgnorePointer(
                ignoring: !_matchController.isMatchUnlocked,
                child: Opacity(
                  opacity: _matchController.isMatchUnlocked
                      ? 1
                      : 0.42,
                  child: _buildDiscoveryModeSelector(),
                ),
              ),
            ),

            if (_matchController.discoveryMode ==
                    MatchDiscoveryMode.global ||
                _availabilityController.isActive) ...[
              const SizedBox(
                height: 10,
              ),

              MatchAvailabilityCard(
                controller: _availabilityController,
                accentColor: _matchController.accentNeon,
                onActivate: () {
                  unawaited(
                    _changeDiscoveryMode(
                      MatchDiscoveryMode.global,
                    ),
                  );
                },
                onClear: () {
                  unawaited(
                    _clearAvailability(),
                  );
                },
              ),
            ],

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // DISCOVERY
            // ==================================================
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _matchController.isMatchUnlocked
                  ? null
                  : () {
                      _ensureMatchUnlockedForInteraction();
                    },
              child: IgnorePointer(
                ignoring: !_matchController.isMatchUnlocked,
                child: Opacity(
                  opacity: _matchController.isMatchUnlocked
                      ? 1
                      : 0.42,
                  child: Stack(
                    children: [
                      // ==================================================
                      // DISCOVERY CARD
                      // ==================================================
                      //
                      // A chave acompanha o usuário atual para garantir
                      // que o card seja reconstruído corretamente quando
                      // o controller avançar para o próximo candidato.
                      //
                      // ==================================================
                      AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: 220,
                        ),

                        switchInCurve: Curves.easeOut,

                        switchOutCurve: Curves.easeIn,

                        child: DiscoverySectionWidget(
                          key:
                              ValueKey<
                                String
                              >(
                                _matchController.discoveryUser?.id ??
                                    'discovery-empty',
                              ),

                          controller: _matchController,

                          isInitializingMatch:
                              _isInitializingMatch ||
                              _teamExpansionController.isBusy,

                          isTeamExpansionMode: _isTeamExpansionMode,

                          onInviteUser: _isTeamExpansionMode
                              ? _inviteUserToProject
                              : null,

                          // ============================================
                          // ASYNC CALLBACK
                          // ============================================
                          onListenDemo: _openUserDemo,
                        ),
                      ),

                      // ==============================================
                      // LOADING
                      // ==============================================
                      if (_demoController.isLoading)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(
                                  alpha: 0.30,
                                ),

                                borderRadius: BorderRadius.circular(
                                  24,
                                ),
                              ),

                              alignment: Alignment.center,

                              child: CircularProgressIndicator(
                                color: _matchController.accentNeon,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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
  // USERNAME ONBOARDING CARD
  // ============================================================

  Widget _buildUsernameOnboardingCard() {
    final accentColor = _matchController.accentNeon;

    final message = _matchController.usernameValidationMessage;

    final available = _matchController.usernameAvailable;

    final checking = _matchController.isCheckingUsername;

    final saving = _matchController.isSavingUsername;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF17132D,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.28,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(
              alpha: 0.08,
            ),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: accentColor,
                  size: 19,
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
                      'Complete seu perfil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Escolha um username único para continuar no Match.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'Como você quer ser chamado?',
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
            controller: _usernameController,
            focusNode: _usernameFocusNode,
            enabled: !saving,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            onChanged: _handleUsernameChanged,
            onSubmitted:
                (
                  _,
                ) {
                  if (_matchController.canSubmitUsername) {
                    unawaited(
                      _saveUsername(),
                    );
                  }
                },
            decoration: InputDecoration(
              hintText: 'lucasvinicius',
              hintStyle: const TextStyle(
                color: Colors.white24,
              ),
              prefixText: '@',
              prefixStyle: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
              suffixIcon: checking
                  ? Padding(
                      padding: const EdgeInsets.all(
                        13,
                      ),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: accentColor,
                        ),
                      ),
                    )
                  : available ==
                        true
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.greenAccent,
                      size: 19,
                    )
                  : available ==
                        false
                  ? const Icon(
                      Icons.cancel_rounded,
                      color: Colors.redAccent,
                      size: 19,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(
                alpha: 0.035,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ),
                borderSide: BorderSide(
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ),
                borderSide: BorderSide(
                  color: accentColor.withValues(
                    alpha: 0.65,
                  ),
                ),
              ),
            ),
          ),

          if (message !=
              null) ...[
            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                if (checking)
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: accentColor,
                    ),
                  )
                else
                  Icon(
                    available ==
                            true
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 14,
                    color:
                        available ==
                            true
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),

                const SizedBox(
                  width: 6,
                ),

                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: checking
                          ? Colors.white38
                          : available ==
                                true
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(
            height: 16,
          ),

          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _matchController.canSubmitUsername
                  ? () {
                      unawaited(
                        _saveUsername(),
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withValues(
                  alpha: 0.05,
                ),
                disabledForegroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'CONTINUAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISCOVERY MODE SELECTOR
  // ============================================================

  Widget _buildDiscoveryModeSelector() {
    final activeMode = _matchController.discoveryMode;

    final disabled =
        _isInitializingMatch ||
        _sessionService.isRestarting;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        4,
      ),

      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.035,
        ),

        borderRadius: BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),

      child: Row(
        children: [
          // ========================================================
          // COMPATÍVEIS
          // ========================================================
          Expanded(
            child: _buildDiscoveryModeButton(
              mode: MatchDiscoveryMode.compatible,

              icon: Icons.auto_awesome_rounded,

              label: 'COMPATÍVEIS',

              selected:
                  activeMode ==
                  MatchDiscoveryMode.compatible,

              disabled: disabled,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          // ========================================================
          // PROXIMIDADE
          // ========================================================
          Expanded(
            child: _buildDiscoveryModeButton(
              mode: MatchDiscoveryMode.nearby,

              icon: Icons.near_me_rounded,

              label: 'PRÓXIMOS',

              selected:
                  activeMode ==
                  MatchDiscoveryMode.nearby,

              disabled: disabled,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          // ========================================================
          // DISPONÍVEIS AGORA
          // ========================================================
          Expanded(
            child: _buildDiscoveryModeButton(
              mode: MatchDiscoveryMode.global,

              icon: Icons.bolt_rounded,

              label: 'AGORA',

              selected:
                  activeMode ==
                  MatchDiscoveryMode.global,

              disabled: disabled,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISCOVERY MODE BUTTON
  // ============================================================

  Widget _buildDiscoveryModeButton({
    required MatchDiscoveryMode mode,
    required IconData icon,
    required String label,
    required bool selected,
    required bool disabled,
  }) {
    final accentColor = _matchController.accentNeon;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: disabled
            ? null
            : () {
                if (mode.requiresLocationConsent) {
                  unawaited(
                    _confirmNearbyDiscovery(),
                  );

                  return;
                }

                unawaited(
                  _changeDiscoveryMode(
                    mode,
                  ),
                );
              },

        borderRadius: BorderRadius.circular(
          10,
        ),

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),

          curve: Curves.easeOut,

          height: 42,

          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),

          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(
                    alpha: 0.16,
                  )
                : Colors.transparent,

            borderRadius: BorderRadius.circular(
              10,
            ),

            border: Border.all(
              color: selected
                  ? accentColor.withValues(
                      alpha: 0.36,
                    )
                  : Colors.transparent,
            ),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              if (disabled &&
                  selected)
                SizedBox(
                  width: 14,

                  height: 14,

                  child: CircularProgressIndicator(
                    strokeWidth: 1.7,

                    color: accentColor,
                  ),
                )
              else
                Icon(
                  icon,

                  size: 16,

                  color: selected
                      ? accentColor
                      : Colors.white38,
                ),

              const SizedBox(
                width: 7,
              ),

              Flexible(
                child: Text(
                  label,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: selected
                        ? accentColor
                        : Colors.white38,

                    fontSize: 9,

                    fontWeight: FontWeight.bold,

                    letterSpacing: 0.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISCOVERY HEADER
  // ============================================================

  Widget _buildDiscoveryHeader() {
    final publicProfile = _publicProfileController.profile;

    final hasPublicProfile =
        publicProfile !=
        null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Expanded(
          child: Text(
            _isTeamExpansionMode
                ? 'Procurar membro'
                : 'Novas Conexões',

            style: const TextStyle(
              color: Colors.white,

              fontSize: 26,

              fontWeight: FontWeight.w800,

              letterSpacing: -0.45,
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ======================================================
        // AÇÕES DO CANTO SUPERIOR
        // ======================================================
        Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            // ==================================================
            // PESQUISAR
            // ==================================================
            Tooltip(
              message: _isSearchPanelOpen
                  ? 'Fechar pesquisa'
                  : 'Pesquisar usuário',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleSearchPanel,
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 160,
                    ),
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
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
                                alpha: 0.06,
                              ),
                      ),
                    ),
                    child: Icon(
                      _isSearchPanelOpen
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      size: 21,
                      color: _isSearchPanelOpen
                          ? _matchController.accentNeon
                          : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 6,
            ),

            // ==================================================
            // PERFIL PÚBLICO
            // ==================================================
            Tooltip(
              message: 'Meu perfil público',

              child: Material(
                color: Colors.transparent,

                child: InkWell(
                  onTap: _openPublicProfile,

                  borderRadius: BorderRadius.circular(
                    14,
                  ),

                  child: Container(
                    width: 42,

                    height: 42,

                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: hasPublicProfile
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
                        color: hasPublicProfile
                            ? _matchController.accentNeon.withValues(
                                alpha: 0.30,
                              )
                            : Colors.white.withValues(
                                alpha: 0.06,
                              ),
                      ),
                    ),

                    child: Icon(
                      Icons.account_circle_outlined,

                      size: 22,

                      color: hasPublicProfile
                          ? _matchController.accentNeon
                          : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 6,
            ),

            // ==================================================
            // MEUS PROJETOS
            // ==================================================
            Tooltip(
              message: 'Meus projetos',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openMatchProjects,
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.035,
                      ),
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: 0.06,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.folder_open_outlined,
                      size: 21,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 6,
            ),

            // ==================================================
            // FILTROS
            // ==================================================
            Stack(
              clipBehavior: Clip.none,

              children: [
                Material(
                  color: Colors.transparent,

                  child: InkWell(
                    onTap: _openFilters,

                    borderRadius: BorderRadius.circular(
                      14,
                    ),

                    child: Container(
                      width: 42,

                      height: 42,

                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: _filterState.hasActiveFilters
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
                          color: _filterState.hasActiveFilters
                              ? _matchController.accentNeon.withValues(
                                  alpha: 0.30,
                                )
                              : Colors.white.withValues(
                                  alpha: 0.06,
                                ),
                        ),
                      ),

                      child: Icon(
                        Icons.tune,

                        size: 20,

                        color: _filterState.hasActiveFilters
                            ? _matchController.accentNeon
                            : Colors.white54,
                      ),
                    ),
                  ),
                ),

                if (_filterState.hasActiveFilters)
                  Positioned(
                    top: -3,

                    right: -3,

                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 17,

                        minHeight: 17,
                      ),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),

                      decoration: BoxDecoration(
                        color: _matchController.accentNeon,

                        borderRadius: BorderRadius.circular(
                          20,
                        ),

                        border: Border.all(
                          color: const Color(
                            0xFF0D0B1F,
                          ),

                          width: 2,
                        ),
                      ),

                      alignment: Alignment.center,

                      child: Text(
                        '${_filterState.activeFilterCount}',

                        style: const TextStyle(
                          color: Colors.black,

                          fontSize: 8,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _matchController.removeListener(
      _handleStateChange,
    );

    _professionalProfileController.removeListener(
      _handleStateChange,
    );

    _matchSearchController.removeListener(
      _handleStateChange,
    );

    _publicProfileController.removeListener(
      _handleStateChange,
    );

    _availabilityController.removeListener(
      _handleStateChange,
    );

    _teamExpansionController.removeListener(
      _handleStateChange,
    );

    _demoController.removeListener(
      _handleStateChange,
    );

    _usernameDebounce?.cancel();

    _usernameDebounce = null;

    _usernameController.dispose();

    _usernameFocusNode.dispose();

    _searchTextController.dispose();

    _searchFocusNode.dispose();

    _matchSearchController.dispose();

    _publicProfileController.dispose();

    _availabilityController.dispose();

    _teamExpansionController.dispose();

    _demoController.dispose();

    unawaited(
      _matchSubscription?.cancel(),
    );

    _matchSubscription = null;

    unawaited(
      _sessionService.dispose(),
    );

    _matchController.dispose();

    super.dispose();
  }
}
