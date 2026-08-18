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
import 'package:versin/modules/match/controllers/match_search_controller.dart';
import 'package:versin/modules/match/data/repositories/match_repository.dart';
import 'package:versin/modules/match/models/match_discovery_mode.dart';
import 'package:versin/modules/match/models/match_filter_state.dart';
import 'package:versin/modules/match/services/match_session_service.dart';

// ============================================================
// MATCH WIDGETS
// ============================================================

import 'package:versin/modules/match/widgets/connection_profile_card_widget.dart';
import 'package:versin/modules/match/widgets/discovery_section_widget.dart';
import 'package:versin/modules/match/widgets/match_filter_sheet.dart';
import 'package:versin/modules/match/widgets/match_search_panel_widget.dart';
import 'package:versin/modules/match/widgets/match_search_results_widget.dart';
import 'package:versin/modules/match/widgets/profile_track_player_sheet.dart';

// ============================================================
// NETWORKING
// ============================================================

import 'package:versin/modules/networking/views/networking_session_view.dart';

// ============================================================
// PROFESSIONAL PROFILE
// ============================================================

import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';
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

class MatchPage extends StatefulWidget {
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

  const MatchPage({super.key, this.targetProjectId, this.targetProjectTitle});

  bool get isTeamExpansionMode {
    final projectId = targetProjectId?.trim();

    return projectId != null && projectId.isNotEmpty;
  }

  @override
  State<MatchPage> createState() => _MatchPageState();
}

// ============================================================
// STATE
// ============================================================

class _MatchPageState extends State<MatchPage> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final MatchController _matchController;

  late final MatchSearchController _matchSearchController;

  late final ProfessionalProfileController _professionalProfileController;

  late final PublicProfileController _publicProfileController;

  // ============================================================
  // SERVICES
  // ============================================================

  late final MatchRepository _matchRepository;

  late final MatchSessionService _sessionService;

  late final MatchLocationConsentService _locationConsentService;

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController _searchTextController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearchPanelOpen = false;

  // ============================================================
  // CONFIRMAR MODO POR PROXIMIDADE
  // ============================================================

  Future<void> _confirmNearbyDiscovery() async {
    if (!mounted || _isInitializingMatch || _sessionService.isRestarting) {
      return;
    }

    // ==========================================================
    // VERIFICAR SE JÁ EXISTE CONSENTIMENTO
    // ==========================================================

    try {
      final alreadyAccepted = await _locationConsentService
          .hasAcceptedNearbyLocation();

      if (!mounted) {
        return;
      }

      if (alreadyAccepted) {
        debugPrint(
          '[MATCH PAGE] '
          'Consentimento de localização já registrado.',
        );

        await _changeDiscoveryMode(MatchDiscoveryMode.nearby);

        return;
      }
    } catch (error, stackTrace) {
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

      ScaffoldMessenger.of(context)
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

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,

      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF17132D),

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

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,

                    child: TextButton.icon(
                      onPressed: () async {
                        await Navigator.of(dialogContext).push(
                          MaterialPageRoute(
                            builder: (_) {
                              return const LocationPrivacyPage();
                            },
                          ),
                        );
                      },

                      icon: const Icon(Icons.open_in_new_rounded, size: 15),

                      label: const Text('Como usamos sua localização'),
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

                    onChanged: (value) {
                      setDialogState(() {
                        accepted = value ?? false;
                      });
                    },
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },

                  child: const Text('CANCELAR'),
                ),

                FilledButton(
                  onPressed: accepted
                      ? () {
                          Navigator.of(dialogContext).pop(true);
                        }
                      : null,

                  child: const Text('CONTINUAR'),
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

    if (!mounted || confirmed != true) {
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
    } catch (error, stackTrace) {
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

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar sua confirmação.'),
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

    await _changeDiscoveryMode(MatchDiscoveryMode.nearby);
  }

  // ============================================================
  // FILTER
  // ============================================================

  MatchFilterState _filterState = const MatchFilterState.initial();

  // ============================================================
  // STATE
  // ============================================================

  bool _isInitializingMatch = true;

  bool _isLoadingDemo = false;

  bool _isCreatingProjectInvitation = false;

  // ============================================================
  // STREAM
  // ============================================================

  StreamSubscription<String>? _matchSubscription;

  // ============================================================
  // PAGE MODE
  // ============================================================

  bool get _isTeamExpansionMode => widget.isTeamExpansionMode;

  String? get _targetProjectId {
    final value = widget.targetProjectId?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  String get _targetProjectTitle {
    final value = widget.targetProjectTitle?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'Studio Session';
  }

  // ============================================================
  // AUTH
  // ============================================================

  String? get _authenticatedUserId {
    final id = Supabase.instance.client.auth.currentUser?.id.trim();

    if (id == null || id.isEmpty) {
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

    unawaited(_initializeMatch());
  }

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  void _setupDependencies() {
    _matchController = sl<MatchController>();

    _professionalProfileController = sl<ProfessionalProfileController>();

    _matchRepository = sl<MatchRepository>();

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
    _publicProfileController = PublicProfileController(
      repository: PublicProfileRepositoryImpl(),
      trackService: ProfileTrackService(),
    );
  }

  // ============================================================
  // LISTENERS
  // ============================================================

  void _setupListeners() {
    _matchController.addListener(_handleStateChange);

    _professionalProfileController.addListener(_handleStateChange);

    _matchSearchController.addListener(_handleStateChange);

    _publicProfileController.addListener(_handleStateChange);

    _matchSubscription = _matchController.matchEventStream.listen(
      _handleMatchEvent,
      onError: (error) {
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

    setState(() {});
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeMatch() async {
    if (mounted) {
      setState(() {
        _isInitializingMatch = true;
      });
    }

    try {
      await _sessionService.initialize();

      await _loadPublicProfile();
    } catch (error) {
      debugPrint(
        '[MATCH PAGE] '
        'Erro ao inicializar: '
        '$error',
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializingMatch = false;
      });
    }
  }

  // ============================================================
  // LOAD PUBLIC PROFILE
  // ============================================================

  Future<void> _loadPublicProfile() async {
    final userId = _authenticatedUserId;

    if (userId == null) {
      debugPrint(
        '[PUBLIC PROFILE] '
        'Usuário não autenticado.',
      );

      return;
    }

    await _publicProfileController.load(userId: userId);

    final profile = _publicProfileController.profile;

    if (profile == null) {
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
  // OPEN PUBLIC PROFILE
  // ============================================================

  Future<void> _openPublicProfile() async {
    final userId = _authenticatedUserId;

    if (userId == null || !mounted) {
      return;
    }

    if (_publicProfileController.loadedUserId != userId) {
      await _publicProfileController.load(userId: userId);
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return PublicProfilePage(
            userId: userId,
            controller: _publicProfileController,
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

  Future<void> _openUserDemo(String userId) async {
    final normalizedUserId = userId.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (normalizedUserId.isEmpty || !mounted) {
      return;
    }

    // ==========================================================
    // PREVENT DUPLICATE REQUEST
    // ==========================================================

    if (_isLoadingDemo) {
      debugPrint(
        '[MATCH DEMO] '
        'Solicitação ignorada: '
        'demo já está carregando.',
      );

      return;
    }

    // ==========================================================
    // DISPLAY NAME
    // ==========================================================

    final discoveryUser = _matchController.discoveryUser;

    final displayName =
        discoveryUser != null && discoveryUser.id == normalizedUserId
        ? discoveryUser.name
        : 'Profissional';

    // ==========================================================
    // LOADING
    // ==========================================================

    setState(() {
      _isLoadingDemo = true;
    });

    try {
      debugPrint(
        '[MATCH DEMO] '
        'Buscando demo de: '
        '$normalizedUserId',
      );

      // ========================================================
      // TRACK + PLAYBACK URL
      // ========================================================
      //
      // IMPORTANTE:
      //
      // Não chamar:
      //
      // getFirstTrack()
      // +
      // getPlaybackUrl()
      //
      // separadamente aqui.
      //
      // Este método já retorna os dois de uma vez e deve gerar
      // somente UMA URL temporária.
      //
      // ========================================================

      final playback = await _publicProfileController
          .getFirstTrackPlaybackForUser(userId: normalizedUserId);

      if (!mounted) {
        return;
      }

      // ========================================================
      // NO TRACK
      // ========================================================

      if (playback == null) {
        debugPrint(
          '[MATCH DEMO] '
          'Usuário sem demo.',
        );

        await ProfileTrackPlayerSheet.show(
          context: context,
          track: null,
          playbackUrl: null,
          displayName: displayName,
          accentColor: _matchController.accentNeon,
        );

        return;
      }

      // ========================================================
      // TRACK FOUND
      // ========================================================

      debugPrint(
        '[MATCH DEMO] '
        'Track encontrada: '
        '${playback.track.title}',
      );

      // ========================================================
      // URL
      // ========================================================

      if (!playback.hasUrl) {
        debugPrint(
          '[MATCH DEMO] '
          'Playback URL indisponível.',
        );
      } else {
        debugPrint(
          '[MATCH DEMO] '
          'Playback URL disponível.',
        );
      }

      // ========================================================
      // PLAYER
      // ========================================================

      await ProfileTrackPlayerSheet.show(
        context: context,
        track: playback.track,
        playbackUrl: playback.url,
        displayName: displayName,
        accentColor: _matchController.accentNeon,
      );
    } catch (error, stackTrace) {
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

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar a demo.')),
        );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingDemo = false;
      });
    }
  }

  // ============================================================
  // INVITE USER TO PROJECT
  // ============================================================

  Future<bool> _inviteUserToProject(String userId) async {
    if (!mounted || !_isTeamExpansionMode || _isCreatingProjectInvitation) {
      return false;
    }

    final projectId = _targetProjectId;

    final currentUserId = _authenticatedUserId;

    final normalizedUserId = userId.trim();

    if (projectId == null ||
        projectId.isEmpty ||
        currentUserId == null ||
        currentUserId.isEmpty ||
        normalizedUserId.isEmpty) {
      return false;
    }

    if (normalizedUserId == currentUserId) {
      return false;
    }

    setState(() {
      _isCreatingProjectInvitation = true;
    });

    try {
      // ========================================================
      // VALIDAR PROJETO
      // ========================================================

      final project = await Supabase.instance.client
          .from('projects')
          .select('id, title, members, founders, status')
          .eq('id', projectId)
          .maybeSingle();

      if (project == null) {
        _showInvitationMessage('Equipe não encontrada.', isError: true);

        return false;
      }

      // ========================================================
      // VALIDAR FUNDADOR
      // ========================================================

      final foundersRaw = project['founders'];

      final founders = foundersRaw is Iterable
          ? foundersRaw
                .map((value) => value.toString().trim())
                .where((value) => value.isNotEmpty)
                .toSet()
          : <String>{};

      if (!founders.contains(currentUserId)) {
        _showInvitationMessage(
          'Somente fundadores podem convidar novos membros.',
          isError: true,
        );

        return false;
      }

      // ========================================================
      // JÁ É MEMBRO
      // ========================================================

      final membersRaw = project['members'];

      final members = membersRaw is Iterable
          ? membersRaw
                .map((value) => value.toString().trim())
                .where((value) => value.isNotEmpty)
                .toSet()
          : <String>{};

      if (members.contains(normalizedUserId)) {
        _showInvitationMessage(
          'Este usuário já faz parte da equipe.',
          isError: true,
        );

        return false;
      }

      // ========================================================
      // CONVITE PENDENTE EXISTENTE
      // ========================================================

      final existingInvitation = await Supabase.instance.client
          .from('project_invitations')
          .select('id, status')
          .eq('project_id', projectId)
          .eq('invited_user_id', normalizedUserId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existingInvitation != null) {
        _showInvitationMessage(
          'Este usuário já possui um convite pendente.',
          isError: true,
        );

        return false;
      }

      // ========================================================
      // CRIAR CONVITE
      // ========================================================

      await Supabase.instance.client.from('project_invitations').insert({
        'project_id': projectId,
        'invited_by': currentUserId,
        'invited_user_id': normalizedUserId,
        'status': 'pending',
      });

      if (!mounted) {
        return true;
      }

      final discoveryUser = _matchController.discoveryUser;

      final displayName =
          discoveryUser != null && discoveryUser.id.trim() == normalizedUserId
          ? discoveryUser.name.trim()
          : '';

      final resolvedName = displayName.isNotEmpty
          ? displayName
          : 'Profissional';

      _showInvitationMessage('Convite enviado para $resolvedName.');

      debugPrint(
        '[MATCH PAGE] '
        'Convite criado. '
        'Projeto: $projectId | '
        'Convidado: $normalizedUserId | '
        'Convidado por: $currentUserId',
      );

      return true;
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[MATCH PAGE] '
        'Erro Supabase ao criar convite: '
        '${error.message}',
      );

      debugPrint(
        '[MATCH PAGE] '
        'Código: '
        '${error.code}',
      );

      debugPrint('$stackTrace');

      if (mounted) {
        _showInvitationMessage(
          'Não foi possível enviar o convite.',
          isError: true,
        );
      }

      return false;
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH PAGE] '
        'Erro ao criar convite: '
        '$error',
      );

      debugPrint('$stackTrace');

      if (mounted) {
        _showInvitationMessage(
          'Não foi possível enviar o convite.',
          isError: true,
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingProjectInvitation = false;
        });
      }
    }
  }

  // ============================================================
  // INVITATION MESSAGE
  // ============================================================

  void _showInvitationMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),

          backgroundColor: isError
              ? Colors.red.shade900
              : const Color(0xFF4C1D95),
        ),
      );
  }

  // ============================================================
  // MATCH EVENT
  // ============================================================

  void _handleMatchEvent(String projectId) {
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
    //
    // Enquanto esta página estiver sendo usada para expandir uma
    // equipe, ela não deve navegar para um projeto criado pelo
    // fluxo normal do Match.
    //
    // A próxima etapa vai substituir o LIKE por CONVIDAR neste
    // modo, evitando que esse evento seja gerado.
    //
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

    debugPrint(
      '[MATCH PAGE] '
      'Match recebido. '
      'Projeto: '
      '$normalizedProjectId',
    );

    _openNetworkingSession(normalizedProjectId);
  }

  // ============================================================
  // NETWORKING
  // ============================================================

  void _openNetworkingSession(String projectId) {
    final normalizedProjectId = projectId.trim();

    if (normalizedProjectId.isEmpty || !mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return NetworkingSessionView(projectId: normalizedProjectId);
        },
      ),
    );
  }

  // ============================================================
  // SEARCH TOGGLE
  // ============================================================

  void _toggleSearchPanel() {
    setState(() {
      _isSearchPanelOpen = !_isSearchPanelOpen;
    });

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
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || !_isSearchPanelOpen) {
        return;
      }

      _searchFocusNode.requestFocus();
    });
  }

  // ============================================================
  // SEARCH CHANGED
  // ============================================================

  void _handleSearchChanged(String value) {
    _matchSearchController.onQueryChanged(value);
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
  // DISCOVERY MODE
  // ============================================================

  Future<void> _changeDiscoveryMode(MatchDiscoveryMode mode) async {
    if (!mounted || _isInitializingMatch || _sessionService.isRestarting) {
      return;
    }

    if (_matchController.discoveryMode == mode) {
      return;
    }

    setState(() {
      _isInitializingMatch = true;
    });

    try {
      await _sessionService.changeDiscoveryMode(mode);
    } catch (error, stackTrace) {
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

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível alterar o modo de descoberta.'),
          ),
        );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializingMatch = false;
      });
    }
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Future<void> _openFilters() async {
    final result = await MatchFilterSheet.show(
      context: context,
      initialState: _filterState,
      accentColor: _matchController.accentNeon,
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _filterState = result;
    });
  }

  // ============================================================
  // PROFESSIONAL PROFILE
  // ============================================================

  Future<void> _openProfessionalProfileSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return const ProfessionalProfileSettingsPage();
        },
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isInitializingMatch = true;
    });

    try {
      await _sessionService.refreshProfileAndRestart();

      await _loadPublicProfile();
    } catch (error) {
      debugPrint(
        '[MATCH PAGE] '
        'Erro ao atualizar perfil: '
        '$error',
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializingMatch = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final searchState = _matchSearchController.state;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1F),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 2),

            // ==================================================
            // TEAM EXPANSION CONTEXT
            // ==================================================
            if (_isTeamExpansionMode) ...[
              _buildTeamExpansionNotice(),

              const SizedBox(height: 12),
            ],

            // ==================================================
            // SEARCH
            // ==================================================
            AnimatedSize(
              duration: const Duration(milliseconds: 180),

              curve: Curves.easeOut,

              child: _isSearchPanelOpen
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),

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
            if (_isSearchPanelOpen && searchState.isActive) ...[
              const SizedBox(height: 16),

              MatchSearchResultsWidget(
                controller: _matchController,

                isSearching: searchState.isSearching,

                query: searchState.query,

                errorMessage: searchState.errorMessage,

                results: searchState.results,
              ),
            ],

            const SizedBox(height: 12),

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

            const SizedBox(height: 10),

            // ==================================================
            // PROFESSIONAL PROFILE
            // ==================================================
            ConnectionProfileCardWidget(
              matchController: _matchController,

              profileController: _professionalProfileController,

              isInitializingMatch: _isInitializingMatch,

              onEditProfile: _openProfessionalProfileSettings,
            ),

            const SizedBox(height: 10),

            // ==================================================
            // DISCOVERY MODE
            // ==================================================
            _buildDiscoveryModeSelector(),

            const SizedBox(height: 14),

            // ==================================================
            // DISCOVERY
            // ==================================================
            Stack(
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
                  duration: const Duration(milliseconds: 220),

                  switchInCurve: Curves.easeOut,

                  switchOutCurve: Curves.easeIn,

                  child: DiscoverySectionWidget(
                    key: ValueKey<String>(
                      _matchController.discoveryUser?.id ?? 'discovery-empty',
                    ),

                    controller: _matchController,

                    isInitializingMatch:
                        _isInitializingMatch || _isCreatingProjectInvitation,

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
                if (_isLoadingDemo)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.30),

                          borderRadius: BorderRadius.circular(24),
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

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TEAM EXPANSION NOTICE
  // ============================================================

  Widget _buildTeamExpansionNotice() {
    final projectId = _targetProjectId;

    if (projectId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

      decoration: BoxDecoration(
        color: const Color(0xFF6D28D9).withValues(alpha: 0.10),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFA78BFA).withValues(alpha: 0.24),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 38,

            height: 38,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.14),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.group_add_rounded,

              color: Color(0xFFA78BFA),

              size: 19,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Expandindo $_targetProjectTitle',

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 12,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Os profissionais escolhidos aqui receberão um convite. '
                  'Eles só entrarão na equipe depois de aceitar.',

                  style: TextStyle(
                    color: Colors.white54,

                    fontSize: 10,

                    height: 1.4,
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
  // DISCOVERY MODE SELECTOR
  // ============================================================

  Widget _buildDiscoveryModeSelector() {
    final activeMode = _matchController.discoveryMode;

    final disabled = _isInitializingMatch || _sessionService.isRestarting;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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

              selected: activeMode == MatchDiscoveryMode.compatible,

              disabled: disabled,
            ),
          ),

          const SizedBox(width: 6),

          // ========================================================
          // PROXIMIDADE
          // ========================================================
          Expanded(
            child: _buildDiscoveryModeButton(
              mode: MatchDiscoveryMode.nearby,

              icon: Icons.near_me_rounded,

              label: 'PRÓXIMOS',

              selected: activeMode == MatchDiscoveryMode.nearby,

              disabled: disabled,
            ),
          ),

          const SizedBox(width: 6),

          // ========================================================
          // GLOBAL
          // ========================================================
          Expanded(
            child: _buildDiscoveryModeButton(
              mode: MatchDiscoveryMode.global,

              icon: Icons.public_rounded,

              label: 'GLOBAL',

              selected: activeMode == MatchDiscoveryMode.global,

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
                  unawaited(_confirmNearbyDiscovery());

                  return;
                }

                unawaited(_changeDiscoveryMode(mode));
              },

        borderRadius: BorderRadius.circular(10),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),

          curve: Curves.easeOut,

          height: 42,

          padding: const EdgeInsets.symmetric(horizontal: 12),

          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(alpha: 0.16)
                : Colors.transparent,

            borderRadius: BorderRadius.circular(10),

            border: Border.all(
              color: selected
                  ? accentColor.withValues(alpha: 0.36)
                  : Colors.transparent,
            ),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              if (disabled && selected)
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

                  color: selected ? accentColor : Colors.white38,
                ),

              const SizedBox(width: 7),

              Flexible(
                child: Text(
                  label,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: selected ? accentColor : Colors.white38,

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

    final hasPublicProfile = publicProfile != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Expanded(
          child: Text(
            _isTeamExpansionMode ? 'Procurar membro' : 'Novas Conexões',

            style: const TextStyle(
              color: Colors.white,

              fontSize: 26,

              fontWeight: FontWeight.w800,

              letterSpacing: -0.45,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // ======================================================
        // AÇÕES DO CANTO SUPERIOR
        // ======================================================
        Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            // ==================================================
            // PERFIL PÚBLICO
            // ==================================================
            Tooltip(
              message: 'Meu perfil público',

              child: Material(
                color: Colors.transparent,

                child: InkWell(
                  onTap: _openPublicProfile,

                  borderRadius: BorderRadius.circular(14),

                  child: Container(
                    width: 42,

                    height: 42,

                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: hasPublicProfile
                          ? _matchController.accentNeon.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.035),

                      borderRadius: BorderRadius.circular(14),

                      border: Border.all(
                        color: hasPublicProfile
                            ? _matchController.accentNeon.withValues(
                                alpha: 0.30,
                              )
                            : Colors.white.withValues(alpha: 0.06),
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

            const SizedBox(width: 6),

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

                    borderRadius: BorderRadius.circular(14),

                    child: Container(
                      width: 42,

                      height: 42,

                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: _filterState.hasActiveFilters
                            ? _matchController.accentNeon.withValues(
                                alpha: 0.10,
                              )
                            : Colors.white.withValues(alpha: 0.035),

                        borderRadius: BorderRadius.circular(14),

                        border: Border.all(
                          color: _filterState.hasActiveFilters
                              ? _matchController.accentNeon.withValues(
                                  alpha: 0.30,
                                )
                              : Colors.white.withValues(alpha: 0.06),
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

                      padding: const EdgeInsets.symmetric(horizontal: 4),

                      decoration: BoxDecoration(
                        color: _matchController.accentNeon,

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(
                          color: const Color(0xFF0D0B1F),

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
    _matchController.removeListener(_handleStateChange);

    _professionalProfileController.removeListener(_handleStateChange);

    _matchSearchController.removeListener(_handleStateChange);

    _publicProfileController.removeListener(_handleStateChange);

    _searchTextController.dispose();

    _searchFocusNode.dispose();

    _matchSearchController.dispose();

    _publicProfileController.dispose();

    unawaited(_matchSubscription?.cancel());

    _matchSubscription = null;

    unawaited(_sessionService.dispose());

    _matchController.dispose();

    super.dispose();
  }
}
