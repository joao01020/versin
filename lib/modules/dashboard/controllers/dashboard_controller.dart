import 'package:flutter/material.dart';

import '../data/models/hardware_status_model.dart';
import '../repositories/dashboard_repository.dart';

class DashboardController
    extends
        ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();

  late final PageController pageController;

  int _currentIndex = 0;

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

  String? profileImagePath;

  bool isProfileCardExpanded = true;
  bool isCalendarExpanded = false;
  bool hasActiveProject = false;

  DateTime focusedDay = DateTime.now();
  int selectedDay = DateTime.now().day;

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

  int get currentIndex => _currentIndex;

  Stream<
    List<
      HardwareStatusModel
    >
  >
  get hardwareStatusStream => _repository.getHardwareStatusStream();

  void init() {
    pageController = PageController(
      initialPage: _currentIndex,
    );

    _checkActiveProjects();
  }

  void _checkActiveProjects() {
    hasActiveProject = true;
    notifyListeners();
  }

  void navigationTap(
    int index,
  ) {
    if (_currentIndex ==
        index) {
      return;
    }

    _currentIndex = index;

    pageController.animateToPage(
      index,
      duration: const Duration(
        milliseconds: 300,
      ),
      curve: Curves.easeInOut,
    );

    notifyListeners();
  }

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

  String getModuleTitle() {
    const titles = [
      'Dashboard',
      'Match',
      'Market',
      'Wallet',
      'Studio Chat',
      'Showcase',
      'Hardware Hub',
      'VNode Network',
      'Settings',
    ];

    if (_currentIndex <
            0 ||
        _currentIndex >=
            titles.length) {
      return 'Dashboard';
    }

    return titles[_currentIndex];
  }

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

  void toggleProfileCard() {
    isProfileCardExpanded = !isProfileCardExpanded;
    notifyListeners();
  }

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

  void addAppointment({
    required String title,
    required String time,
  }) {
    appointments.add(
      {
        'day': selectedDay,
        'month': focusedDay.month,
        'year': focusedDay.year,
        'time': time,
        'title': title,
      },
    );

    notifyListeners();
  }

  void pickProfileImage() {
    debugPrint(
      'Abrir seletor de galeria local',
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
