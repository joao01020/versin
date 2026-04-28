import 'dart:async';
import 'package:flutter/material.dart';

class ChatInitializer {
  static void run({
    required Function(bool) onLoadingStatusChanged,
    required Function() onStartWelcomeFlow,
    required bool mounted,
  }) {
    // Reduzi um pouco o tempo para o app parecer mais ágil
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        onLoadingStatusChanged(false);
        onStartWelcomeFlow();
      }
    });
  }

  static void welcomeFlow({
    required List<Map<String, dynamic>> messages, 
    required Function(String, {Widget? customWidget}) addMessage, 
    required Function(bool) setAiTyping,
    required Function() scrollToBottom,
    required List<String> userRhymes, 
    required bool mounted,
    required Function(int, double) onProgressUpdate,
    required Function(String) onWordSelected, 
    required List<Map<String, dynamic>> globalTrendingWords,
  }) {
    if (messages.isNotEmpty) return;

    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      // Removido qualquer customWidget que pudesse injetar botões
      addMessage("Salve! Sou o Versin, seu mentor de composição. 🎤", customWidget: null);
      scrollToBottom();

      Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setAiTyping(false);
        
        // Texto limpo focado na imersão do usuário
        addMessage(
          "Para começar a arquitetar sua letra, mande o sentimento ou o tema que você tem em mente agora.",
          customWidget: null,
        );
        
        onProgressUpdate(2, 0.0);
        scrollToBottom();
      });
    });
  }

  static void startStructureStep({
    required Function(String, {Widget? customWidget}) addMessage,
    required Function(int, double) onProgressUpdate,
    required Function() scrollToBottom,
    required Color activeColor,
  }) {
    onProgressUpdate(4, 0.0);
    
    // CORREÇÃO FINAL: Removida a DraggableList que ocupava espaço e trazia o roxo.
    // O usuário agora define a estrutura por texto, mantendo o minimalismo.
    addMessage(
      "Ponto 4: Arquitetura. Como você visualiza a ordem? (Ex: Intro > Verso > Refrão). Digite sua sequência.",
      customWidget: null,
    );
    
    // Atualiza o progresso automaticamente para não travar a timeline
    onProgressUpdate(4, 1.0);
    Future.delayed(const Duration(milliseconds: 500), () => onProgressUpdate(5, 0.0));
    
    scrollToBottom();
  }
}