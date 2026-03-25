import 'dart:async';
import 'package:flutter/material.dart';

class ChatInitializer {
  static void run({
    required Function(bool) onLoadingStatusChanged,
    required Function() onStartWelcomeFlow,
    required bool mounted,
  }) {
    // Timer para remover o Card de boas-vindas inicial (Splash/Initializing)
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        onLoadingStatusChanged(false);
        onStartWelcomeFlow();
      }
    });
  }

  static void welcomeFlow({
    required List<Map<String, String>> messages,
    required Function(String) addMessage,
    required Function(bool) setAiTyping,
    required Function() scrollToBottom,
    required bool mounted,
  }) {
    if (messages.isNotEmpty) return;

    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      addMessage("Salve! Sou o Versin... 🎤");
      scrollToBottom();

      Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setAiTyping(false);
        addMessage("O que você está sentindo hoje? Vamos transformar em letra.");
        scrollToBottom();
      });
    });
  }
}