import 'package:flutter/material.dart';


enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final Widget? customWidget;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.customWidget,
  }) : timestamp = timestamp ?? DateTime.now();

  // Método helper para converter o JSON que vem da API para um objeto ChatMessage
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] == 'user' ? ChatRole.user : ChatRole.assistant,
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  // Facilita o envio de dados de volta para a API ou Supabase se necessário
  Map<String, dynamic> toJson() => {
        'role': role.name, // Converte o enum de volta para 'user' ou 'assistant'
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  // Facilita a verificação de quem enviou mantendo compatibilidade
  bool get isUser => role == ChatRole.user;
}