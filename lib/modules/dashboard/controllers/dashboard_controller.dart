import 'package:flutter/material.dart';

import 'package:versin/modules/login/data/repositories/auth_repository_impl.dart';
import 'package:versin/modules/login/domain/repositories/auth_repository.dart';

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

  String _artistName = 'Artista';

  bool _isLoadingArtistName = false;

  String get artistName => _artistName;

  bool get isLoadingArtistName => _isLoadingArtistName;

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

    _checkActiveProjects();

    await loadArtistName();
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

    notifyListeners();

    try {
      final name = await _authRepository.getArtistName();

      if (name !=
              null &&
          name.trim().isNotEmpty) {
        _artistName = name.trim();
      } else {
        _artistName = 'Artista';
      }

      debugPrint(
        '[DASHBOARD] '
        'Nome artístico carregado: $_artistName',
      );
    } catch (
      error
    ) {
      debugPrint(
        '[DASHBOARD] '
        'Erro ao carregar nome artístico: $error',
      );

      _artistName = 'Artista';
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

    notifyListeners();
  }

  // ============================================================
  // PROJETO ATIVO
  // ============================================================

  void _checkActiveProjects() {
    // ==========================================================
    // TEMPORÁRIO
    // ==========================================================
    //
    // Mantido com o comportamento anterior.
    //
    // Posteriormente esta informação deve vir do módulo de
    // projetos / banco de dados.
    //
    // ==========================================================

    hasActiveProject = true;

    notifyListeners();
  }

  // ============================================================
  // NAVEGAÇÃO PELO MENU
  // ============================================================

  void navigationTap(
    int index,
  ) {
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
    _artistName = 'Artista';

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
