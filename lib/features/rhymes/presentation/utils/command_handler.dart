import 'package:flutter/material.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

class CommandHandler {
  final RhymesController rhymesController; 
  final Function(String) onSystemMessage;
  final VoidCallback onClearChat;
  final Function({bool? rhyme, bool? compose, bool? list, bool? marketing}) onUpdateModes;

  CommandHandler({
    required this.rhymesController,
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

    // Desativar todos os modos ativos
    if (cleanText == "/desligarmodo") {
      onUpdateModes(rhyme: false, compose: false, list: false, marketing: false);
      onSystemMessage("> **MODO PADRÃO.**");
      return true;
    }

    // Limpar o histórico de mensagens
    if (cleanText == "/limparchat") {
      onClearChat();
      onSystemMessage("> **HISTÓRICO LIMPO.**");
      return true;
    }

    // Ativar Modo Rima
    if (cleanText == "/modorima") {
      onUpdateModes(rhyme: true, compose: false, list: false, marketing: false);
      onSystemMessage("> **MODO RIMA.**");
      return true;
    }

    // Ativar Modo Composição
    if (cleanText == "/modocompor") {
      onUpdateModes(rhyme: false, compose: true, list: false, marketing: false);
      onSystemMessage("> **MODO COMPOSIÇÃO.**");
      return true;
    }

    // Ativar Modo Listagem
    if (cleanText == "/modolistar") {
      onUpdateModes(rhyme: false, compose: false, list: true, marketing: false);
      onSystemMessage("> **MODO LISTAGEM.**");
      return true;
    }

    // Ativar Modo Marketing
    if (cleanText == "/modomarketing") {
      onUpdateModes(rhyme: false, compose: false, list: false, marketing: true);
      onSystemMessage("> **MODO MARKETING.**");
      return true;
    }

    // Adição rápida de rimas via comando /list
    if (cleanText.startsWith("/list")) {
      final content = text.replaceFirst(RegExp(r'/list', caseSensitive: false), "").trim();
      if (content.isNotEmpty) {
        final rhymes = content.split(RegExp(r'[,;]')); // Corrigido Regex de separação
        for (var rhyme in rhymes) {
          if (rhyme.trim().isNotEmpty) {
            // Chamando o método addWord (inglês) do novo RhymesController
            rhymesController.addWord(rhyme.trim(), true);
          }
        }
        onSystemMessage("> **${rhymes.length} rimas adicionadas.**");
      }
      return true;
    }

    return false;
  }
}