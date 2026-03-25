import 'package:flutter/material.dart';
import 'package:versin/features/rimas/presentation/controller/rimas_controller.dart';

class CommandHandler {
  final RimasController rimasController;
  final Function(String) onSystemMessage;
  final VoidCallback onClearChat;
  final Function({bool? rhyme, bool? compor, bool? listar, bool? marketing}) onUpdateModes;

  CommandHandler({
    required this.rimasController,
    required this.onSystemMessage,
    required this.onClearChat,
    required this.onUpdateModes,
  });

  /// Lista objetiva para o Menu Suspenso (Overlay)
  List<Map<String, String>> getCommands() {
    return [
      {"cmd": "/modorima", "desc": "Fonética e rimas"},
      {"cmd": "/modocompor", "desc": "Métrica e versos"},
      {"cmd": "/modolistar", "desc": "Vocabulário"},
      {"cmd": "/modomarketing", "desc": "Slogans e divulgação"},
      {"cmd": "/limparchat", "desc": "Limpa histórico"},
      {"cmd": "/desligarmodo", "desc": "Modo padrão"},
    ];
  }

  bool handle(String text) {
    final cleanText = text.trim().toLowerCase();

    if (cleanText == "/desligarmodo") {
      onUpdateModes(rhyme: false, compor: false, listar: false, marketing: false);
      onSystemMessage("> **MODO PADRÃO.**");
      return true;
    }

    if (cleanText == "/limparchat") {
      onClearChat();
      onSystemMessage("> **HISTÓRICO LIMPO.**");
      return true;
    }

    if (cleanText == "/modorima") {
      onUpdateModes(rhyme: true, compor: false, listar: false, marketing: false);
      onSystemMessage("> **MODO RIMA.**");
      return true;
    }

    if (cleanText == "/modocompor") {
      onUpdateModes(rhyme: false, compor: true, listar: false, marketing: false);
      onSystemMessage("> **MODO COMPOSIÇÃO.**");
      return true;
    }

    if (cleanText == "/modolistar") {
      onUpdateModes(rhyme: false, compor: false, listar: true, marketing: false);
      onSystemMessage("> **MODO LISTAGEM.**");
      return true;
    }

    if (cleanText == "/modomarketing") {
      onUpdateModes(rhyme: false, compor: false, listar: false, marketing: true);
      onSystemMessage("> **MODO MARKETING.**");
      return true;
    }

    if (cleanText.startsWith("/list")) {
      final content = text.replaceFirst(RegExp(r'/list', caseSensitive: false), "").trim();
      if (content.isNotEmpty) {
        final rimas = content.split(RegExp(r'[,,;]'));
        for (var rima in rimas) {
          if (rima.trim().isNotEmpty) rimasController.adicionarPalavra(rima.trim(), true);
        }
        onSystemMessage("> **${rimas.length} rimas adicionadas.**");
      }
      return true;
    }

    return false;
  }
}