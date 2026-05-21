import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SearchState { idle, searching, found, notFound }

class HubTelemetryController {
  final SupabaseClient _client = Supabase.instance.client;

  // Notificadores de Estado Reativos (Nativos)
  final ValueNotifier<SearchState> searchState = ValueNotifier<SearchState>(SearchState.idle);
  final ValueNotifier<bool> isGlobalSearching = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isScanning = ValueNotifier<bool>(false);
  final ValueNotifier<bool> revealHardwareKey = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasRevealedOnce = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isDisconnecting = ValueNotifier<bool>(false);
  final ValueNotifier<bool> forceOffline = ValueNotifier<bool>(false);

  Timer? _searchTimeoutTimer;
  late AnimationController globalSearchController;
  late AnimationController barramentoScanController;

  /// Inicializa os controladores de animação vinculados ao ciclo da View
  void initControllers({required TickerProvider vsync}) {
    globalSearchController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 3),
    );

    barramentoScanController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 15),
    );

    barramentoScanController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        isScanning.value = false;
      }
    });
  }

  /// Retorna o fluxo contínuo do banco de dados em tempo real
  Stream<List<Map<String, dynamic>>> get hardwareStream {
    return _client
        .from('status_hardware')
        .stream(primaryKey: ['id'])
        .eq('id', 1);
  }

  /// Dispara a busca ativa simulando os broadcasts UDP/HTTP para o chassi
  void startActiveHardwareSearch(bool estaOnlineAgora) {
    if (searchState.value == SearchState.searching) return;
    _searchTimeoutTimer?.cancel();

    searchState.value = SearchState.searching;
    isGlobalSearching.value = true;
    globalSearchController.repeat();

    _searchTimeoutTimer = Timer(const Duration(seconds: 3), () {
      isGlobalSearching.value = false;
      globalSearchController.stop();

      if (estaOnlineAgora && !forceOffline.value) {
        searchState.value = SearchState.found;
      } else {
        searchState.value = SearchState.notFound;
      }

      _searchTimeoutTimer = Timer(const Duration(seconds: 4), () {
        searchState.value = SearchState.idle;
      });
    });
  }

  /// Cancela a varredura ativa de rádio e reseta ponteiros
  void cancelActiveSearch() {
    _searchTimeoutTimer?.cancel();
    searchState.value = SearchState.idle;
    isGlobalSearching.value = false;
    globalSearchController.stop();
  }

  /// Ativa/Desativa o scan geométrico dos pinos I/O do chassi
  void toggleScan() {
    isScanning.value = !isScanning.value;
    if (isScanning.value) {
      barramentoScanController.forward(from: 0.0);
    } else {
      barramentoScanController.stop();
    }
  }

  /// Revela a assinatura anti-tamper encriptada na placa
  void revealKey() {
    if (!hasRevealedOnce.value) {
      revealHardwareKey.value = true;
      hasRevealedOnce.value = true;
    }
  }

  /// Ponto de entrada público para o botão "FORÇAR OFFLINE" (Solução 2)
  void triggerManualDisconnect() {
    // Interrompe imediatamente animações de varredura ativas
    if (isScanning.value) {
      toggleScan();
    }
    cancelActiveSearch();
    
    // Dispara a mutação remota no Supabase em segundo plano
    disconnectHardware();
    
    debugPrint("Apolo-system: Barramento local desconectado manualmente pelo usuário.");
  }

  /// Força a desconexão lógica gravando o estado offline no Supabase
  Future<void> disconnectHardware() async {
    if (isDisconnecting.value) return;

    isDisconnecting.value = true;
    forceOffline.value = true;

    try {
      await _client
          .from('status_hardware')
          .update({
            'status': 'offline',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', 1);
    } catch (e) {
      debugPrint("Erro ao desconectar hardware no Supabase: $e");
      // Mantém em modo offline local por segurança mesmo com falha de rede
    } finally {
      isDisconnecting.value = false;
    }
  }

  /// Desaloca a memória de timers e controladores de animação
  void dispose() {
    _searchTimeoutTimer?.cancel();
    globalSearchController.dispose();
    barramentoScanController.dispose();
    searchState.dispose();
    isGlobalSearching.dispose();
    isScanning.dispose();
    revealHardwareKey.dispose();
    hasRevealedOnce.dispose();
    isDisconnecting.dispose();
    forceOffline.dispose();
  }
}