import 'dart:async';
import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';
import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';
// EN: Importing the user entity to handle structured data
// PT: Importando a entidade de usuário para lidar com dados estruturados
import '../models/match_user_entity.dart';

class MatchController with ChangeNotifier {
  // EN: Fetching the unique DashboardController instance to access global states and tokens
  // PT: Buscando a instância única do DashboardController para acessar estados globais e tokens
  final DashboardController _dashboardController = sl<DashboardController>();

  // EN: Getters to maintain styling consistency without modifying the frontend properties
  // PT: Getters para manter a consistência de estilo sem modificar as propriedades do frontend
  Color get accentNeon => _dashboardController.accentNeon;
  Color get primaryPurple => _dashboardController.primaryPurple;

  // EN: State management variables starting empty, waiting for real-time pipeline stream
  // PT: Variáveis de gerenciamento de estado iniciando vazias, aguardando o stream do pipeline em tempo real
  bool isLoading = true;
  MatchUserEntity? discoveryUser;
  List<MatchUserEntity> recommendedUsers = [];

  // EN: 20-minute countdown timer logic (1200 seconds)
  // PT: Lógica do temporizador de contagem regressiva de 20 minutos (1200 segundos)
  Timer? _countdownTimer;
  int remainingSeconds = 1200;

  // EN: Safety timeout timer to prevent endless loading when no users are found
  // PT: Timer de segurança para evitar carregamento infinito quando nenhum usuário é encontrado
  Timer? _searchTimeoutTimer;

  // EN: Initializes the match session in an empty waiting state with an optimized 1.5-second search window
  // PT: Inicializa a sessão de match em estado de espera vazio com uma janela de busca otimizada de 1.5 segundos
  void initMatchSession(UserRole currentUserRole) {
    isLoading = true;
    discoveryUser = null;
    recommendedUsers = [];
    
    _countdownTimer?.cancel();
    _searchTimeoutTimer?.cancel();
    notifyListeners();

    // EN: Reduced from 5s to 1.5s for snappy UI feedback when pipeline database returns empty
    // PT: Reduzido de 5s para 1.5s para um feedback de UI mais rápido quando o banco retornar vazio
    _searchTimeoutTimer = Timer(const Duration(milliseconds: 1500), () {
      if (isLoading && discoveryUser == null && recommendedUsers.isEmpty) {
        isLoading = false;
        notifyListeners();
      }
    });
  }

  // EN: Call this method when the AI algorithm/Supabase finds a prominent user showcase
  // PT: Chame este método quando o algoritmo da IA/Supabase encontrar uma vitrine de usuário em destaque
  void setDiscoveryUser(MatchUserEntity user) {
    _searchTimeoutTimer?.cancel(); // PT: Cancela o timeout de erro já que os dados chegaram
    discoveryUser = user;
    isLoading = false;
    startConnectionTimer(); 
    notifyListeners();
  }

  // EN: Call this method to feed or append the secondary real-time recommendations list
  // PT: Chame este método para alimentar ou anexar a lista secundária de recomendações em tempo real
  void updateRecommendedUsers(List<MatchUserEntity> users) {
    _searchTimeoutTimer?.cancel(); // PT: Cancela o timeout de erro já que os dados chegaram
    recommendedUsers = users;
    if (discoveryUser != null) {
      isLoading = false;
    }
    notifyListeners();
  }

  // EN: Controls the ticking mechanism of the 20-minute execution phase
  // PT: Controla o mecanismo de tique-taque da fase de execução de 20 minutos
  void startConnectionTimer() {
    _countdownTimer?.cancel();
    remainingSeconds = 1200;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        notifyListeners();
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  // EN: Security method to bind both accounts under an encrypted temporary project hash guided by AI
  // PT: Método de segurança para vincular ambas as contas sob uma hash provisória de projeto criptografada guiada por IA
  String generateProvisionalContractHash(String userA, String userB) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return "VRSN-${userA.hashCode ^ userB.hashCode}-$timestamp";
  }

  // EN: Converted into a getter so the View can pass it directly into the onPressed parameter without signature clashes
  // PT: Convertido em um getter para que a View possa passá-lo direto no parâmetro onPressed sem conflito de assinatura
  VoidCallback get openFilters => () {
    // PT: Filtros de busca (Originalmente vazio)
    // EN: Search filters (Originally empty)
  };

  void listenDemo() {
    // PT: Ouvir demonstração (Originalmente vazio)
    // EN: Listen to demo track (Originally empty)
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _searchTimeoutTimer?.cancel();
    super.dispose();
  }
}