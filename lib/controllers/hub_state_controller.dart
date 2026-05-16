// lib/app/controllers/hub_state_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HubStateController extends ChangeNotifier {
  // Singleton para manter a mesma instância na memória
  static final HubStateController _instance = HubStateController._internal();
  factory HubStateController() => _instance;
  HubStateController._internal() {
    // Inicia a escuta do banco de dados assim que o controller nasce
    _initSupabaseStream();
  }

  // Instância do cliente Supabase
  final _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _streamSubscription;

  // Estados privados que o Frontend vai consumir
  bool _forceOffline = false;
  bool isDisconnecting = false;
  
  bool _isOnline = false;
  String _statusMessage = "Hardware desconectado";
  Color _statusColor = Colors.redAccent;

  // Getters Públicos para o Frontend (Interface Limpa)
  bool get forceOffline => _forceOffline;
  bool get isOnline => _isOnline;
  String get statusMessage => _statusMessage;
  Color get statusColor => _statusColor;

  // Setter da trava global
  set forceOffline(bool value) {
    if (_forceOffline != value) {
      _forceOffline = value;
      _updateState(statusReal: _isOnline ? 'online' : 'offline', forceUpdate: true);
    }
  }

  // Lógica de "Backend/Infraestrutura" isolada da UI
  void _initSupabaseStream() {
    _streamSubscription = _supabase
        .from('status_hardware')
        .stream(primaryKey: ['id'])
        .eq('id', 1)
        .listen((data) {
          if (data.isNotEmpty) {
            final dadosHardware = data.first;
            final String statusReal = dadosHardware['status'] ?? 'offline';
            final String? updatedAtStr = dadosHardware['updated_at']?.toString();
            
            _processHardwareLogic(statusReal, updatedAtStr);
          }
        }, onError: (error) {
          _isOnline = false;
          _statusMessage = "Erro na conexão com o servidor";
          _statusColor = Colors.redAccent;
          notifyListeners();
        });
  }

  // Processamento lógico e regras de fuso horário (Timezone)
  void _processHardwareLogic(String statusReal, String? updatedAtStr) {
    if (updatedAtStr == null) {
      _updateState(statusReal: statusReal, estaOnline: false, mensagem: "Sinal inválido");
      return;
    }

    // Blindagem de Timezone (UTC)
    String dateStr = updatedAtStr;
    if (!dateStr.endsWith('Z') && !dateStr.contains('+') && !dateStr.contains('-')) {
      dateStr += 'Z';
    }

    final DateTime updatedAt = DateTime.parse(dateStr).toUtc();
    final DateTime agoraUtc = DateTime.now().toUtc();
    final int diferencaSegundos = agoraUtc.difference(updatedAt).inSeconds.abs();

    // Validação da janela de 10 minutos (600 segundos)
    if (statusReal == 'online' && diferencaSegundos < 600) {
      _updateState(
        statusReal: statusReal,
        estaOnline: true,
        mensagem: "Hub conectado via Apolo-system",
      );
    } else {
      _updateState(
        statusReal: statusReal,
        estaOnline: false,
        mensagem: "Último sinal há $diferencaSegundos segundos",
      );
    }
  }

  // Centralizador de mudança de estado e notificação da UI
  void _updateState({
    required String statusReal,
    bool estaOnline = false,
    String mensagem = "Hardware desconectado",
    bool forceUpdate = false,
  }) {
    // Se a trava manual estiver ativa, aplica o curto-circuito independente do banco
    if (_forceOffline) {
      _isOnline = false;
      _statusMessage = "Hardware desconectado manualmente";
      _statusColor = Colors.redAccent;
    } else {
      _isOnline = estaOnline;
      _statusMessage = mensagem;
      _statusColor = estaOnline ? const Color(0xFF00FF66) : Colors.redAccent; // hackerGreen nativo aqui
    }
    
    // Avisa o Frontend que os dados mudaram
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel(); // Fecha o stream para evitar vazamento de memória
    super.dispose();
  }
}