import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/chat/domain/repositories/chat_repository.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/brain/controller/brain_controller.dart';

// ============================================================
// PAPEL DA MENSAGEM
// ============================================================

enum ChatRole {
  user,
  assistant,
}

// ============================================================
// ETAPA DA CRIAÇÃO
// ============================================================

enum ChatCreationStage {
  imagination,
  writing,
}

// ============================================================
// MENSAGEM
// ============================================================

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
          json['content']?.toString() ??
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
  toJson() {
    return {
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isUser =>
      role ==
      ChatRole.user;
}

// ============================================================
// CHAT CONTROLLER
// ============================================================

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

  final List<
    ChatMessage
  >
  messages = [];

  ChatCreationStage creationStage = ChatCreationStage.imagination;

  bool isAiTyping = false;

  final bool isInitializing = false;

  String projectName = 'SEM TÍTULO';

  String lastConfirmedStructure = '';

  int currentSuggestionIndex = 0;

  Timer? _creativeHelpTimer;

  bool _isDisposed = false;

  ChatController({
    required this.repository,
    required this.rhymesController,
  });

  // ============================================================
  // PALAVRAS IGNORADAS NA EXTRAÇÃO INICIAL
  // ============================================================

  static const Set<
    String
  >
  _stopWords = {
    'a',
    'ao',
    'aos',
    'aquela',
    'aquele',
    'aqueles',
    'aquilo',
    'as',
    'até',
    'com',
    'como',
    'da',
    'das',
    'de',
    'dela',
    'dele',
    'deles',
    'depois',
    'do',
    'dos',
    'e',
    'ela',
    'ele',
    'eles',
    'em',
    'essa',
    'esse',
    'esta',
    'está',
    'estava',
    'este',
    'eu',
    'fica',
    'fico',
    'foi',
    'já',
    'lá',
    'mais',
    'mas',
    'me',
    'meu',
    'minha',
    'muito',
    'na',
    'nas',
    'no',
    'nos',
    'o',
    'os',
    'ou',
    'para',
    'pela',
    'pelo',
    'por',
    'porque',
    'que',
    'se',
    'sem',
    'só',
    'sou',
    'sua',
    'também',
    'tem',
    'tenho',
    'um',
    'uma',
    'vai',
    'vejo',
    'você',
  };

  // ============================================================
  // NOTIFY
  // ============================================================

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  // ============================================================
  // SUGESTÕES
  // ============================================================

  void nextSuggestion() {
    updateSuggestionIndex(
      currentSuggestionIndex +
          1,
    );
  }

  void previousSuggestion() {
    updateSuggestionIndex(
      currentSuggestionIndex -
          1,
    );
  }

  void updateSuggestionIndex(
    int index,
  ) {
    final total = rhymesController.suggestions.length;

    if (total ==
        0) {
      return;
    }

    currentSuggestionIndex =
        index %
        total;

    if (currentSuggestionIndex <
        0) {
      currentSuggestionIndex += total;
    }

    notifyListeners();
  }

  String getCurrentSuggestion() {
    final suggestions = rhymesController.suggestions;

    if (suggestions.isEmpty) {
      return 'Métrica';
    }

    return suggestions[currentSuggestionIndex %
        suggestions.length];
  }

  // ============================================================
  // PROCESSAR MENSAGEM EXTERNA
  // ============================================================

  Future<
    void
  >
  processMessage(
    String message,
  ) async {
    messageController.text = message;

    await sendMessage();
  }

  // ============================================================
  // ENVIO
  // ============================================================

  Future<
    void
  >
  sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    _cancelCreativeHelp();

    messages.add(
      ChatMessage(
        role: ChatRole.user,
        content: text,
      ),
    );

    messageController.clear();

    notifyListeners();

    _scrollToBottom();

    // ========================================================
    // PRIMEIRA ETAPA — IMAGINAÇÃO
    // NÃO CHAMA IA
    // ========================================================

    if (creationStage ==
        ChatCreationStage.imagination) {
      await _processInitialImagination(
        text,
      );

      return;
    }

    // ========================================================
    // ETAPA NORMAL — IA
    // ========================================================

    await _sendToAi(
      text,
    );
  }

  // ============================================================
  // PROCESSAR IMAGINAÇÃO INICIAL
  // ============================================================

  Future<
    void
  >
  _processInitialImagination(
    String text,
  ) async {
    final brainController = brain;

    // ========================================================
    // CAMINHO PRINCIPAL — BRAIN CONTROLLER + CREATIVE VISION
    // ========================================================

    if (brainController !=
        null) {
      final vision = brainController.analyzeCreativeInput(
        text,
      );

      final originalWords = vision.originalWords;

      final addedCount = await rhymesController.addWords(
        originalWords,
      );

      creationStage = ChatCreationStage.writing;

      if (vision.isEmpty) {
        messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content:
                'Ainda está bem aberto — e tudo bem.\n\n'
                'Joga mais algumas imagens, sensações ou palavras soltas. '
                'Não precisa rimar nem tentar encontrar um tema agora.',
          ),
        );

        notifyListeners();
        _scrollToBottom();

        return;
      }

      final originalText = originalWords.isNotEmpty
          ? originalWords.join(
              ' • ',
            )
          : '';

      final discoveries = brainController.creativeDiscoveries;

      final discoveriesText = discoveries.isNotEmpty
          ? discoveries
                .take(
                  6,
                )
                .join(
                  ' • ',
                )
          : '';

      final saveMessage =
          addedCount >
              0
          ? 'Guardei $addedCount palavra${addedCount == 1 ? '' : 's'} '
                'da sua visão na biblioteca.'
          : 'As palavras principais dessa visão já estavam na sua biblioteca.';

      final buffer = StringBuffer();

      buffer.writeln(
        'Estou começando a enxergar algo aqui.',
      );
      buffer.writeln();

      if (vision.summary.trim().isNotEmpty) {
        buffer.writeln(
          vision.summary.trim(),
        );
      }

      if (originalText.isNotEmpty) {
        buffer.writeln();
        buffer.writeln(
          'O que veio de você:',
        );
        buffer.writeln(
          originalText,
        );
      }

      if (discoveriesText.isNotEmpty) {
        buffer.writeln();
        buffer.writeln(
          'Alguns caminhos que apareceram:',
        );
        buffer.writeln(
          discoveriesText,
        );
      }

      buffer.writeln();
      buffer.writeln(
        saveMessage,
      );
      buffer.writeln();
      buffer.write(
        'Agora começa a escrever sem tentar fechar a música cedo demais. '
        'Use esses caminhos se eles fizerem sentido — ou quebra tudo e segue outro.',
      );

      messages.add(
        ChatMessage(
          role: ChatRole.assistant,
          content: buffer.toString(),
        ),
      );

      notifyListeners();
      _scrollToBottom();

      return;
    }

    // ========================================================
    // FALLBACK — CASO NÃO EXISTA BRAIN CONTROLLER
    // ========================================================

    final extractedWords = _extractCreativeWords(
      text,
    );

    final addedCount = await rhymesController.addWords(
      extractedWords,
    );

    creationStage = ChatCreationStage.writing;

    if (extractedWords.isEmpty) {
      messages.add(
        ChatMessage(
          role: ChatRole.assistant,
          content:
              'Entendi o caminho.\n\n'
              'Agora começa a transformar essa imagem em palavras. '
              'Não precisa se preocupar em rimar ainda.',
        ),
      );

      notifyListeners();
      _scrollToBottom();

      return;
    }

    final wordsText = extractedWords.join(
      ' • ',
    );

    final saveMessage =
        addedCount >
            0
        ? 'Guardei $addedCount palavra${addedCount == 1 ? '' : 's'} '
              'nova${addedCount == 1 ? '' : 's'} na sua biblioteca.'
        : 'Essas palavras já estavam na sua biblioteca.';

    messages.add(
      ChatMessage(
        role: ChatRole.assistant,
        content:
            'Peguei algumas palavras da sua ideia:\n\n'
            '$wordsText\n\n'
            '$saveMessage\n\n'
            'Agora começa a escrever. Você pode seguir essas palavras '
            'ou deixar a música puxar outro caminho.',
      ),
    );

    notifyListeners();
    _scrollToBottom();
  }

  // ============================================================
  // EXTRAÇÃO LOCAL
  // ============================================================

  List<
    String
  >
  _extractCreativeWords(
    String text,
  ) {
    final normalized = text.toLowerCase().replaceAll(
      RegExp(
        r'[^\p{L}\p{N}\s]',
        unicode: true,
      ),
      ' ',
    );

    final words = normalized.split(
      RegExp(
        r'\s+',
      ),
    );

    final extracted =
        <
          String
        >[];

    for (final rawWord in words) {
      final word = rawWord.trim();

      if (word.length <
          4) {
        continue;
      }

      if (_stopWords.contains(
        word,
      )) {
        continue;
      }

      if (extracted.contains(
        word,
      )) {
        continue;
      }

      extracted.add(
        word,
      );

      if (extracted.length >=
          8) {
        break;
      }
    }

    return extracted;
  }

  // ============================================================
  // ENVIO PARA IA
  // ============================================================

  Future<
    void
  >
  _sendToAi(
    String text,
  ) async {
    isAiTyping = true;

    notifyListeners();

    _scrollToBottom();

    try {
      final response = await rhymesController.fetchAiResponse(
        text,
      );

      final content = response['content'];

      if (content !=
              null &&
          content.trim().isNotEmpty) {
        messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content: content,
          ),
        );
      } else {
        messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content: 'Resposta em branco.',
          ),
        );
      }
    } catch (
      e
    ) {
      debugPrint(
        'Erro no ChatController: $e',
      );

      messages.add(
        ChatMessage(
          role: ChatRole.assistant,
          content: 'Erro de conexão.',
        ),
      );
    } finally {
      isAiTyping = false;

      notifyListeners();

      _scrollToBottom();
    }
  }

  // ============================================================
  // ESTRUTURA
  // ============================================================

  void sendStructureToChat(
    List<
      String
    >
    structure,
  ) {
    final structureText = structure.join(
      ' - ',
    );

    messages.add(
      ChatMessage(
        role: ChatRole.assistant,
        content: 'Estrutura definida: $structureText',
      ),
    );

    notifyListeners();

    _scrollToBottom();
  }

  void saveStructure(
    String structure,
  ) {
    lastConfirmedStructure = structure;

    notifyListeners();
  }

  // ============================================================
  // TEXTO
  // ============================================================

  void addWordToText(
    String word,
  ) {
    final current = messageController.text.trim();

    messageController.text = current.isEmpty
        ? '$word '
        : '$current $word ';

    messageController.selection = TextSelection.collapsed(
      offset: messageController.text.length,
    );

    notifyListeners();
  }

  // ============================================================
  // BPM
  // ============================================================

  void toggleBpm() {
    rhymesController.isBpmPlaying = !rhymesController.isBpmPlaying;

    notifyListeners();
  }

  // ============================================================
  // PROJETO
  // ============================================================

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
          ) {
            return AlertDialog(
              title: const Text(
                'Nome do Projeto',
              ),
              content: TextField(
                controller: nameController,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text(
                    'Cancelar',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();

                    if (name.isNotEmpty) {
                      projectName = name;
                    }

                    notifyListeners();

                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text(
                    'Salvar',
                  ),
                ),
              ],
            );
          },
    );
  }

  // ============================================================
  // MENU RÁPIDO
  // ============================================================

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
          ) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(
                      16,
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ...options.map(
                  (
                    option,
                  ) {
                    return ListTile(
                      title: Text(
                        option,
                      ),
                      onTap: () {
                        onSelect(
                          option,
                        );

                        Navigator.pop(
                          context,
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
    );
  }

  // ============================================================
  // INICIALIZAÇÃO
  // ============================================================

  Future<
    void
  >
  initChatSession(
    BuildContext context,
  ) async {
    if (messages.isNotEmpty) {
      return;
    }

    creationStage = ChatCreationStage.imagination;

    messages.add(
      ChatMessage(
        role: ChatRole.assistant,
        content:
            'O que você enxerga?\n\n'
            'Não precisa pensar em uma música ainda.\n'
            'Me diga a cena, sensação ou situação que está na sua cabeça.',
      ),
    );

    notifyListeners();

    _scrollToBottom();

    _startCreativeHelpTimer();
  }

  // ============================================================
  // AJUDA APÓS 30 SEGUNDOS
  // ============================================================

  void _startCreativeHelpTimer() {
    _creativeHelpTimer?.cancel();

    _creativeHelpTimer = Timer(
      const Duration(
        seconds: 30,
      ),
      () {
        if (_isDisposed) {
          return;
        }

        final userAlreadyAnswered = messages.any(
          (
            message,
          ) => message.isUser,
        );

        if (userAlreadyAnswered) {
          return;
        }

        messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content:
                'Travou?\n\n'
                'Pode jogar palavras soltas também.\n\n'
                'Não precisam rimar e nem fazer sentido ainda.\n\n'
                'Ex:\n'
                'madrugada • carro • chuva • mensagem • vazio',
          ),
        );

        notifyListeners();

        _scrollToBottom();
      },
    );
  }

  void _cancelCreativeHelp() {
    _creativeHelpTimer?.cancel();

    _creativeHelpTimer = null;
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    if (_isDisposed) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (_isDisposed ||
            !scrollController.hasClients) {
          return;
        }

        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _isDisposed = true;

    _creativeHelpTimer?.cancel();

    messageController.dispose();

    scrollController.dispose();

    super.dispose();
  }
}
