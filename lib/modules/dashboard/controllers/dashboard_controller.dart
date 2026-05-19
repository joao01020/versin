import 'package:flutter/material.dart';
import '../repositories/dashboard_repository.dart'; // <-- Importa o repositório
import '../data/models/hardware_status_model.dart'; // ⚡ IMPORT ADICIONADO: Para reconhecer o tipo do chassi

/// [DashboardController] handles business logic, consuming data safely through repositories.
/// [DashboardController] gerencia a lógica de negócios, consumindo dados de forma segura via repositórios.
class DashboardController {
  // Injecting the data repository / Injetando o repositório de dados
  final DashboardRepository _repository = DashboardRepository();

  // NAVIGATION & PAGE CONTROL
  late final PageController pageController;
  int currentIndex = 0;

  // SYSTEM PALETTE & DESIGN COLORS
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color deepBg = const Color(0xFF0D0B1F);
  final Color accentNeon = const Color(0xFFE040FB);
  final Color hackerGreen = const Color(0xFF00FF66);
  final Color calendarBg = const Color(0xFF1E1E1E);
  final Color calendarPurpleAccent = const Color(0xFF9C27B0);

  // STATES
  String? profileImagePath;
  bool isProfileCardExpanded = true;
  bool isCalendarExpanded = false;
  DateTime focusedDay = DateTime.now();
  int selectedDay = DateTime.now().day;

  // APPOINTMENTS MOCK DATA
  final List<Map<String, dynamic>> appointments = [
    {"day": DateTime.now().day, "month": DateTime.now().month, "year": DateTime.now().year, "time": "14:00", "title": "Sessão de Mixagem - Trap Beat"},
    {"day": DateTime.now().day, "month": DateTime.now().month, "year": DateTime.now().year, "time": "18:30", "title": "Sync do banco com Supabase V2"},
    {"day": 20, "month": 5, "year": 2026, "time": "10:00", "title": "Recuperar batidas antigas"},
  ];

  // EXPOSING THE STREAM FROM THE REPOSITORY / EXPOENDO O STREAM VINDO DO REPOSITÓRIO
  /// Stream fetching hardware real-time data from the backend repository layer.
  // ⚡ RETORNO CORRIGIDO: Agora batendo perfeitamente com o tipo que vem do DashboardRepository
  Stream<List<HardwareStatusModel>> get hardwareStatusStream => _repository.getHardwareStatusStream();

  void init() {
    pageController = PageController(initialPage: currentIndex);
  }

  void disposeController() {
    pageController.dispose();
  }

  void navigationTap(int index) {
    currentIndex = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void handlePageChange(int index) {
    currentIndex = index;
  }

  String getModuleTitle() {
    switch (currentIndex) {
      case 0: return "Lab Module";
      case 1: return "Match";
      case 2: return "Market";
      case 3: return "Wallet";
      case 4: return "Studio Chat";
      case 5: return "Showcase";
      case 6: return "Hardware Hub";
      case 7: return "VNode Network";
      case 8: return "Settings";
      default: return "Dashboard";
    }
  }

  String getShortMonthName(int month) {
    const months = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
    return months[month - 1];
  }

  void toggleProfileCard() => isProfileCardExpanded = !isProfileCardExpanded;
  void toggleCalendarExpanded() => isCalendarExpanded = !isCalendarExpanded;

  void updateFocusedMonth(int newMonth) {
    focusedDay = DateTime(focusedDay.year, newMonth, 1);
    selectedDay = 1;
  }

  void updateFocusedYear(int newYear) {
    focusedDay = DateTime(newYear, focusedDay.month, 1);
    selectedDay = 1;
  }

  void navigateMonth({required bool forward}) {
    int nextMonth = forward ? focusedDay.month + 1 : focusedDay.month - 1;
    focusedDay = DateTime(focusedDay.year, nextMonth, 1);
    selectedDay = 1;
  }

  void selectDay(int day) => selectedDay = day;

  void addAppointment({required String title, required String time}) {
    appointments.add({
      "day": selectedDay,
      "month": focusedDay.month,
      "year": focusedDay.year,
      "time": time,
      "title": title,
    });
  }

  void pickProfileImage() => debugPrint("Abrir seletor de galeria local");
}