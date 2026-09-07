import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/app/locator.dart';

import 'package:versin/modules/match/availability/controllers/match_availability_controller.dart';
import 'package:versin/modules/match/availability/services/match_availability_service.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';
import 'package:versin/modules/match/data/repositories/match_repository.dart';

import 'package:versin/modules/match/demo/controllers/match_demo_controller.dart';
import 'package:versin/modules/match/demo/widgets/profile_track_player_sheet.dart';

import 'package:versin/modules/match/discovery/controllers/match_discovery_controller.dart';
import 'package:versin/modules/match/discovery/widgets/match_discovery_info_sheet.dart';

import 'package:versin/modules/match/filters/widgets/match_filter_sheet.dart';

import 'package:versin/modules/match/location/service/match_location_consent_service.dart';

import 'package:versin/modules/match/models/match_discovery_mode.dart';
import 'package:versin/modules/match/models/match_filter_state.dart';

import 'package:versin/modules/match/availability/flows/match_availability_flow.dart';
import 'package:versin/modules/match/location/flows/match_nearby_consent_flow.dart';

import 'package:versin/modules/match/search/controllers/match_search_controller.dart';

import 'package:versin/modules/match/services/match_session_service.dart';

import 'package:versin/modules/match/team_expansion/controllers/match_team_expansion_controller.dart';
import 'package:versin/modules/match/team_expansion/services/match_team_invitation_service.dart';

import 'package:versin/modules/match/views/projects/match_projects_view.dart';
import 'package:versin/modules/match/page/services/match_confirmation_service.dart';

import 'package:versin/modules/onboarding/controllers/match_onboarding_controller.dart';

import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';
import 'package:versin/modules/profile/public_profile/controllers/public_profile_controller.dart';
import 'package:versin/modules/profile/public_profile/data/repositories/public_profile_repository_impl.dart';
import 'package:versin/modules/profile/public_profile/services/profile_track_service.dart';
import 'package:versin/modules/profile/public_profile/views/public_profile_page.dart';
import 'package:versin/modules/profile/services/presence/user_presence_service.dart';
import 'package:versin/modules/profile/views/professional_profile_settings_page.dart';

// ============================================================
// MATCH PAGE COORDINATOR
// ============================================================
//
// Responsável por orquestrar a feature da página.
//
// Ele conhece:
//
// - controllers;
// - services;
// - sessão;
// - fluxos;
// - navegação de feature;
// - lifecycle de objetos criados pela página.
//
// A View conhece somente:
// - estado exposto;
// - callbacks.
//
// ============================================================

class MatchPageCoordinator extends ChangeNotifier {
  final String? targetProjectId;
  final String? targetProjectTitle;

  MatchPageCoordinator({this.targetProjectId, this.targetProjectTitle}) {
    _setupDependencies();
    _setupListeners();
  }

  // ============================================================
  // OWNED / RESOLVED DEPENDENCIES
  // ============================================================

  late final MatchController matchController;
  late final MatchSearchController matchSearchController;
  late final ProfessionalProfileController professionalProfileController;
  late final PublicProfileController publicProfileController;
  late final MatchTeamExpansionController teamExpansionController;
  late final MatchDemoController demoController;
  late final MatchOnboardingController onboardingController;
  late final MatchDiscoveryController discoveryController;
  late final MatchAvailabilityController availabilityController;

  late final MatchRepository _matchRepository;
  late final MatchSessionService _sessionService;
  late final UserPresenceService _presenceService;

  late final MatchNearbyConsentFlow _nearbyConsentFlow;
  late final MatchAvailabilityFlow _availabilityFlow;

  // ============================================================
  // UI STATE
  // ============================================================

  final TextEditingController searchTextController = TextEditingController();

  final FocusNode searchFocusNode = FocusNode();

  bool isSearchPanelOpen = false;
  bool isInitializingMatch = true;

  MatchFilterState filterState = const MatchFilterState.initial();

  StreamSubscription<String>? _matchSubscription;

  final MatchConfirmationService _confirmationService =
      MatchConfirmationService();
  final List<MatchConfirmation> _confirmationQueue = <MatchConfirmation>[];
  final Set<String> _pendingConfirmationIds = <String>{};
  bool _confirmationReady = false;

  bool get hasPendingConfirmation => _confirmationQueue.isNotEmpty;

  MatchConfirmation? takeNextConfirmation() {
    if (_disposed || _confirmationQueue.isEmpty) return null;
    return _confirmationQueue.removeAt(0);
  }

  Future<void> acknowledgeConfirmation(MatchConfirmation confirmation) async {
    await _confirmationService.acknowledge(confirmation.projectId);
    _pendingConfirmationIds.remove(confirmation.projectId);
  }

  bool _disposed = false;
  bool _initialized = false;

  // ============================================================
  // DERIVED STATE
  // ============================================================

  bool get isTeamExpansionMode {
    final projectId = targetProjectId?.trim();

    return projectId != null && projectId.isNotEmpty;
  }

  String? get normalizedTargetProjectId {
    final value = targetProjectId?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  String get resolvedTargetProjectTitle {
    final value = targetProjectTitle?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'Studio Session';
  }

  bool get hasPublicProfile => publicProfileController.profile != null;

  bool get isInteractionUnlocked => matchController.isMatchUnlocked;

  bool get isDiscoveryBusy => discoveryController.isBusy;

  bool get isAvailabilityVisible =>
      matchController.discoveryMode == MatchDiscoveryMode.global ||
      availabilityController.isActive;

  String? get authenticatedUserId {
    final id = Supabase.instance.client.auth.currentUser?.id.trim();

    if (id == null || id.isEmpty) {
      return null;
    }

    return id;
  }

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  void _setupDependencies() {
    matchController = sl<MatchController>();

    professionalProfileController = sl<ProfessionalProfileController>();

    _matchRepository = sl<MatchRepository>();

    _presenceService = sl<UserPresenceService>();

    onboardingController = MatchOnboardingController(
      matchController: matchController,
    );

    matchSearchController = MatchSearchController(
      repository: _matchRepository,
      currentUserIdProvider: () {
        return matchController.currentUserId;
      },
    );

    _sessionService = MatchSessionService(
      matchController: matchController,
      matchRepository: _matchRepository,
      professionalProfileController: professionalProfileController,
    );

    discoveryController = MatchDiscoveryController(
      matchController: matchController,
      sessionService: _sessionService,
    );

    availabilityController = MatchAvailabilityController(
      availabilityService: MatchAvailabilityService(),
    );

    teamExpansionController = MatchTeamExpansionController(
      invitationService: MatchTeamInvitationService(),
      projectId: normalizedTargetProjectId,
      projectTitle: resolvedTargetProjectTitle,
    );

    publicProfileController = PublicProfileController(
      repository: PublicProfileRepositoryImpl(),
      trackService: ProfileTrackService(),
    );

    demoController = MatchDemoController(
      publicProfileController: publicProfileController,
    );

    _nearbyConsentFlow = MatchNearbyConsentFlow(
      consentService: MatchLocationConsentService(),
    );

    _availabilityFlow = MatchAvailabilityFlow(
      availabilityController: availabilityController,
      presenceService: _presenceService,
    );
  }

  // ============================================================
  // LISTENERS
  // ============================================================

  void _setupListeners() {
    matchController.addListener(_relayState);

    professionalProfileController.addListener(_relayState);

    matchSearchController.addListener(_relayState);

    publicProfileController.addListener(_relayState);

    availabilityController.addListener(_relayState);

    teamExpansionController.addListener(_relayState);

    demoController.addListener(_relayState);

    discoveryController.addListener(_relayState);

    _matchSubscription = matchController.matchEventStream.listen(
      _handleMatchEvent,
      onError: (error) {
        debugPrint(
          '[MATCH PAGE COORDINATOR] '
          'Erro no stream: $error',
        );
      },
    );
  }

  void _relayState() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_disposed || _initialized) {
      return;
    }

    _initialized = true;

    onboardingController.initialize();

    _setInitializing(true);

    debugPrint(
      '[MATCH PAGE COORDINATOR] '
      'Modo: '
      '${isTeamExpansionMode ? "expansão de equipe" : "match normal"}'
      '${normalizedTargetProjectId != null ? " | projeto: $normalizedTargetProjectId" : ""}',
    );

    try {
      // Establish the historical baseline before starting match events.
      final confirmationUserId = authenticatedUserId;
      if (!isTeamExpansionMode && confirmationUserId != null) {
        try {
          await _confirmationService.initialize(confirmationUserId);
          _confirmationReady = true;
        } catch (error) {
          // A notification failure must never prevent discovery.
          debugPrint('[MATCH CONFIRMATION] Inicialização: $error');
        }
      }

      await _sessionService.initialize();

      if (_disposed) {
        return;
      }

      onboardingController.syncUsername();

      await _loadPublicProfile();

      if (_disposed) {
        return;
      }

      await availabilityController.initialize();
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH PAGE COORDINATOR] '
        'Erro ao inicializar: $error',
      );

      debugPrint(
        '[MATCH PAGE COORDINATOR] '
        'Stack trace: $stackTrace',
      );
    } finally {
      _setInitializing(false);
    }
  }

  // ============================================================
  // PUBLIC PROFILE
  // ============================================================

  Future<void> _loadPublicProfile() async {
    final userId = authenticatedUserId;

    if (userId == null) {
      return;
    }

    await publicProfileController.load(userId: userId);
  }

  Future<void> openPublicProfile(
    BuildContext context, {
    bool highlightOnlineOnOpen = false,
  }) async {
    if (!ensureInteractionUnlocked()) {
      return;
    }

    final userId = authenticatedUserId;

    if (userId == null || !context.mounted) {
      return;
    }

    if (publicProfileController.loadedUserId != userId) {
      await publicProfileController.load(userId: userId);
    }

    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return PublicProfilePage(
            userId: userId,
            controller: publicProfileController,
            highlightOnlineOnOpen: highlightOnlineOnOpen,
          );
        },
      ),
    );

    if (_disposed || !context.mounted) {
      return;
    }

    await publicProfileController.refresh();
  }

  // ============================================================
  // PROJECTS
  // ============================================================

  Future<void> openProjects(BuildContext context) async {
    if (!context.mounted || !ensureInteractionUnlocked()) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return const MatchProjectsView();
        },
      ),
    );
  }

  // ============================================================
  // PROFESSIONAL PROFILE
  // ============================================================

  Future<void> openProfessionalProfileSettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return const ProfessionalProfileSettingsPage();
        },
      ),
    );

    if (_disposed || !context.mounted) {
      return;
    }

    _setInitializing(true);

    try {
      await matchController.refreshMatchOnboarding();

      if (_disposed) {
        return;
      }

      if (matchController.isMatchUnlocked) {
        await _sessionService.refreshProfileAndRestart();
      }

      await _loadPublicProfile();
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH PAGE COORDINATOR] '
        'Erro ao atualizar perfil: $error',
      );

      debugPrint(
        '[MATCH PAGE COORDINATOR] '
        'Stack trace: $stackTrace',
      );
    } finally {
      _setInitializing(false);
    }
  }

  // ============================================================
  // DEMO
  // ============================================================

  Future<void> openUserDemo(BuildContext context, String userId) async {
    if (!ensureInteractionUnlocked()) {
      return;
    }

    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty ||
        !context.mounted ||
        demoController.isLoading) {
      return;
    }

    final discoveryUser = matchController.discoveryUser;

    final displayName =
        discoveryUser != null &&
            discoveryUser.id == normalizedUserId &&
            discoveryUser.name.trim().isNotEmpty
        ? discoveryUser.name.trim()
        : 'Profissional';

    try {
      final demo = await demoController.load(userId: normalizedUserId);

      if (_disposed || !context.mounted || demo == null) {
        return;
      }

      await ProfileTrackPlayerSheet.show(
        context: context,
        track: demo.track,
        playbackUrl: demo.playbackUrl,
        displayName: displayName,
        accentColor: matchController.accentNeon,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH DEMO] '
        'Erro ao abrir demo: $error',
      );

      debugPrint(
        '[MATCH DEMO] '
        'Stack trace: $stackTrace',
      );

      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        demoController.errorMessage ?? 'Não foi possível carregar a demo.',
      );
    }
  }

  // ============================================================
  // TEAM EXPANSION
  // ============================================================

  Future<bool> inviteUserToProject(BuildContext context, String userId) async {
    if (!ensureInteractionUnlocked() ||
        !isTeamExpansionMode ||
        !context.mounted) {
      return false;
    }

    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    final discoveryUser = matchController.discoveryUser;

    final displayName =
        discoveryUser != null && discoveryUser.id.trim() == normalizedUserId
        ? discoveryUser.name.trim()
        : '';

    final resolvedName = displayName.isNotEmpty ? displayName : 'Profissional';

    try {
      final result = await teamExpansionController.invite(
        userId: normalizedUserId,
      );

      if (!context.mounted) {
        return result.wasCreated;
      }

      switch (result.status) {
        case MatchTeamInvitationStatus.invited:
          _showInvitationMessage(
            context,
            'Convite enviado para $resolvedName.',
          );

          return true;

        case MatchTeamInvitationStatus.alreadyPending:
          _showInvitationMessage(
            context,
            'Este usuário já possui um convite pendente.',
            isError: true,
          );

          return false;

        case MatchTeamInvitationStatus.alreadyMember:
          _showInvitationMessage(
            context,
            'Este usuário já faz parte da equipe.',
            isError: true,
          );

          return false;
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH TEAM] '
        'Erro ao convidar usuário: $error',
      );

      debugPrint(
        '[MATCH TEAM] '
        '$stackTrace',
      );

      if (!context.mounted) {
        return false;
      }

      final controllerMessage = teamExpansionController.errorMessage?.trim();

      _showInvitationMessage(
        context,
        controllerMessage != null && controllerMessage.isNotEmpty
            ? controllerMessage
            : 'Não foi possível enviar o convite.',
        isError: true,
      );

      return false;
    }
  }

  void _showInvitationMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) {
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
  // SEARCH
  // ============================================================

  void toggleSearchPanel() {
    if (_disposed) {
      return;
    }

    isSearchPanelOpen = !isSearchPanelOpen;

    notifyListeners();

    if (isSearchPanelOpen) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (_disposed || !isSearchPanelOpen) {
          return;
        }

        searchFocusNode.requestFocus();
      });

      return;
    }

    clearSearch();
  }

  void handleSearchChanged(String value) {
    matchSearchController.onQueryChanged(value);
  }

  void clearSearch() {
    searchTextController.clear();
    searchFocusNode.unfocus();
    matchSearchController.clear();
  }

  // ============================================================
  // FILTER
  // ============================================================

  Future<void> openFilters(BuildContext context) async {
    if (!ensureInteractionUnlocked()) {
      return;
    }

    final result = await MatchFilterSheet.show(
      context: context,
      initialState: filterState,
      accentColor: matchController.accentNeon,
    );

    if (_disposed || !context.mounted || result == null) {
      return;
    }

    filterState = result;

    notifyListeners();
  }

  // ============================================================
  // DISCOVERY INFO
  // ============================================================

  void openDiscoveryInfo(BuildContext context) {
    MatchDiscoveryInfoSheet.show(
      context: context,
      accentColor: matchController.accentNeon,
    );
  }

  // ============================================================
  // DISCOVERY MODE
  // ============================================================

  Future<void> handleDiscoveryModeSelected(
    BuildContext context,
    MatchDiscoveryMode mode,
  ) async {
    if (!ensureInteractionUnlocked() ||
        _disposed ||
        isInitializingMatch ||
        discoveryController.isBusy) {
      return;
    }

    if (mode.requiresLocationConsent) {
      final accepted = await _nearbyConsentFlow.ensureConsent(
        context: context,
        accentColor: matchController.accentNeon,
      );

      if (!accepted || _disposed || !context.mounted) {
        return;
      }
    }

    if (mode == MatchDiscoveryMode.global) {
      final canEnter = await _availabilityFlow.ensureAvailable(
        context: context,
        accentColor: matchController.accentNeon,
        openOnlineProfile: () {
          return openPublicProfile(context, highlightOnlineOnOpen: true);
        },
      );

      if (!canEnter || _disposed || !context.mounted) {
        return;
      }
    }

    await _changeDiscoveryMode(context, mode);
  }

  Future<void> _changeDiscoveryMode(
    BuildContext context,
    MatchDiscoveryMode mode,
  ) async {
    if (_disposed ||
        !context.mounted ||
        isInitializingMatch ||
        discoveryController.isBusy) {
      return;
    }

    if (matchController.discoveryMode == mode) {
      return;
    }

    _setInitializing(true);

    try {
      final changed = await discoveryController.changeMode(mode);

      if (_disposed || !context.mounted || changed) {
        return;
      }

      final message = discoveryController.errorMessage?.trim();

      _showMessage(
        context,
        message != null && message.isNotEmpty
            ? message
            : 'Não foi possível alterar o modo de descoberta.',
      );
    } finally {
      _setInitializing(false);
    }
  }

  // ============================================================
  // AVAILABILITY
  // ============================================================

  Future<void> clearAvailability(BuildContext context) async {
    if (_disposed || availabilityController.isLoading) {
      return;
    }

    final cleared = await availabilityController.clear();

    if (_disposed || !context.mounted) {
      return;
    }

    if (!cleared) {
      _showMessage(
        context,
        'Não foi possível encerrar sua disponibilidade.',
        floating: true,
      );

      return;
    }

    if (matchController.discoveryMode == MatchDiscoveryMode.global) {
      await _sessionService.changeDiscoveryMode(MatchDiscoveryMode.compatible);
    }

    if (!context.mounted) {
      return;
    }

    _showMessage(context, 'Disponibilidade encerrada.', floating: true);
  }

  // ============================================================
  // GUARD / EVENTS
  // ============================================================

  bool ensureInteractionUnlocked() {
    return onboardingController.ensureMatchUnlockedForInteraction();
  }

  void refreshUi() {
    _relayState();
  }

  void _handleMatchEvent(String projectId) {
    final id = projectId.trim();
    if (_disposed || isTeamExpansionMode || !_confirmationReady || id.isEmpty) {
      return;
    }
    if (_confirmationService.isSeen(id) || !_pendingConfirmationIds.add(id)) {
      return;
    }
    unawaited(_resolveConfirmation(id));
  }

  Future<void> _resolveConfirmation(String projectId) async {
    try {
      final confirmation = await _confirmationService.resolve(projectId);
      if (_disposed || confirmation == null) {
        _pendingConfirmationIds.remove(projectId);
        return;
      }
      _confirmationQueue.add(confirmation);
      notifyListeners();
    } catch (error) {
      _pendingConfirmationIds.remove(projectId);
      debugPrint('[MATCH CONFIRMATION] Não foi possível carregar: $error');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _setInitializing(bool value) {
    if (_disposed || isInitializingMatch == value) {
      return;
    }

    isInitializingMatch = value;

    notifyListeners();
  }

  void _showMessage(
    BuildContext context,
    String message, {
    bool floating = false,
  }) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: floating ? SnackBarBehavior.floating : null,
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _confirmationQueue.clear();
    _pendingConfirmationIds.clear();

    matchController.removeListener(_relayState);

    professionalProfileController.removeListener(_relayState);

    matchSearchController.removeListener(_relayState);

    publicProfileController.removeListener(_relayState);

    availabilityController.removeListener(_relayState);

    teamExpansionController.removeListener(_relayState);

    demoController.removeListener(_relayState);

    discoveryController.removeListener(_relayState);

    searchTextController.dispose();
    searchFocusNode.dispose();

    matchSearchController.dispose();
    publicProfileController.dispose();
    availabilityController.dispose();
    teamExpansionController.dispose();
    demoController.dispose();
    onboardingController.dispose();
    discoveryController.dispose();

    unawaited(_matchSubscription?.cancel());

    _matchSubscription = null;

    unawaited(_sessionService.dispose());

    // MatchController é factory no locator.
    // Portanto pertence a esta sessão de página.
    matchController.dispose();

    super.dispose();
  }
}
