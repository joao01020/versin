import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/login/data/repositories/auth_repository_impl.dart';
import 'package:versin/modules/login/domain/repositories/auth_repository.dart';
import 'package:versin/modules/profile/services/profile_name_cache_service.dart';

import '../data/models/hardware_status_model.dart';
import '../repositories/dashboard_repository.dart';

// ============================================================
// DASHBOARD CONTROLLER
// ============================================================

class DashboardController
    extends
        ChangeNotifier {
  // ============================================================
  // REPOSITORIES
  // ============================================================

  final DashboardRepository _repository = DashboardRepository();

  final AuthRepository _authRepository = AuthRepositoryImpl();

  final ProfileNameCacheService _profileNameCacheService = ProfileNameCacheService();

  // ============================================================
  // PAGE CONTROLLER
  // ============================================================

  PageController? _pageController;

  int _currentIndex = 0;

  // ============================================================
  // CORES
  // ============================================================

  final Color primaryPurple = const Color(
    0xFF6A1B9A,
  );

  final Color deepBg = const Color(
    0xFF0D0B1F,
  );

  final Color accentNeon = const Color(
    0xFFE040FB,
  );

  final Color hackerGreen = const Color(
    0xFF00FF66,
  );

  final Color calendarBg = const Color(
    0xFF1E1E1E,
  );

  final Color calendarPurpleAccent = const Color(
    0xFF9C27B0,
  );

  // ============================================================
  // PERFIL / ARTISTA
  // ============================================================

  String _artistName = '';

  bool _isLoadingArtistName = false;

  bool _isSavingArtistName = false;

  bool _artistNameResolved = false;

  String? _artistNameError;

  String get artistName => _artistName;

  bool get isLoadingArtistName => _isLoadingArtistName;

  bool get isSavingArtistName => _isSavingArtistName;

  bool get artistNameResolved => _artistNameResolved;

  String? get artistNameError => _artistNameError;

  bool get requiresArtistName {
    if (!_artistNameResolved) {
      return false;
    }

    final normalized = _artistName.trim();

    return normalized.isEmpty ||
        normalized ==
            'Membro';
  }

  bool get canUseApplication {
    return _artistNameResolved &&
        !requiresArtistName;
  }

  String? profileImagePath;

  // ============================================================
  // ESTADOS
  // ============================================================

  bool isProfileCardExpanded = true;

  // ============================================================
  // CALENDÁRIO LEGADO
  // ============================================================
  //
  // Estes estados permanecem temporariamente porque alguns
  // componentes antigos do Dashboard ainda podem utilizá-los.
  //
  // O novo módulo de calendário utiliza:
  //
  // CalendarController
  // CalendarService
  // CalendarRepository
  //
  // ============================================================

  bool isCalendarExpanded = false;

  DateTime focusedDay = DateTime.now();

  int selectedDay = DateTime.now().day;

  // ============================================================
  // PROJETO
  // ============================================================

  bool hasActiveProject = false;

  // ============================================================
  // COMPROMISSOS LEGADOS
  // ============================================================
  //
  // IMPORTANTE:
  //
  // As tarefas fake foram REMOVIDAS.
  //
  // Esta lista fica vazia apenas por compatibilidade temporária
  // com widgets antigos do Dashboard.
  //
  // Novas tarefas NÃO devem ser persistidas aqui.
  //
  // A fonte real passa a ser o módulo:
  //
  // modules/calendar
  //
  // ============================================================

  final List<
    Map<
      String,
      dynamic
    >
  >
  appointments = [];

  // ============================================================
  // GETTERS
  // ============================================================

  int get currentIndex => _currentIndex;

  PageController get pageController {
    return _pageController ??= PageController(
      initialPage: _currentIndex,
    );
  }

  Stream<
    List<
      HardwareStatusModel
    >
  >
  get hardwareStatusStream {
    return _repository.getHardwareStatusStream();
  }

  // ============================================================
  // INIT
  // ============================================================

  Future<
    void
  >
  init() async {
    _pageController ??= PageController(
      initialPage: _currentIndex,
    );

    await Future.wait(
      [
        _checkActiveProjects(),
        loadArtistName(),
      ],
    );
  }

  // ============================================================
  // CARREGAR NOME ARTÍSTICO
  // ============================================================

  Future<
    void
  >
  loadArtistName() async {
    if (_isLoadingArtistName) {
      return;
    }

    _isLoadingArtistName = true;

    _artistNameError = null;

    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id.trim();

      if (userId ==
              null ||
          userId.isEmpty) {
        _artistName = 'Membro';

        _artistNameResolved = true;

        return;
      }

      // ========================================================
      // FONTE DE VERDADE DO ONBOARDING
      // ========================================================
      //
      // Para liberar o aplicativo, verificamos especificamente:
      //
      // public.profiles.artist_name
      //
      // NÃO usamos:
      //
      // - username;
      // - name;
      // - e-mail;
      // - fallback do cache.
      //
      // Isso é intencional.
      //
      // O usuário só deixa o onboarding quando realmente possui
      // um nome público salvo em artist_name.
      //
      // ========================================================

      final profile = await Supabase.instance.client
          .from(
            'profiles',
          )
          .select(
            'artist_name',
          )
          .eq(
            'id',
            userId,
          )
          .maybeSingle();

      final artistName =
          profile?['artist_name']?.toString().trim() ??
          '';

      if (artistName.isNotEmpty) {
        _artistName = artistName;

        await _profileNameCacheService.cacheName(
          userId: userId,
          displayName: artistName,
        );

        debugPrint(
          '[DASHBOARD] '
          'Nome público carregado: $_artistName',
        );
      } else {
        _artistName = 'Membro';

        debugPrint(
          '[DASHBOARD] '
          'Perfil sem artist_name. '
          'Onboarding de nome obrigatório.',
        );
      }

      _artistNameResolved = true;
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      _artistName = 'Membro';

      _artistNameResolved = true;

      _artistNameError = 'Não foi possível carregar o nome do perfil.';

      debugPrint(
        '[DASHBOARD] '
        'Erro Supabase ao carregar artist_name: '
        '${error.message}',
      );

      debugPrint(
        '[DASHBOARD] '
        'Código: ${error.code}',
      );

      debugPrint(
        '$stackTrace',
      );
    } catch (
      error,
      stackTrace
    ) {
      _artistName = 'Membro';

      _artistNameResolved = true;

      _artistNameError = 'Não foi possível carregar o nome do perfil.';

      debugPrint(
        '[DASHBOARD] '
        'Erro ao carregar nome do perfil: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    } finally {
      _isLoadingArtistName = false;

      notifyListeners();
    }
  }

  // ============================================================
  // ATUALIZAR NOME ARTÍSTICO EM MEMÓRIA
  // ============================================================

  void updateArtistName(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return;
    }

    _artistName = normalized;

    _artistNameResolved = true;

    _artistNameError = null;

    notifyListeners();
  }

  // ============================================================
  // SALVAR NOME OBRIGATÓRIO
  // ============================================================
  //
  // Salva somente:
  //
  // public.profiles.artist_name
  //
  // Não altera:
  //
  // - username;
  // - bio;
  // - avatar;
  // - função profissional;
  // - habilidades.
  //
  // ============================================================

  Future<
    bool
  >
  saveArtistName(
    String value,
  ) async {
    if (_isSavingArtistName) {
      return false;
    }

    final normalized = value.trim();

    if (normalized.length <
        2) {
      _artistNameError = 'Digite pelo menos 2 caracteres.';

      notifyListeners();

      return false;
    }

    if (normalized.length >
        60) {
      _artistNameError = 'O nome pode ter no máximo 60 caracteres.';

      notifyListeners();

      return false;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      _artistNameError = 'Não foi possível identificar sua conta.';

      notifyListeners();

      return false;
    }

    _isSavingArtistName = true;

    _artistNameError = null;

    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from(
            'profiles',
          )
          .update(
            {
              'artist_name': normalized,

              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          )
          .eq(
            'id',
            userId,
          )
          .select(
            'artist_name',
          )
          .maybeSingle();

      final savedName =
          response?['artist_name']?.toString().trim() ??
          '';

      if (savedName.isEmpty) {
        throw StateError(
          'O banco não confirmou o nome salvo.',
        );
      }

      await _profileNameCacheService.cacheName(
        userId: userId,
        displayName: savedName,
      );

      _artistName = savedName;

      _artistNameResolved = true;

      _artistNameError = null;

      debugPrint(
        '[DASHBOARD] '
        'Nome público salvo com sucesso.',
      );

      notifyListeners();

      return true;
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      _artistNameError = 'Não foi possível salvar seu nome.';

      debugPrint(
        '[DASHBOARD] '
        'Erro Supabase ao salvar artist_name: '
        '${error.message}',
      );

      debugPrint(
        '[DASHBOARD] '
        'Código: ${error.code}',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    } catch (
      error,
      stackTrace
    ) {
      _artistNameError = 'Não foi possível salvar seu nome.';

      debugPrint(
        '[DASHBOARD] '
        'Erro ao salvar nome público: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    } finally {
      _isSavingArtistName = false;

      notifyListeners();
    }
  }

  // ============================================================
  // PROJETO ATIVO
  // ============================================================

  Future<
    void
  >
  _checkActiveProjects() async {
    final userId = Supabase.instance.client.auth.currentUser?.id.trim();

    // ==========================================================
    // SEM USUÁRIO AUTENTICADO
    // ==========================================================

    if (userId ==
            null ||
        userId.isEmpty) {
      if (hasActiveProject) {
        hasActiveProject = false;

        notifyListeners();
      }

      debugPrint(
        '[DASHBOARD] '
        'Projeto ativo: usuário não autenticado.',
      );

      return;
    }

    try {
      // ========================================================
      // PROJETO DE MATCH ATIVO
      // ========================================================
      //
      // O card do Dashboard só deve aparecer quando existir
      // realmente uma Studio Session criada pelo Match:
      //
      // origin = match
      // status = active
      // usuário atual pertence a members
      //
      // ========================================================

      final response = await Supabase.instance.client
          .from(
            'projects',
          )
          .select(
            'id',
          )
          .eq(
            'origin',
            'match',
          )
          .eq(
            'status',
            'active',
          )
          .contains(
            'members',
            <
              String
            >[
              userId,
            ],
          )
          .limit(
            1,
          );

      final rows =
          List<
            Map<
              String,
              dynamic
            >
          >.from(
            response,
          );

      final hasProject = rows.isNotEmpty;

      if (hasActiveProject !=
          hasProject) {
        hasActiveProject = hasProject;

        notifyListeners();
      }

      debugPrint(
        '[DASHBOARD] '
        'Projeto de Match ativo: $hasActiveProject',
      );
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD] '
        'Erro Supabase ao verificar projeto ativo: '
        '${error.message}',
      );

      debugPrint(
        '[DASHBOARD] '
        'Código: ${error.code}',
      );

      debugPrint(
        '$stackTrace',
      );

      if (hasActiveProject) {
        hasActiveProject = false;

        notifyListeners();
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD] '
        'Erro ao verificar projeto ativo: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (hasActiveProject) {
        hasActiveProject = false;

        notifyListeners();
      }
    }
  }

  // ============================================================
  // RECARREGAR PROJETO ATIVO
  // ============================================================
  //
  // Pode ser chamado quando:
  //
  // - um Match criar projeto;
  // - um convite de projeto for aceito;
  // - um projeto for encerrado;
  // - o Dashboard voltar ao foco.
  //
  // ============================================================

  Future<
    void
  >
  refreshActiveProject() async {
    await _checkActiveProjects();
  }

  // ============================================================
  // NAVEGAÇÃO PELO MENU
  // ============================================================

  void navigationTap(
    int index,
  ) {
    // ========================================================
    // ONBOARDING DE NOME
    // ========================================================
    //
    // Mesmo que algum widget tente navegar diretamente pelo
    // controller, o usuário permanece na Home até possuir
    // artist_name.
    //
    // ========================================================

    if (requiresArtistName &&
        index !=
            0) {
      return;
    }

    if (_currentIndex ==
        index) {
      return;
    }

    _currentIndex = index;

    final controller = _pageController;

    if (controller !=
            null &&
        controller.hasClients) {
      controller.jumpToPage(
        index,
      );
    }

    notifyListeners();
  }

  // ============================================================
  // ALTERAÇÃO DO PAGEVIEW
  // ============================================================

  void handlePageChange(
    int index,
  ) {
    if (requiresArtistName &&
        index !=
            0) {
      return;
    }

    if (_currentIndex ==
        index) {
      return;
    }

    _currentIndex = index;

    notifyListeners();
  }

  // ============================================================
  // TÍTULO DO MÓDULO
  // ============================================================

  String getModuleTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';

      case 1:
        return 'Conectar';

      case 2:
        return 'Mercado';

      case 3:
        return 'Carteira';

      case 4:
        return 'IA';

      case 5:
        return 'Armazenamento';

      case 6:
        return 'Hardware Hub';

      case 7:
        return 'VNode Network';

      case 8:
        return 'Ajustes';

      case 9:
        return 'Estúdio';

      default:
        return 'Dashboard';
    }
  }

  // ============================================================
  // MESES
  // ============================================================

  String getShortMonthName(
    int month,
  ) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    if (month <
            1 ||
        month >
            12) {
      return '';
    }

    return months[month -
        1];
  }

  // ============================================================
  // PERFIL
  // ============================================================

  void toggleProfileCard() {
    if (requiresArtistName) {
      if (!isProfileCardExpanded) {
        isProfileCardExpanded = true;

        notifyListeners();
      }

      return;
    }

    isProfileCardExpanded = !isProfileCardExpanded;

    notifyListeners();
  }

  // ============================================================
  // CALENDÁRIO LEGADO
  // ============================================================
  //
  // Estes métodos permanecem temporariamente para evitar
  // quebrar widgets antigos.
  //
  // A CalendarPage nova possui seu próprio CalendarController.
  //
  // ============================================================

  void toggleCalendarExpanded() {
    isCalendarExpanded = !isCalendarExpanded;

    notifyListeners();
  }

  void updateFocusedMonth(
    int newMonth,
  ) {
    if (newMonth <
            1 ||
        newMonth >
            12) {
      return;
    }

    focusedDay = DateTime(
      focusedDay.year,
      newMonth,
      1,
    );

    selectedDay = 1;

    notifyListeners();
  }

  void updateFocusedYear(
    int newYear,
  ) {
    focusedDay = DateTime(
      newYear,
      focusedDay.month,
      1,
    );

    selectedDay = 1;

    notifyListeners();
  }

  void navigateMonth({
    required bool forward,
  }) {
    focusedDay = DateTime(
      focusedDay.year,
      focusedDay.month +
          (forward
              ? 1
              : -1),
      1,
    );

    selectedDay = 1;

    notifyListeners();
  }

  void selectDay(
    int day,
  ) {
    final maxDay = DateTime(
      focusedDay.year,
      focusedDay.month +
          1,
      0,
    ).day;

    if (day <
            1 ||
        day >
            maxDay) {
      return;
    }

    selectedDay = day;

    notifyListeners();
  }

  // ============================================================
  // ADICIONAR COMPROMISSO LEGADO
  // ============================================================
  //
  // Mantido somente para compatibilidade com código antigo.
  //
  // NÃO deve mais ser utilizado para novos compromissos.
  //
  // Os novos compromissos devem utilizar:
  //
  // CalendarController.createPersonalEvent()
  //
  // ou
  //
  // CalendarController.createCollaborativeEvent()
  //
  // ============================================================

  void addAppointment({
    required String title,
    required String time,
  }) {
    final normalizedTitle = title.trim();

    final normalizedTime = time.trim();

    if (normalizedTitle.isEmpty ||
        normalizedTime.isEmpty) {
      return;
    }

    debugPrint(
      '[DASHBOARD] '
      'addAppointment() legado ignorado. '
      'Use o novo módulo Calendar.',
    );
  }

  // ============================================================
  // LIMPAR COMPROMISSOS LEGADOS
  // ============================================================

  void clearLegacyAppointments() {
    if (appointments.isEmpty) {
      return;
    }

    appointments.clear();

    notifyListeners();

    debugPrint(
      '[DASHBOARD] '
      'Compromissos legados removidos.',
    );
  }

  // ============================================================
  // IMAGEM DE PERFIL
  // ============================================================

  void pickProfileImage() {
    debugPrint(
      'Abrir seletor de galeria local',
    );
  }

  // ============================================================
  // RESET DO PAGE CONTROLLER
  // ============================================================

  void resetPageController() {
    _pageController?.dispose();

    _pageController = null;
  }

  // ============================================================
  // RESET DE NAVEGAÇÃO
  // ============================================================

  void resetNavigation() {
    _currentIndex = 0;

    resetPageController();

    notifyListeners();
  }

  // ============================================================
  // RESET DO PERFIL
  // ============================================================

  void resetProfile() {
    _artistName = '';

    _artistNameResolved = false;

    _isLoadingArtistName = false;

    _isSavingArtistName = false;

    _artistNameError = null;

    profileImagePath = null;

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _pageController?.dispose();

    _pageController = null;

    super.dispose();
  }
}
