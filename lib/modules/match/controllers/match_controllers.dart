import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/app/locator.dart';

import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';

import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';
import 'package:versin/modules/profile/models/music_role.dart';
import '../models/match_discovery_mode.dart';
import '../models/match_user_entity.dart';

// ============================================================
// MATCH CONTROLLER
// ============================================================
//
// Controller principal do módulo Match.
//
// Responsabilidades:
//
// - controlar o estado da descoberta;
// - controlar Discovery;
// - controlar recomendações;
// - controlar modo de descoberta;
// - registrar likes;
// - detectar match mútuo;
// - iniciar networking;
// - emitir evento de projeto;
// - controlar countdown da conexão;
// - expor dados do perfil profissional.
//
// IMPORTANTE:
//
// O Controller NÃO:
//
// - desenha widgets;
// - controla BuildContext;
// - navega entre páginas;
// - pesquisa usuários manualmente;
// - calcula ranking de candidatos.
//
// Essas responsabilidades pertencem respectivamente a:
//
// UI
// MatchPage / Widgets
//
// Busca
// MatchSearchController
//
// Ranking / candidatos
// MatchRepository
//
// Sessão
// MatchSessionService
//
// ============================================================

class MatchController with ChangeNotifier {
  // ============================================================
  // CONSTANTES
  // ============================================================

  static const int _connectionDurationSeconds = 1200;

  static const Duration _searchTimeout = Duration(milliseconds: 1500);

  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final DashboardController _dashboardController = sl<DashboardController>();

  final ProfessionalProfileController _professionalProfileController =
      sl<ProfessionalProfileController>();

  // ============================================================
  // SUPABASE
  // ============================================================
  //
  // Por enquanto permanece aqui porque:
  //
  // - favoritos;
  // - match mútuo;
  // - criação de projeto;
  //
  // ainda fazem parte do Controller atual.
  //
  // Em uma próxima refatoração isso poderá ser movido para
  // MatchRemoteDatasource sem alterar a UI.
  //
  // ============================================================

  SupabaseClient get _supabase => Supabase.instance.client;

  // ============================================================
  // STREAM DE EVENTO DE MATCH
  // ============================================================

  final StreamController<String> _matchEventController =
      StreamController<String>.broadcast();

  // ============================================================
  // TIMERS
  // ============================================================

  Timer? _countdownTimer;

  Timer? _searchTimeoutTimer;

  // ============================================================
  // REALTIME
  // ============================================================

  StreamSubscription<dynamic>? _matchSubscription;

  // ============================================================
  // PROTEÇÃO DE CONCORRÊNCIA
  // ============================================================
  //
  // O mesmo par pode ser verificado ao mesmo tempo por:
  //
  // - registerLike();
  // - listener Realtime;
  // - rebuilds / ações repetidas da UI.
  //
  // Sem essa proteção, o Web pode disparar verificações
  // duplicadas e até emitir o mesmo projeto várias vezes.
  //
  // ============================================================

  final Set<String> _networkingChecksInProgress = <String>{};

  final Set<String> _emittedProjectIds = <String>{};

  // ============================================================
  // ESTADO INTERNO
  // ============================================================

  bool _isLoading = true;

  MatchDiscoveryMode _discoveryMode = MatchDiscoveryMode.compatible;

  MatchUserEntity? _discoveryUser;

  List<MatchUserEntity> _recommendedUsers = const <MatchUserEntity>[];

  final Set<String> _discoveryVisitedUserIds = <String>{};

  // ============================================================
  // PERFIS JÁ DECIDIDOS
  // ============================================================
  //
  // Contém usuários que já receberam:
  //
  // - LIKE;
  // - X / PASS.
  //
  // Estes IDs são carregados do Supabase no início da sessão e
  // também atualizados imediatamente em memória após cada ação.
  //
  // ============================================================

  final Set<String> _discoveryDecidedUserIds = <String>{};

  // ============================================================
  // ONBOARDING DO MATCH
  // ============================================================
  //
  // O estado é derivado do perfil real do usuário autenticado.
  //
  // Não usamos SharedPreferences para decidir se o usuário já
  // concluiu esta etapa.
  //
  // Fonte da verdade:
  //
  // public.profiles.id = auth.uid()
  // public.profiles.username
  // professional profile / primary_role
  //
  // ============================================================

  String _currentUsername = '';

  bool _isLoadingMatchProfile = false;

  bool _isCheckingUsername = false;

  bool _isSavingUsername = false;

  bool? _usernameAvailable;

  String? _usernameValidationMessage;

  int _usernameCheckRevision = 0;

  int _professionalProfileAttentionRevision = 0;

  int _remainingSeconds = _connectionDurationSeconds;

  bool _disposed = false;

  // ============================================================
  // GETTERS — ESTADO
  // ============================================================

  bool get isLoading => _isLoading;

  MatchDiscoveryMode get discoveryMode => _discoveryMode;

  bool get isCompatibleDiscovery =>
      _discoveryMode == MatchDiscoveryMode.compatible;

  bool get isGlobalDiscovery => _discoveryMode == MatchDiscoveryMode.global;

  MatchUserEntity? get discoveryUser => _discoveryUser;

  List<MatchUserEntity> get recommendedUsers => _recommendedUsers;

  int get remainingSeconds => _remainingSeconds;

  // ============================================================
  // GETTERS — EVENTOS
  // ============================================================

  Stream<String> get matchEventStream => _matchEventController.stream;

  // ============================================================
  // GETTERS — TEMA
  // ============================================================

  Color get accentNeon => _dashboardController.accentNeon;

  Color get primaryPurple => _dashboardController.primaryPurple;

  // ============================================================
  // GETTERS — PERFIL PROFISSIONAL
  // ============================================================

  ProfessionalProfileController get professionalProfileController =>
      _professionalProfileController;

  MusicRole? get currentPrimaryRole =>
      _professionalProfileController.primaryRole;

  Set<MusicRole> get currentRoles =>
      _professionalProfileController.selectedRoles;

  Set<MusicRole> get lookingForRoles =>
      _professionalProfileController.lookingForRoles;

  String get primaryRoleLabel =>
      _professionalProfileController.primaryRoleLabel;

  // ============================================================
  // GETTERS — ONBOARDING DO MATCH
  // ============================================================

  String get currentUsername => _currentUsername;

  bool get isLoadingMatchProfile => _isLoadingMatchProfile;

  bool get isCheckingUsername => _isCheckingUsername;

  bool get isSavingUsername => _isSavingUsername;

  bool? get usernameAvailable => _usernameAvailable;

  String? get usernameValidationMessage => _usernameValidationMessage;

  bool get hasUsername => _currentUsername.trim().isNotEmpty;

  bool get hasPrimaryRole => currentPrimaryRole != null;

  bool get requiresUsername => !hasUsername;

  bool get requiresProfessionalProfile => hasUsername && !hasPrimaryRole;

  bool get isMatchUnlocked => hasUsername && hasPrimaryRole;

  int get professionalProfileAttentionRevision =>
      _professionalProfileAttentionRevision;

  bool get canSubmitUsername {
    return !_isCheckingUsername &&
        !_isSavingUsername &&
        _usernameAvailable == true;
  }

  // ============================================================
  // GETTERS — RESULTADOS
  // ============================================================

  bool get hasDiscoveryUser => _discoveryUser != null;

  bool get hasRecommendations => _recommendedUsers.isNotEmpty;

  List<MatchUserEntity> get visibleRecommendedUsers {
    final currentId = _discoveryUser?.id.trim();

    if (currentId == null || currentId.isEmpty) {
      return _recommendedUsers;
    }

    return _recommendedUsers
        .where((user) => user.id.trim() != currentId)
        .toList(growable: false);
  }

  bool get hasVisibleRecommendations => visibleRecommendedUsers.isNotEmpty;

  bool get isDiscoveryUserOnline => _discoveryUser?.isOnline ?? false;

  bool get hasMatchResults =>
      _discoveryUser != null || _recommendedUsers.isNotEmpty;

  // ============================================================
  // USER ID
  // ============================================================

  String? get currentUserId {
    // ==========================================================
    // USUÁRIO AUTENTICADO
    // ==========================================================
    //
    // O usuário autenticado tem prioridade.
    //
    // Isso evita que DEBUG_USER_ID faça o Match considerar outra
    // conta como sendo a atual e acabe mostrando o próprio perfil.
    //
    // ==========================================================

    final authenticatedUserId = _supabase.auth.currentUser?.id.trim();

    if (authenticatedUserId != null && authenticatedUserId.isNotEmpty) {
      return authenticatedUserId;
    }

    // ==========================================================
    // DEBUG USER
    // ==========================================================
    //
    // Usado somente quando não existe sessão autenticada.
    //
    // ==========================================================

    if (kDebugMode) {
      final debugUserId = dotenv.env['DEBUG_USER_ID']?.trim();

      if (debugUserId != null && debugUserId.isNotEmpty) {
        return debugUserId;
      }
    }

    return null;
  }

  // ============================================================
  // INIT MATCH SESSION
  // ============================================================

  Future<void> initMatchSession() async {
    if (_disposed) {
      return;
    }

    // ==========================================================
    // RESET
    // ==========================================================

    _setLoading(true, notify: false);

    _discoveryUser = null;

    _recommendedUsers = const <MatchUserEntity>[];

    _discoveryVisitedUserIds.clear();

    _discoveryDecidedUserIds.clear();

    _remainingSeconds = _connectionDurationSeconds;

    _networkingChecksInProgress.clear();

    _emittedProjectIds.clear();

    _cancelTimers();

    safeNotify();

    // ==========================================================
    // PERFIL PROFISSIONAL
    // ==========================================================
    //
    // Mantemos load() aqui por compatibilidade com chamadas
    // diretas a MatchController.
    //
    // O ProfessionalProfileController é LazySingleton e pode
    // compartilhar os dados com Dashboard e Match.
    //
    // ==========================================================

    await _professionalProfileController.load();

    if (_disposed) {
      return;
    }

    // ==========================================================
    // PERFIL BÁSICO / USERNAME
    // ==========================================================

    await _loadCurrentUsername();

    if (_disposed) {
      return;
    }

    // ==========================================================
    // ONBOARDING INCOMPLETO
    // ==========================================================
    //
    // O Match pode abrir normalmente, porém ainda não iniciamos
    // discovery/realtime enquanto faltar:
    //
    // - username;
    // - função principal.
    //
    // A UI usa requiresUsername / requiresProfessionalProfile
    // para orientar o usuário.
    //
    // ==========================================================

    if (!isMatchUnlocked) {
      _isLoading = false;

      safeNotify();

      _logSessionStarted();

      return;
    }

    // ==========================================================
    // CARREGAR PERFIS JÁ AVALIADOS
    // ==========================================================

    await _loadPersistedDiscoveryDecisions();

    if (_disposed) {
      return;
    }

    // ==========================================================
    // VALIDAR CONFIGURAÇÃO
    // ==========================================================

    _validateProfessionalProfile();

    // ==========================================================
    // REALTIME DE MATCH MÚTUO
    // ==========================================================

    _startRealtimeMatchListener();

    // ==========================================================
    // TIMEOUT DA BUSCA
    // ==========================================================

    _startSearchTimeout();

    // ==========================================================
    // LOG
    // ==========================================================

    _logSessionStarted();
  }

  // ============================================================
  // CARREGAR USERNAME ATUAL
  // ============================================================

  Future<void> _loadCurrentUsername() async {
    final userId = currentUserId?.trim();

    if (_disposed || userId == null || userId.isEmpty) {
      _currentUsername = '';

      return;
    }

    _isLoadingMatchProfile = true;

    safeNotify();

    try {
      final profile = await _supabase
          .from('profiles')
          .select('id, username')
          .eq('id', userId)
          .maybeSingle();

      if (_disposed) {
        return;
      }

      _currentUsername =
          profile?['username']?.toString().trim().replaceFirst(
            RegExp(r'^@+'),
            '',
          ) ??
          '';

      debugPrint(
        '[MATCH] '
        'Username atual: '
        '${_currentUsername.isEmpty ? "não informado" : "@$_currentUsername"}',
      );
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[MATCH] '
        'Erro Supabase ao carregar username: '
        '${error.message}',
      );

      debugPrint(
        '[MATCH] '
        'Código: ${error.code}',
      );

      debugPrint('$stackTrace');

      _currentUsername = '';
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH] '
        'Erro ao carregar username: '
        '$error',
      );

      debugPrint('$stackTrace');

      _currentUsername = '';
    } finally {
      if (!_disposed) {
        _isLoadingMatchProfile = false;

        safeNotify();
      }
    }
  }

  // ============================================================
  // NORMALIZAR USERNAME
  // ============================================================

  String normalizeUsername(String value) {
    return value.trim().toLowerCase().replaceFirst(RegExp(r'^@+'), '');
  }

  // ============================================================
  // VALIDAR FORMATO DO USERNAME
  // ============================================================

  String? validateUsername(String value) {
    final username = normalizeUsername(value);

    if (username.isEmpty) {
      return 'Informe um username.';
    }

    if (username.length < 3) {
      return 'Use pelo menos 3 caracteres.';
    }

    if (username.length > 24) {
      return 'Use no máximo 24 caracteres.';
    }

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      return 'Use apenas letras, números e _.';
    }

    return null;
  }

  // ============================================================
  // RESETAR ESTADO DE VERIFICAÇÃO
  // ============================================================

  void resetUsernameCheck() {
    if (_disposed) {
      return;
    }

    _usernameCheckRevision++;

    _isCheckingUsername = false;

    _usernameAvailable = null;

    _usernameValidationMessage = null;

    safeNotify();
  }

  // ============================================================
  // VERIFICAR DISPONIBILIDADE DO USERNAME
  // ============================================================
  //
  // Usa a RPC criada no Supabase:
  //
  // public.check_username_available(text)
  //
  // Retorno:
  //
  // true  -> disponível
  // false -> indisponível / inválido
  //
  // ============================================================

  Future<bool> checkUsernameAvailability(String value) async {
    if (_disposed) {
      return false;
    }

    final username = normalizeUsername(value);

    final validationError = validateUsername(username);

    final revision = ++_usernameCheckRevision;

    if (validationError != null) {
      _isCheckingUsername = false;

      _usernameAvailable = false;

      _usernameValidationMessage = validationError;

      safeNotify();

      return false;
    }

    _isCheckingUsername = true;

    _usernameAvailable = null;

    _usernameValidationMessage = 'Verificando disponibilidade...';

    safeNotify();

    try {
      final result = await _supabase.rpc(
        'check_username_available',
        params: {'requested_username': username},
      );

      if (_disposed || revision != _usernameCheckRevision) {
        return false;
      }

      final available = result == true;

      _usernameAvailable = available;

      _usernameValidationMessage = available
          ? '@$username está disponível.'
          : '@$username já está em uso.';

      return available;
    } on PostgrestException catch (error, stackTrace) {
      if (!_disposed && revision == _usernameCheckRevision) {
        _usernameAvailable = false;

        _usernameValidationMessage = 'Não foi possível verificar o username.';
      }

      debugPrint(
        '[MATCH] '
        'Erro Supabase ao verificar username: '
        '${error.message}',
      );

      debugPrint(
        '[MATCH] '
        'Código: ${error.code}',
      );

      debugPrint('$stackTrace');

      return false;
    } catch (error, stackTrace) {
      if (!_disposed && revision == _usernameCheckRevision) {
        _usernameAvailable = false;

        _usernameValidationMessage = 'Não foi possível verificar o username.';
      }

      debugPrint(
        '[MATCH] '
        'Erro ao verificar username: '
        '$error',
      );

      debugPrint('$stackTrace');

      return false;
    } finally {
      if (!_disposed && revision == _usernameCheckRevision) {
        _isCheckingUsername = false;

        safeNotify();
      }
    }
  }

  // ============================================================
  // SALVAR USERNAME
  // ============================================================
  //
  // Usa a RPC:
  //
  // public.set_my_username(text)
  //
  // A função no banco usa auth.uid(), então o Flutter NÃO envia
  // o ID do usuário.
  //
  // ============================================================

  Future<bool> saveUsername(String value) async {
    if (_disposed || _isSavingUsername) {
      return false;
    }

    final username = normalizeUsername(value);

    final validationError = validateUsername(username);

    if (validationError != null) {
      _usernameAvailable = false;

      _usernameValidationMessage = validationError;

      safeNotify();

      return false;
    }

    // Nunca confiar somente numa verificação antiga.
    //
    // Antes de salvar verificamos novamente a disponibilidade.
    final available = await checkUsernameAvailability(username);

    if (!available || _disposed) {
      return false;
    }

    _isSavingUsername = true;

    safeNotify();

    try {
      final result = await _supabase.rpc(
        'set_my_username',
        params: {'requested_username': username},
      );

      if (_disposed) {
        return false;
      }

      final savedUsername =
          result?.toString().trim().replaceFirst(RegExp(r'^@+'), '') ?? '';

      _currentUsername = savedUsername.isNotEmpty ? savedUsername : username;

      _usernameAvailable = true;

      _usernameValidationMessage = '@$_currentUsername salvo com sucesso.';

      debugPrint(
        '[MATCH] '
        'Username salvo: '
        '@$_currentUsername',
      );

      safeNotify();

      return true;
    } on PostgrestException catch (error, stackTrace) {
      final duplicate = error.code == '23505';

      _usernameAvailable = false;

      _usernameValidationMessage = duplicate
          ? '@$username já está em uso.'
          : 'Não foi possível salvar o username.';

      debugPrint(
        '[MATCH] '
        'Erro Supabase ao salvar username: '
        '${error.message}',
      );

      debugPrint(
        '[MATCH] '
        'Código: ${error.code}',
      );

      debugPrint('$stackTrace');

      safeNotify();

      return false;
    } catch (error, stackTrace) {
      _usernameAvailable = false;

      _usernameValidationMessage = 'Não foi possível salvar o username.';

      debugPrint(
        '[MATCH] '
        'Erro ao salvar username: '
        '$error',
      );

      debugPrint('$stackTrace');

      safeNotify();

      return false;
    } finally {
      if (!_disposed) {
        _isSavingUsername = false;

        safeNotify();
      }
    }
  }

  // ============================================================
  // RECARREGAR ONBOARDING
  // ============================================================
  //
  // Deve ser chamado pela MatchPage depois que o usuário voltar
  // da página "Editar perfil profissional".
  //
  // ============================================================

  Future<void> refreshMatchOnboarding() async {
    if (_disposed) {
      return;
    }

    await Future.wait([
      _professionalProfileController.load(),
      _loadCurrentUsername(),
    ]);

    if (_disposed) {
      return;
    }

    safeNotify();
  }

  // ============================================================
  // LIBERAR SESSÃO DE MATCH APÓS ONBOARDING
  // ============================================================
  //
  // Após username + função principal estarem configurados, a UI
  // chama este método para iniciar a sessão real de discovery.
  //
  // ============================================================

  Future<bool> startMatchAfterOnboarding() async {
    if (_disposed) {
      return false;
    }

    await refreshMatchOnboarding();

    if (_disposed || !isMatchUnlocked) {
      return false;
    }

    await initMatchSession();

    return !_disposed && isMatchUnlocked;
  }

  // ============================================================
  // PEDIR ATENÇÃO AO PERFIL PROFISSIONAL
  // ============================================================
  //
  // A UI observa professionalProfileAttentionRevision.
  //
  // Cada incremento pode disparar uma animação curta de glow no
  // botão "EDITAR PERFIL PROFISSIONAL".
  //
  // ============================================================

  void requestProfessionalProfileAttention() {
    if (_disposed || !requiresProfessionalProfile) {
      return;
    }

    _professionalProfileAttentionRevision++;

    safeNotify();
  }

  // ============================================================
  // CARREGAR DECISÕES PERSISTIDAS
  // ============================================================

  Future<void> _loadPersistedDiscoveryDecisions() async {
    final userId = currentUserId;

    if (userId == null || userId.trim().isEmpty) {
      return;
    }

    final normalizedUserId = userId.trim();

    try {
      // ========================================================
      // LIKES JÁ FEITOS
      // ========================================================

      final likes = await _supabase
          .from('favorites')
          .select('target_user_id')
          .eq('sender_id', normalizedUserId);

      for (final row in likes) {
        final targetId = row['target_user_id']?.toString().trim();

        if (targetId != null && targetId.isNotEmpty) {
          _discoveryDecidedUserIds.add(targetId);
        }
      }

      // ========================================================
      // PASSES / X JÁ FEITOS
      // ========================================================

      final passes = await _supabase
          .from('match_passes')
          .select('target_user_id')
          .eq('sender_id', normalizedUserId);

      for (final row in passes) {
        final targetId = row['target_user_id']?.toString().trim();

        if (targetId != null && targetId.isNotEmpty) {
          _discoveryDecidedUserIds.add(targetId);
        }
      }

      debugPrint(
        '[MATCH] '
        'Perfis já avaliados carregados: '
        '${_discoveryDecidedUserIds.length}.',
      );
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[MATCH] '
        'Erro Supabase ao carregar perfis já avaliados: '
        '${error.message}',
      );

      debugPrint(
        '[MATCH] '
        'Código: '
        '${error.code}',
      );

      debugPrint('$stackTrace');
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH] '
        'Erro ao carregar perfis já avaliados: '
        '$error',
      );

      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // VALIDAR PERFIL
  // ============================================================

  void _validateProfessionalProfile() {
    if (currentPrimaryRole == null) {
      debugPrint(
        '[MATCH] '
        'Função principal não configurada.',
      );
    }

    if (_discoveryMode == MatchDiscoveryMode.compatible &&
        lookingForRoles.isEmpty) {
      debugPrint(
        '[MATCH] '
        'Nenhum profissional procurado configurado.',
      );
    }
  }

  // ============================================================
  // TIMEOUT DA BUSCA
  // ============================================================

  void _startSearchTimeout() {
    _searchTimeoutTimer?.cancel();

    _searchTimeoutTimer = Timer(_searchTimeout, () {
      if (_disposed) {
        return;
      }

      if (!_isLoading) {
        return;
      }

      if (_discoveryUser != null) {
        return;
      }

      if (_recommendedUsers.isNotEmpty) {
        return;
      }

      _setLoading(false);
    });
  }

  // ============================================================
  // LOG DA SESSÃO
  // ============================================================

  void _logSessionStarted() {
    debugPrint('[MATCH] ========================================');

    debugPrint('[MATCH] Sessão iniciada.');

    debugPrint('[MATCH] User ID: $currentUserId');

    debugPrint(
      '[MATCH] '
      'Modo de descoberta: '
      '${_discoveryMode.name}',
    );

    debugPrint(
      '[MATCH] '
      'Username: '
      '${hasUsername ? "@$_currentUsername" : "não informado"}',
    );

    debugPrint(
      '[MATCH] '
      'Função principal: '
      '${currentPrimaryRole?.key ?? "não informado"}',
    );

    debugPrint(
      '[MATCH] '
      'Onboarding liberado: '
      '$isMatchUnlocked',
    );

    debugPrint(
      '[MATCH] '
      'Funções: '
      '${currentRoles.map((role) {
        return role.key;
      }).toList()}',
    );

    debugPrint(
      '[MATCH] '
      'Procura: '
      '${lookingForRoles.map((role) {
        return role.key;
      }).toList()}',
    );

    debugPrint('[MATCH] ========================================');
  }

  // ============================================================
  // LIMPAR RESULTADOS
  // ============================================================

  void clearMatchResults({bool stopLoading = true}) {
    if (_disposed) {
      return;
    }

    _discoveryUser = null;

    _recommendedUsers = const <MatchUserEntity>[];

    _discoveryVisitedUserIds.clear();

    _countdownTimer?.cancel();

    _countdownTimer = null;

    _remainingSeconds = _connectionDurationSeconds;

    if (stopLoading) {
      _isLoading = false;
    }

    safeNotify();

    debugPrint('[MATCH] Resultados limpos.');
  }

  // ============================================================
  // MODO DE DESCOBERTA
  // ============================================================

  void setDiscoveryMode(MatchDiscoveryMode mode) {
    if (_disposed || _discoveryMode == mode) {
      return;
    }

    if (!isMatchUnlocked) {
      requestProfessionalProfileAttention();

      return;
    }

    _discoveryMode = mode;

    // ==========================================================
    // LIMPAR RESULTADOS ANTIGOS
    // ==========================================================
    //
    // O Repository reinicia a busca usando o novo modo.
    //
    // ==========================================================

    _discoveryUser = null;

    _recommendedUsers = const <MatchUserEntity>[];

    _discoveryVisitedUserIds.clear();

    _remainingSeconds = _connectionDurationSeconds;

    _countdownTimer?.cancel();

    _countdownTimer = null;

    _setLoading(true, notify: false);

    _startSearchTimeout();

    safeNotify();

    debugPrint(
      '[MATCH] '
      'Modo de descoberta: '
      '${mode.name}',
    );
  }

  void useCompatibleDiscovery() {
    setDiscoveryMode(MatchDiscoveryMode.compatible);
  }

  void useGlobalDiscovery() {
    setDiscoveryMode(MatchDiscoveryMode.global);
  }

  // ============================================================
  // REALTIME MATCH
  // ============================================================

  void _startRealtimeMatchListener() {
    final userId = currentUserId;

    if (userId == null || userId.trim().isEmpty) {
      debugPrint(
        '[MATCH] '
        'Não foi possível iniciar realtime: '
        'usuário não identificado.',
      );

      return;
    }

    // ==========================================================
    // CANCELAR LISTENER ANTERIOR
    // ==========================================================

    unawaited(_matchSubscription?.cancel());

    _matchSubscription = null;

    // ==========================================================
    // NOVO LISTENER
    // ==========================================================

    _matchSubscription = _supabase
        .from('favorites')
        .stream(primaryKey: ['id'])
        .eq('target_user_id', userId)
        .listen(
          (snapshot) {
            if (_disposed || snapshot.isEmpty) {
              return;
            }

            final lastMatch = snapshot.last;

            final senderId = lastMatch['sender_id']?.toString().trim();

            if (senderId == null || senderId.isEmpty) {
              return;
            }

            unawaited(checkAndStartNetworking(userId, senderId));
          },
          onError: (error) {
            debugPrint(
              '[MATCH] '
              'Erro realtime: $error',
            );
          },
        );
  }

  // ============================================================
  // VERIFICAR MATCH MÚTUO
  // ============================================================

  Future<bool> checkAndStartNetworking(String myId, String otherId) async {
    final normalizedMyId = myId.trim();

    final normalizedOtherId = otherId.trim();

    // ==========================================================
    // VALIDAR
    // ==========================================================

    if (normalizedMyId.isEmpty ||
        normalizedOtherId.isEmpty ||
        normalizedMyId == normalizedOtherId) {
      return false;
    }

    // ==========================================================
    // CHAVE CANÔNICA DO PAR
    // ==========================================================
    //
    // A <-> B
    //
    // e
    //
    // B <-> A
    //
    // representam o mesmo par para controle de concorrência.
    //
    // ==========================================================

    final pairKey = _networkingPairKey(normalizedMyId, normalizedOtherId);

    // ==========================================================
    // VERIFICAÇÃO JÁ EM ANDAMENTO
    // ==========================================================

    if (_networkingChecksInProgress.contains(pairKey)) {
      debugPrint(
        '[MATCH] '
        'Verificação já em andamento para '
        '$normalizedMyId <-> $normalizedOtherId.',
      );

      return false;
    }

    _networkingChecksInProgress.add(pairKey);

    try {
      // ========================================================
      // LIKE: EU -> OUTRO
      // ========================================================

      final myLike = await _supabase
          .from('favorites')
          .select('id')
          .eq('sender_id', normalizedMyId)
          .eq('target_user_id', normalizedOtherId)
          .limit(1);

      // ========================================================
      // LIKE: OUTRO -> EU
      // ========================================================

      final otherLike = await _supabase
          .from('favorites')
          .select('id')
          .eq('sender_id', normalizedOtherId)
          .eq('target_user_id', normalizedMyId)
          .limit(1);

      // ========================================================
      // EU AINDA NÃO CURTI
      // ========================================================

      if (myLike.isEmpty) {
        debugPrint(
          '[MATCH] '
          'Sem match: '
          '$normalizedMyId ainda não curtiu '
          '$normalizedOtherId.',
        );

        return false;
      }

      // ========================================================
      // OUTRO AINDA NÃO CURTIU
      // ========================================================

      if (otherLike.isEmpty) {
        debugPrint(
          '[MATCH] '
          'Like registrado, aguardando reciprocidade: '
          '$normalizedMyId -> '
          '$normalizedOtherId',
        );

        return false;
      }

      // ========================================================
      // MATCH MÚTUO CONFIRMADO
      // ========================================================

      debugPrint(
        '[MATCH] '
        'Match mútuo confirmado: '
        '$normalizedMyId <-> '
        '$normalizedOtherId',
      );

      // ========================================================
      // PROJETO EXISTENTE
      // ========================================================

      final existingProjects = await _supabase
          .from('projects')
          .select('id, members, status, origin')
          .eq('origin', 'match')
          .eq('status', 'active')
          .contains('members', [normalizedMyId, normalizedOtherId])
          .limit(1);

      if (existingProjects.isNotEmpty) {
        final existingProjectId = existingProjects.first['id']
            ?.toString()
            .trim();

        if (existingProjectId != null && existingProjectId.isNotEmpty) {
          _emitMatchEvent(existingProjectId);

          debugPrint(
            '[MATCH] '
            'Projeto existente encontrado: '
            '$existingProjectId',
          );

          return true;
        }
      }

      // ========================================================
      // CRIAR NOVO PROJETO
      // ========================================================

      final newProject = await _supabase
          .from('projects')
          .insert({
            'title': 'Studio Session',

            'members': [normalizedMyId, normalizedOtherId],

            'founders': [normalizedMyId, normalizedOtherId],

            'status': 'active',

            'origin': 'match',
          })
          .select('id')
          .single();

      final newProjectId = newProject['id']?.toString().trim();

      if (newProjectId == null || newProjectId.isEmpty) {
        debugPrint(
          '[MATCH] '
          'Projeto criado sem ID válido.',
        );

        return false;
      }

      // ========================================================
      // EMITIR EVENTO
      // ========================================================

      _emitMatchEvent(newProjectId);

      debugPrint(
        '[MATCH] '
        'Novo projeto criado: '
        '$newProjectId',
      );

      return true;
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[MATCH] '
        'Erro Supabase ao verificar match: '
        '${error.message}',
      );

      debugPrint(
        '[MATCH] '
        'Código: '
        '${error.code}',
      );

      debugPrint(
        '[MATCH] '
        'StackTrace: '
        '$stackTrace',
      );

      return false;
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH] '
        'Erro ao iniciar networking: '
        '$error',
      );

      debugPrint(
        '[MATCH] '
        'StackTrace: '
        '$stackTrace',
      );

      return false;
    } finally {
      _networkingChecksInProgress.remove(pairKey);
    }
  }

  // ============================================================
  // NETWORKING PAIR KEY
  // ============================================================

  String _networkingPairKey(String firstUserId, String secondUserId) {
    final first = firstUserId.trim();

    final second = secondUserId.trim();

    if (first.compareTo(second) <= 0) {
      return '$first::$second';
    }

    return '$second::$first';
  }

  // ============================================================
  // EMITIR MATCH
  // ============================================================

  void _emitMatchEvent(String projectId) {
    if (_disposed || _matchEventController.isClosed) {
      return;
    }

    final normalizedProjectId = projectId.trim();

    if (normalizedProjectId.isEmpty) {
      return;
    }

    // ==========================================================
    // EVENTO JÁ EMITIDO
    // ==========================================================
    //
    // O Realtime pode entregar snapshots repetidos.
    //
    // Não queremos abrir a mesma Studio Session duas vezes.
    //
    // ==========================================================

    if (_emittedProjectIds.contains(normalizedProjectId)) {
      debugPrint(
        '[MATCH] '
        'Evento de networking já emitido para: '
        '$normalizedProjectId',
      );

      return;
    }

    _emittedProjectIds.add(normalizedProjectId);

    _matchEventController.add(normalizedProjectId);
  }

  // ============================================================
  // REGISTRAR LIKE
  // ============================================================

  Future<void> registerLike(String targetId) async {
    if (!isMatchUnlocked) {
      requestProfessionalProfileAttention();

      return;
    }

    final userId = currentUserId;

    // ==========================================================
    // USUÁRIO ATUAL
    // ==========================================================

    if (userId == null || userId.trim().isEmpty) {
      debugPrint(
        '[MATCH] '
        'Like ignorado: '
        'usuário não identificado.',
      );

      return;
    }

    final normalizedUserId = userId.trim();

    final normalizedTargetId = targetId.trim();

    // ==========================================================
    // VALIDAR DESTINO
    // ==========================================================

    if (normalizedTargetId.isEmpty || normalizedTargetId == normalizedUserId) {
      return;
    }

    try {
      // ========================================================
      // GARANTIR LIKE
      // ========================================================
      //
      // O banco possui:
      //
      // UNIQUE(sender_id, target_user_id)
      //
      // Usamos UPSERT + ignoreDuplicates para tornar o like
      // idempotente.
      //
      // Assim:
      //
      // 1º clique
      // -> cria a linha
      //
      // próximos cliques
      // -> não geram HTTP 409
      //
      // Isso é especialmente importante no Flutter Web, onde
      // o conflito aparecia no painel Network do navegador.
      //
      // ========================================================

      await _supabase
          .from('favorites')
          .upsert(
            {
              'sender_id': normalizedUserId,

              'target_user_id': normalizedTargetId,
            },
            onConflict: 'sender_id,target_user_id',
            ignoreDuplicates: true,
          );

      _discoveryDecidedUserIds.add(normalizedTargetId);

      debugPrint(
        '[MATCH] '
        'Like garantido: '
        '$normalizedUserId -> '
        '$normalizedTargetId',
      );

      // ========================================================
      // VERIFICAR RECIPROCIDADE IMEDIATAMENTE
      // ========================================================
      //
      // Mesmo se o like já existia, o outro usuário pode ter
      // curtido depois.
      //
      // Portanto SEMPRE verificamos o match após o upsert.
      //
      // ========================================================

      await checkAndStartNetworking(normalizedUserId, normalizedTargetId);
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[MATCH] '
        'Erro Supabase ao registrar like: '
        '${error.message}',
      );

      debugPrint(
        '[MATCH] '
        'Código: '
        '${error.code}',
      );

      debugPrint(
        '[MATCH] '
        'StackTrace: '
        '$stackTrace',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH] '
        'Erro ao registrar like: '
        '$error',
      );

      debugPrint(
        '[MATCH] '
        'StackTrace: '
        '$stackTrace',
      );
    }
  }

  // ============================================================
  // DISCOVERY USER
  // ============================================================

  void setDiscoveryUser(MatchUserEntity user) {
    if (_disposed) {
      return;
    }

    if (!isMatchUnlocked) {
      requestProfessionalProfileAttention();

      return;
    }

    final userId = user.id.trim();

    if (userId.isEmpty) {
      return;
    }

    if (_discoveryDecidedUserIds.contains(userId)) {
      debugPrint(
        '[MATCH] '
        'Perfil ignorado porque já foi avaliado: '
        '$userId',
      );

      return;
    }

    // ==========================================================
    // ENCERRAR TIMEOUT
    // ==========================================================

    _searchTimeoutTimer?.cancel();

    _searchTimeoutTimer = null;

    // ==========================================================
    // USER
    // ==========================================================

    _discoveryUser = user;

    // ==========================================================
    // LOADING
    // ==========================================================

    _isLoading = false;

    // ==========================================================
    // TIMER
    // ==========================================================

    startConnectionTimer();

    safeNotify();
  }

  // ============================================================
  // PRÓXIMO USUÁRIO DO DISCOVERY
  // ============================================================

  bool moveToNextDiscoveryUser() {
    if (_disposed) {
      return false;
    }

    if (!isMatchUnlocked) {
      requestProfessionalProfileAttention();

      return false;
    }

    final currentUser = _discoveryUser;

    if (currentUser == null) {
      return false;
    }

    final currentId = currentUser.id.trim();

    MatchUserEntity? nextUser;

    for (final candidate in _recommendedUsers) {
      final candidateId = candidate.id.trim();

      if (candidateId.isEmpty) {
        continue;
      }

      if (candidateId == currentId) {
        continue;
      }

      if (_discoveryVisitedUserIds.contains(candidateId)) {
        continue;
      }

      if (_discoveryDecidedUserIds.contains(candidateId)) {
        continue;
      }

      nextUser = candidate;

      break;
    }

    if (nextUser == null) {
      debugPrint(
        '[MATCH] Nenhum próximo usuário disponível. '
        'Mantendo ${currentUser.name}.',
      );

      return false;
    }

    if (currentId.isNotEmpty) {
      _discoveryVisitedUserIds.add(currentId);
    }

    _discoveryUser = nextUser;

    startConnectionTimer();

    safeNotify();

    return true;
  }

  bool dismissCurrentDiscoveryUser() {
    if (_disposed || _discoveryUser == null) {
      return false;
    }

    if (!isMatchUnlocked) {
      requestProfessionalProfileAttention();

      return false;
    }

    final currentUser = _discoveryUser;

    if (currentUser == null) {
      return false;
    }

    final targetId = currentUser.id.trim();

    if (targetId.isEmpty) {
      return false;
    }

    // ==========================================================
    // MARCAR IMEDIATAMENTE EM MEMÓRIA
    // ==========================================================
    //
    // Faz o perfil sumir no mesmo instante, mesmo antes do
    // Supabase finalizar a gravação.
    //
    // ==========================================================

    _discoveryDecidedUserIds.add(targetId);

    // ==========================================================
    // PERSISTIR PASS / X
    // ==========================================================
    //
    // Mantemos este método síncrono para não quebrar os widgets
    // atuais que já esperam bool.
    //
    // ==========================================================

    unawaited(_registerPass(targetId));

    return moveToNextDiscoveryUser();
  }

  // ============================================================
  // REGISTRAR PASS / X
  // ============================================================

  Future<void> _registerPass(String targetId) async {
    final userId = currentUserId;

    if (userId == null || userId.trim().isEmpty) {
      return;
    }

    final normalizedUserId = userId.trim();

    final normalizedTargetId = targetId.trim();

    if (normalizedTargetId.isEmpty || normalizedTargetId == normalizedUserId) {
      return;
    }

    try {
      await _supabase
          .from('match_passes')
          .upsert(
            {
              'sender_id': normalizedUserId,
              'target_user_id': normalizedTargetId,
            },
            onConflict: 'sender_id,target_user_id',
            ignoreDuplicates: true,
          );

      debugPrint(
        '[MATCH] '
        'Pass registrado: '
        '$normalizedUserId -> '
        '$normalizedTargetId',
      );
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[MATCH] '
        'Erro Supabase ao registrar pass: '
        '${error.message}',
      );

      debugPrint(
        '[MATCH] '
        'Código: '
        '${error.code}',
      );

      debugPrint('$stackTrace');
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH] '
        'Erro ao registrar pass: '
        '$error',
      );

      debugPrint('$stackTrace');
    }
  }

  Future<bool> likeCurrentDiscoveryUserAndAdvance() async {
    if (_disposed) {
      return false;
    }

    if (!isMatchUnlocked) {
      requestProfessionalProfileAttention();

      return false;
    }

    final currentUser = _discoveryUser;

    if (currentUser == null) {
      return false;
    }

    final targetId = currentUser.id.trim();

    if (targetId.isEmpty) {
      return false;
    }

    await registerLike(targetId);

    if (_disposed) {
      return false;
    }

    return moveToNextDiscoveryUser();
  }

  // ============================================================
  // RECOMENDAÇÕES
  // ============================================================

  void updateRecommendedUsers(List<MatchUserEntity> users) {
    if (_disposed) {
      return;
    }

    // ==========================================================
    // ENCERRAR TIMEOUT
    // ==========================================================

    _searchTimeoutTimer?.cancel();

    _searchTimeoutTimer = null;

    // ==========================================================
    // RESULTADOS
    // ==========================================================

    final myUserId = currentUserId?.trim();

    final filteredUsers = users
        .where((user) {
          final candidateId = user.id.trim();

          if (candidateId.isEmpty) {
            return false;
          }

          if (myUserId != null &&
              myUserId.isNotEmpty &&
              candidateId == myUserId) {
            return false;
          }

          if (_discoveryDecidedUserIds.contains(candidateId)) {
            return false;
          }

          return true;
        })
        .toList(growable: false);

    _recommendedUsers = List<MatchUserEntity>.unmodifiable(filteredUsers);

    // ==========================================================
    // PERFIL ATUAL JÁ FOI AVALIADO
    // ==========================================================

    final currentDiscoveryId = _discoveryUser?.id.trim();

    if (currentDiscoveryId != null &&
        currentDiscoveryId.isNotEmpty &&
        _discoveryDecidedUserIds.contains(currentDiscoveryId)) {
      _discoveryUser = null;
    }

    // ==========================================================
    // BUSCA FINALIZADA
    // ==========================================================

    _isLoading = false;

    safeNotify();
  }

  // ============================================================
  // TIMER DA CONEXÃO
  // ============================================================

  void startConnectionTimer() {
    if (_disposed) {
      return;
    }

    _countdownTimer?.cancel();

    _remainingSeconds = _connectionDurationSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();

        return;
      }

      if (_remainingSeconds > 0) {
        _remainingSeconds--;

        safeNotify();

        return;
      }

      timer.cancel();

      _countdownTimer = null;
    });
  }

  // ============================================================
  // CANCELAR TIMERS
  // ============================================================

  void _cancelTimers() {
    _countdownTimer?.cancel();

    _countdownTimer = null;

    _searchTimeoutTimer?.cancel();

    _searchTimeoutTimer = null;
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(bool value, {bool notify = true}) {
    if (_disposed) {
      return;
    }

    if (_isLoading == value) {
      return;
    }

    _isLoading = value;

    if (notify) {
      safeNotify();
    }
  }

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  void safeNotify() {
    if (_disposed) {
      return;
    }

    if (!hasListeners) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // CONTRATO PROVISÓRIO
  // ============================================================

  String generateProvisionalContractHash(String userA, String userB) {
    final normalizedUserA = userA.trim();

    final normalizedUserB = userB.trim();

    final hash = normalizedUserA.hashCode ^ normalizedUserB.hashCode;

    return 'VRSN-'
        '$hash-'
        '${DateTime.now().millisecondsSinceEpoch}';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    // ==========================================================
    // MARCAR COMO ENCERRADO
    // ==========================================================

    _disposed = true;

    // ==========================================================
    // TIMERS
    // ==========================================================

    _cancelTimers();

    // ==========================================================
    // REALTIME
    // ==========================================================

    unawaited(_matchSubscription?.cancel());

    _matchSubscription = null;

    _networkingChecksInProgress.clear();

    _emittedProjectIds.clear();

    _discoveryVisitedUserIds.clear();

    _discoveryDecidedUserIds.clear();

    // ==========================================================
    // EVENT STREAM
    // ==========================================================

    if (!_matchEventController.isClosed) {
      unawaited(_matchEventController.close());
    }

    // ==========================================================
    // NÃO DISPOR PROFESSIONAL PROFILE CONTROLLER
    // ==========================================================
    //
    // ProfessionalProfileController é LazySingleton e é
    // compartilhado por outras partes do aplicativo.
    //
    // ==========================================================

    super.dispose();
  }
}
