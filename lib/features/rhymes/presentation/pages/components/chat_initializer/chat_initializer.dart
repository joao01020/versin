import 'dart:async';
import 'package:flutter/material.dart';
import 'package:versin/features/rhymes/presentation/widgets/structure_builder/structure_draggable_list.dart';

class ChatInitializer {
  static void run({
    required Function(bool) onLoadingStatusChanged,
    required Function() onStartWelcomeFlow,
    required bool mounted,
  }) {
    Timer(const Duration(seconds: 5), () {
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
      addMessage("Salve! Sou o Versin... 🎤");
      scrollToBottom();

      Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setAiTyping(false);
        
        // Agora o flow envia apenas a orientação textual
        addMessage(
          "Para começar, mande o sentimento que quer na letra",
        );
        
        // Atualiza o progresso para o ponto 2 (Expressão), pois não há mais o seletor
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
    
    addMessage(
      "Quarto ponto: Estrutura. Arraste para organizar ou use o '+' para novos blocos.",
      customWidget: StructureDraggableList(
        initialStructure: const ["Intro", "Verso 1", "Refrão", "Verso 2", "Refrão", "Ponte", "Final"],
        activeColor: activeColor,
        onStructureChanged: (newStructure) {
          onProgressUpdate(4, 1.0);
          Future.delayed(const Duration(seconds: 1), () => onProgressUpdate(5, 0.1));
        },
      ),
    );
    scrollToBottom();
  }
}