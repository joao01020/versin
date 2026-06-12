import 'package:flutter/material.dart';
import 'package:versin/modules/chat/domain/repositories/chat_repository.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/brain/controller/brain_controller.dart';

// --- MODEL IN-LINE ---
enum ChatRole {
  user,
  assistant,
}

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
  }) : timestamp =
           timestamp ??
           DateTime.now();

  factory ChatMessage.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return ChatMessage(
      role:
          json['role'] ==
              'user'
          ? ChatRole.user
          : ChatRole.assistant,
      content:
          json['content'] ??
          '',
      timestamp:
          json['timestamp'] !=
              null
          ? DateTime.parse(
              json['timestamp'],
            )
          : DateTime.now(),
    );
  }

  Map<
    String,
    dynamic
  >
  toJson() => {
    'role': role.name,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  bool get isUser =>
      role ==
      ChatRole.user;
}

// --- CHAT CONTROLLER ---

class ChatController
    extends
        ChangeNotifier {
  final ChatRepository repository;
  final RhymesController rhymesController;

  BrainController? get brain =>
      rhymesController
          is BrainController
      ? rhymesController
            as BrainController
      : null;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<
    ChatMessage
  >
  messages = [];
  bool isAiTyping = false;
  final bool isInitializing = false; // Corrigido para final conforme sugestão do linter
  String projectName = "SEM TÍTULO";
  String lastConfirmedStructure = "";
  int currentSuggestionIndex = 0;

  bool _isDisposed = false;

  ChatController({
    required this.repository,
    required this.rhymesController,
  });

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  // --- COMPATIBILITY METHODS ---

  void nextSuggestion() => updateSuggestionIndex(
    currentSuggestionIndex +
        1,
  );

  void previousSuggestion() => updateSuggestionIndex(
    currentSuggestionIndex -
        1,
  );

  Future<
    void
  >
  processMessage(
    String message,
  ) async {
    messageController.text = message;
    await sendMessage();
  }

  void sendStructureToChat(
    List<
      String
    >
    structure,
  ) {
    final structureText = structure.join(
      " - ",
    );
    messages.add(
      ChatMessage(
        role: ChatRole.assistant,
        content: "Estrutura definida: $structureText",
      ),
    );
    notifyListeners();
    _scrollToBottom();
  }

  // --- MESSAGES LOGIC ---

  Future<
    void
  >
  sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messages.add(
      ChatMessage(
        role: ChatRole.user,
        content: text,
      ),
    );
    messageController.clear();
    isAiTyping = true;
    notifyListeners();
    _scrollToBottom();

    try {
      final Map<
        String,
        String
      >
      aiResponse = await rhymesController.fetchAiResponse(
        text,
      );

      if (aiResponse.isNotEmpty &&
          aiResponse['content'] !=
              null) {
        messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content: aiResponse['content']!,
          ),
        );
      } else {
        messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content: "Resposta em branco.",
          ),
        );
      }
    } catch (
      e
    ) {
      messages.add(
        ChatMessage(
          role: ChatRole.assistant,
          content: "Erro de conexão.",
        ),
      );
    } finally {
      isAiTyping = false;
      notifyListeners();
      _scrollToBottom();
    }
  }

  // --- AUXILIARY LOGIC ---

  void addWordToText(
    String word,
  ) {
    messageController.text = "${messageController.text.trim()} $word ";
    notifyListeners();
  }

  void updateSuggestionIndex(
    int index,
  ) {
    final total = rhymesController.suggestions.length;
    if (total >
        0) {
      currentSuggestionIndex =
          index %
          total;
      if (currentSuggestionIndex <
          0)
        currentSuggestionIndex += total;
      notifyListeners();
    }
  }

  String getCurrentSuggestion() {
    final suggestions = rhymesController.suggestions;
    return suggestions.isNotEmpty
        ? suggestions[currentSuggestionIndex %
              suggestions.length]
        : "Métrica";
  }

  void saveStructure(
    String structure,
  ) {
    lastConfirmedStructure = structure;
    notifyListeners();
  }

  void toggleBpm() {
    rhymesController.isBpmPlaying = !rhymesController.isBpmPlaying;
    notifyListeners();
  }

  void editProjectName(
    BuildContext context,
  ) {
    final nameController = TextEditingController(
      text: projectName,
    );
    showDialog(
      context: context,
      builder:
          (
            context,
          ) => AlertDialog(
            title: const Text(
              "Nome do Projeto",
            ),
            content: TextField(
              controller: nameController,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                ),
                child: const Text(
                  "Cancelar",
                ),
              ),
              TextButton(
                onPressed: () {
                  projectName = nameController.text.trim();
                  notifyListeners();
                  Navigator.pop(
                    context,
                  );
                },
                child: const Text(
                  "Salvar",
                ),
              ),
            ],
          ),
    );
  }

  void showStudioQuickMenu(
    BuildContext context,
    String title,
    List<
      String
    >
    options,
    Function(
      String,
    )
    onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (
            context,
          ) => Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (
                    opt,
                  ) => ListTile(
                    title: Text(
                      opt,
                    ),
                    onTap: () {
                      onSelect(
                        opt,
                      );
                      Navigator.pop(
                        context,
                      );
                    },
                  ),
                )
                .toList(),
          ),
    );
  }

  // --- UTILITIES ---

  void _scrollToBottom() {
    if (_isDisposed) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(
              milliseconds: 300,
            ),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  Future<
    void
  >
  initChatSession(
    BuildContext context,
  ) async {
    if (messages.isEmpty) {
      messages.add(
        ChatMessage(
          role: ChatRole.assistant,
          content: "VERSIN GENESIS: Conexão estabelecida.",
        ),
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
