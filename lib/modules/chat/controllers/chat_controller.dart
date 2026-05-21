import 'package:flutter/material.dart';
import 'package:versin/modules/chat/domain/repositories/chat_repository.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

// --- MODEL IN-LINE (Evita problemas de caminhos e cache no compilador) ---

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

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] == 'user' ? ChatRole.user : ChatRole.assistant,
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  bool get isUser => role == ChatRole.user;
}

// --- CHAT CONTROLLER ---

class ChatController extends ChangeNotifier {
  final ChatRepository repository;
  final RhymesController rhymesController;
  
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  List<ChatMessage> messages = [];
  bool isAiTyping = false;
  bool isInitializing = false;
  String projectName = "SEM TÍTULO";
  String lastConfirmedStructure = "";
  int currentSuggestionIndex = 0;
  
  // Controle interno sênior para evitar memory leaks ao atualizar estados assíncronos
  bool _isDisposed = false;

  ChatController({
    required this.repository,
    required this.rhymesController,
  });

  // Evita chamadas de estado em componentes destruídos
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  // --- COMPATIBILITY METHODS ---

  void nextSuggestion() => updateSuggestionIndex(currentSuggestionIndex + 1);
  
  void previousSuggestion() => updateSuggestionIndex(currentSuggestionIndex - 1);

  Future<void> processMessage(String message) async {
    messageController.text = message;
    await sendMessage();
  }

  void sendStructureToChat(List<String> structure) {
    final structureText = structure.join(" - ");
    messages.add(ChatMessage(
      role: ChatRole.assistant, 
      content: "Estrutura definida: $structureText",
    ));
    notifyListeners();
    _scrollToBottom();
  }

  void showStudioQuickMenu(BuildContext context, String title, List<String> options, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15122C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              ...options.map((option) => ListTile(
                    title: Text(option, style: const TextStyle(color: Colors.white70)),
                    onTap: () {
                      onSelect(option);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void toggleBpm() {
    rhymesController.isBpmPlaying = !rhymesController.isBpmPlaying;
    notifyListeners();
  }

  // --- MESSAGES LOGIC (IA INTEGRADA) ---

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    // Adiciona entrada do usuário localmente na UI
    messages.add(ChatMessage(role: ChatRole.user, content: text));
    messageController.clear();
    isAiTyping = true;
    notifyListeners();
    _scrollToBottom();

    try {
      // SÊNIOR: Consome a engine estável do RhymesController, injetando chaves e contexto de estúdio (BPM/Vibe)
      final Map<String, String> aiResponse = await rhymesController.fetchAiResponse(text);
      
      if (aiResponse.isNotEmpty && aiResponse['content'] != null && aiResponse['content']!.isNotEmpty) {
        messages.add(ChatMessage(
          role: ChatRole.assistant,
          content: aiResponse['content']!,
        ));
      } else {
        messages.add(ChatMessage(
          role: ChatRole.assistant,
          content: "O sinal do estúdio VERSIN retornou uma resposta em branco.",
        ));
      }
    } catch (e) {
      messages.add(ChatMessage(
        role: ChatRole.assistant, 
        content: "Conexão instável com a rede Versin. Verifique os parâmetros do beat.",
      ));
    } finally {
      isAiTyping = false;
      notifyListeners();
      _scrollToBottom();
    }
  }

  // --- TEXT AND SUGGESTIONS LOGIC ---

  void addWordToText(String word) {
    final currentText = messageController.text;
    messageController.text = "$currentText $word ";
    messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: messageController.text.length),
    );
    notifyListeners();
  }

  void updateSuggestionIndex(int index) {
    currentSuggestionIndex = index;
    notifyListeners();
  }

  String getCurrentSuggestion() {
    final suggestions = rhymesController.suggestions;
    if (suggestions.isEmpty) return "Métrica";
    return suggestions[currentSuggestionIndex % suggestions.length];
  }

  // --- PROJECT LOGIC ---

  void saveStructure(String structure) {
    lastConfirmedStructure = structure;
    notifyListeners();
  }

  void editProjectName(BuildContext context) {
    final nameController = TextEditingController(text: projectName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF15122C),
        title: const Text("Nome do Projeto", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Insira o título", hintStyle: TextStyle(color: Colors.white30)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                projectName = nameController.text.trim();
                notifyListeners();
              }
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  // --- UTILITIES ---

  void _scrollToBottom() {
    if (_isDisposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> initChatSession(BuildContext context) async {
    if (messages.isNotEmpty) return; 

    isInitializing = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1200));

    messages.add(ChatMessage(
      role: ChatRole.assistant,
      content: "VERSIN GENESIS: Conexão estabelecida com o estúdio. "
    ));

    isInitializing = false;
    notifyListeners();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _isDisposed = true;
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}