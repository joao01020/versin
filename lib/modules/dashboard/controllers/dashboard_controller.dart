import 'package:flutter/material.dart';

import 'package:versin/modules/login/data/repositories/auth_repository_impl.dart';
import 'package:versin/modules/login/domain/repositories/auth_repository.dart';

import '../data/models/hardware_status_model.dart';
import '../repositories/dashboard_repository.dart';

class DashboardController
    extends
        ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();

  final AuthRepository _authRepository = AuthRepositoryImpl();

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

  bool isCalendarExpanded = false;

  bool hasActiveProject = false;

  DateTime focusedDay = DateTime.now();

  int selectedDay = DateTime.now().day;

  // ============================================================
  // COMPROMISSOS
  // ============================================================

  final List<
    Map<
      String,
      dynamic
    >
  >
  appointments = [
    {
      'day': DateTime.now().day,
      'month': DateTime.now().month,
      'year': DateTime.now().year,
      'time': '14:00',
      'title': 'Sessão de Mixagem - Trap Beat',
    },
    {
      'day': DateTime.now().day,
      'month': DateTime.now().month,
      'year': DateTime.now().year,
      'time': '18:30',
      'title': 'Sync do banco com Supabase V2',
    },
    {
      'day': 20,
      'month': 5,
      'year': 2026,
      'time': '10:00',
      'title': 'Recuperar batidas antigas',
    },
  ];

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
  get hardwareStatusStream => _repository.getHardwareStatusStream();

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
        '[DASHBOARD] Nome artístico carregado: $_artistName',
      );
    } catch (
      error
    ) {
      debugPrint(
        '[DASHBOARD] Erro ao carregar nome artístico: $error',
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
  // CALENDÁRIO
  // ============================================================

  void toggleCalendarExpanded() {
    isCalendarExpanded = !isCalendarExpanded;

    notifyListeners();
  }

  void updateFocusedMonth(
    int newMonth,
  ) {
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
    selectedDay = day;

    notifyListeners();
  }

  // ============================================================
  // COMPROMISSOS
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

    appointments.add(
      {
        'day': selectedDay,
        'month': focusedDay.month,
        'year': focusedDay.year,
        'time': normalizedTime,
        'title': normalizedTitle,
      },
    );

    notifyListeners();
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
