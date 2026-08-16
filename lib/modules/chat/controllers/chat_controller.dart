import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:versin/modules/chat/domain/repositories/chat_repository.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/brain/controller/brain_controller.dart';
import 'package:versin/modules/studio/controllers/studio_controller.dart';

enum ChatRole {
  user,
  assistant,
}

enum ChatCreationStage {
  imagination,
  writing,
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

class ChatController
    extends
        ChangeNotifier {
  final ChatRepository repository;
  final RhymesController rhymesController;

  late final StudioController studioController;

  // ============================================================
  // ÚLTIMO ESTADO SINCRONIZADO DO STUDIO
  // ============================================================
  //
  // Evita atualizações repetidas quando o próprio Chat altera o
  // StudioController e o listener global é disparado em seguida.
  //
  // ============================================================

  late String _lastStudioTitle;
  late int _lastStudioBpm;
  String? _lastStudioVibe;
  String? _lastStudioTechnique;

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

  // ============================================================
  // PROJETO COMPARTILHADO COM O STUDIO
  // ============================================================

  String get projectName => studioController.title;

  int get projectBpm => studioController.bpm;

  String get projectVibe =>
      studioController.vibe ??
      rhymesController.selectedVibe;

  String get projectTechnique =>
      studioController.technique ??
      rhymesController.selectedTechnique;

  String lastConfirmedStructure = '';

  int currentSuggestionIndex = 0;

  Timer? _creativeHelpTimer;

  bool _isDisposed = false;

  ChatController({
    required this.repository,
    required this.rhymesController,
  }) {
    // ==========================================================
    // STUDIO CONTROLLER GLOBAL
    // ==========================================================
    //
    // Chat e Studio usam exatamente a mesma instância.
    //
    // Se o Studio ainda não foi aberto, criamos o controller
    // aqui. Quando o Studio abrir depois, ele reutilizará esta
    // mesma instância pelo GetIt.
    //
    // ==========================================================

    if (!GetIt.I
        .isRegistered<
          StudioController
        >()) {
      GetIt.I.registerLazySingleton<
        StudioController
      >(
        () => StudioController(
          rhymesController: rhymesController,
        ),
      );
    }

    studioController =
        GetIt.I<
          StudioController
        >();

    // ==========================================================
    // ESTADO INICIAL DA SESSÃO
    // ==========================================================

    _lastStudioTitle = studioController.title;

    _lastStudioBpm = studioController.bpm;

    _lastStudioVibe = studioController.vibe;

    _lastStudioTechnique = studioController.technique;

    studioController.addListener(
      _onStudioChanged,
    );

    // ==========================================================
    // SINCRONIZAR CONFIGURAÇÃO DA IA
    // ==========================================================
    //
    // O Studio é a fonte do projeto.
    // O RhymesController continua recebendo os mesmos dados
    // porque BPM/vibe/técnica são usados nas requisições de IA.
    //
    // ==========================================================

    rhymesController.updateStudioConfig(
      bpm: studioController.bpm,
      vibe:
          studioController.vibe ??
          rhymesController.selectedVibe,
      technique:
          studioController.technique ??
          rhymesController.selectedTechnique,
    );
  }

  // ============================================================
  // ALTERAÇÃO VINDO DO STUDIO
  // ============================================================

  void _onStudioChanged() {
    if (_isDisposed) {
      return;
    }

    final currentTitle = studioController.title;

    final currentBpm = studioController.bpm;

    final currentVibe = studioController.vibe;

    final currentTechnique = studioController.technique;

    // ==========================================================
    // BPM
    // ==========================================================
    //
    // Se o BPM mudou diretamente no Studio, atualiza também o
    // RhymesController porque ele envia esse valor para a IA.
    //
    // ==========================================================

    if (currentBpm !=
        _lastStudioBpm) {
      _lastStudioBpm = currentBpm;

      rhymesController.updateStudioConfig(
        bpm: currentBpm,
      );
    }

    // ==========================================================
    // VIBE
    // ==========================================================

    if (currentVibe !=
        _lastStudioVibe) {
      _lastStudioVibe = currentVibe;

      if (currentVibe !=
              null &&
          currentVibe.trim().isNotEmpty) {
        rhymesController.updateStudioConfig(
          vibe: currentVibe,
        );
      }
    }

    // ==========================================================
    // TÉCNICA
    // ==========================================================

    if (currentTechnique !=
        _lastStudioTechnique) {
      _lastStudioTechnique = currentTechnique;

      if (currentTechnique !=
              null &&
          currentTechnique.trim().isNotEmpty) {
        rhymesController.updateStudioConfig(
          technique: currentTechnique,
        );
      }
    }

    // ==========================================================
    // TÍTULO
    // ==========================================================

    if (currentTitle !=
        _lastStudioTitle) {
      _lastStudioTitle = currentTitle;
    }

    notifyListeners();
  }

  // ============================================================
  // TÍTULO COMPARTILHADO
  // ============================================================

  void updateProjectName(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return;
    }

    _lastStudioTitle = normalized;

    studioController.updateTitle(
      normalized,
    );

    notifyListeners();
  }

  // ============================================================
  // BPM COMPARTILHADO
  // ============================================================

  void updateProjectBpm(
    int value,
  ) {
    if (value <=
        0) {
      return;
    }

    _lastStudioBpm = value;

    studioController.updateBpm(
      value,
    );

    rhymesController.updateStudioConfig(
      bpm: value,
    );

    notifyListeners();
  }

  // ============================================================
  // VIBE COMPARTILHADA
  // ============================================================

  void updateProjectVibe(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return;
    }

    _lastStudioVibe = normalized;

    studioController.updateVibe(
      normalized,
    );

    rhymesController.updateStudioConfig(
      vibe: normalized,
    );

    notifyListeners();
  }

  // ============================================================
  // TÉCNICA COMPARTILHADA
  // ============================================================

  void updateProjectTechnique(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return;
    }

    _lastStudioTechnique = normalized;

    studioController.updateTechnique(
      normalized,
    );

    rhymesController.updateStudioConfig(
      technique: normalized,
    );

    notifyListeners();
  }

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

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

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

  Future<
    void
  >
  processMessage(
    String message,
  ) async {
    messageController.text = message;

    await sendMessage();
  }

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

    if (creationStage ==
        ChatCreationStage.imagination) {
      await _processInitialImagination(
        text,
      );

      return;
    }

    await _sendToAi(
      text,
    );
  }

  Future<
    void
  >
  _processInitialImagination(
    String text,
  ) async {
    final brainController = brain;

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

  Future<
    void
  >
  _sendToAi(
    String text,
  ) async {
    final normalizedText = text.trim();

    if (normalizedText.isEmpty) {
      return;
    }

    isAiTyping = true;

    notifyListeners();

    _scrollToBottom();

    try {
      final response = await repository.fetchAiResponse(
        normalizedText,
      );

      rhymesController.applyAiResponseMetadata(
        response,
      );

      final content = response['content']?.toString().trim();

      if (content !=
              null &&
          content.isNotEmpty) {
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

      final usedVersinApi =
          response['used_versin_api'] ==
          true;

      final usedPrivateApi =
          response['used_private_api'] ==
          true;

      final provider = response['provider']?.toString().trim();

      final model = response['model']?.toString().trim();

      debugPrint(
        '[CHAT CONTROLLER] '
        'Resposta recebida.',
      );

      debugPrint(
        '[CHAT CONTROLLER] '
        'IA Versin: $usedVersinApi',
      );

      debugPrint(
        '[CHAT CONTROLLER] '
        'API privada: $usedPrivateApi',
      );

      if (provider !=
              null &&
          provider.isNotEmpty) {
        debugPrint(
          '[CHAT CONTROLLER] '
          'Provider: $provider',
        );
      }

      if (model !=
              null &&
          model.isNotEmpty) {
        debugPrint(
          '[CHAT CONTROLLER] '
          'Modelo: $model',
        );
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT CONTROLLER] '
        'Erro ao enviar mensagem: $error',
      );

      debugPrint(
        '[CHAT CONTROLLER] '
        'Stack trace: $stackTrace',
      );

      messages.add(
        ChatMessage(
          role: ChatRole.assistant,

          content: _buildAiErrorMessage(
            error,
          ),
        ),
      );
    } finally {
      isAiTyping = false;

      notifyListeners();

      _scrollToBottom();
    }
  }

  String _buildAiErrorMessage(
    Object error,
  ) {
    final normalized = error.toString().toLowerCase();

    if (normalized.contains(
      'unimplemented',
    )) {
      return 'A API privada está configurada, mas o cliente desse provedor ainda não foi conectado.';
    }

    if (normalized.contains(
          'timeout',
        ) ||
        normalized.contains(
          'timed out',
        )) {
      return 'A IA demorou demais para responder. Tente novamente.';
    }

    if (normalized.contains(
          '401',
        ) ||
        normalized.contains(
          'unauthorized',
        ) ||
        normalized.contains(
          'não autorizado',
        )) {
      return 'Não foi possível autenticar a API. Verifique a credencial configurada.';
    }

    if (normalized.contains(
          '429',
        ) ||
        normalized.contains(
          'quota',
        ) ||
        normalized.contains(
          'limite',
        )) {
      return 'O limite de uso da IA foi atingido ou o provedor recusou novas requisições.';
    }

    return 'Erro de conexão com a IA. Tente novamente.';
  }

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

  void toggleBpm() {
    rhymesController.isBpmPlaying = !rhymesController.isBpmPlaying;

    notifyListeners();
  }

  void editProjectName(
    BuildContext context,
  ) {
    String draftName = projectName;

    showDialog<
      void
    >(
      context: context,
      barrierDismissible: true,
      builder:
          (
            dialogContext,
          ) {
            return AlertDialog(
              backgroundColor: const Color(
                0xFF1A1A1A,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  18,
                ),
              ),
              title: const Text(
                'Nome do Projeto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: TextFormField(
                initialValue: projectName,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                cursorColor: const Color(
                  0xFFE100FF,
                ),
                textInputAction: TextInputAction.done,
                onChanged:
                    (
                      value,
                    ) {
                      draftName = value;
                    },
                onFieldSubmitted:
                    (
                      value,
                    ) {
                      final name = value.trim();

                      if (name.isEmpty) {
                        return;
                      }

                      updateProjectName(
                        name,
                      );

                      Navigator.of(
                        dialogContext,
                      ).pop();
                    },
                decoration: InputDecoration(
                  hintText: 'Nome da música',
                  hintStyle: const TextStyle(
                    color: Colors.white30,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(
                    alpha: 0.04,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                    borderSide: const BorderSide(
                      color: Color(
                        0xFFE100FF,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final name = draftName.trim();

                    if (name.isEmpty) {
                      return;
                    }

                    updateProjectName(
                      name,
                    );

                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFE100FF,
                    ),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
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

  Future<
    void
  >
  initChatSession(
    BuildContext context,
  ) async {
    if (messages.isNotEmpty) {
      return;
    }

    // ==========================================================
    // CARREGAR MEMÓRIA CRIATIVA
    // ==========================================================
    //
    // O vocabulário funciona como memória persistente da
    // composição. Se já existem palavras salvas, não faz sentido
    // voltar para a etapa inicial de imaginação.
    //
    // ==========================================================

    await rhymesController.carregarDadosUsuario();

    if (_isDisposed) {
      return;
    }

    final savedWords = rhymesController.vocabularyWords;

    // ==========================================================
    // RETOMAR TRABALHO EXISTENTE
    // ==========================================================

    if (savedWords.isNotEmpty) {
      creationStage = ChatCreationStage.writing;

      final preview = savedWords
          .take(
            5,
          )
          .join(
            ' • ',
          );

      final wordCount = savedWords.length;

      final wordLabel =
          wordCount ==
              1
          ? 'palavra salva'
          : 'palavras salvas';

      messages.add(
        ChatMessage(
          role: ChatRole.assistant,
          content:
              'Vamos voltar ao trabalho?\n\n'
              'Já temos $wordCount $wordLabel '
              'da sua composição.\n\n'
              '$preview\n\n'
              'O que posso te ajudar agora?',
        ),
      );

      notifyListeners();

      _scrollToBottom();

      return;
    }

    // ==========================================================
    // PRIMEIRO CONTATO
    // ==========================================================

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

  @override
  void dispose() {
    _isDisposed = true;

    studioController.removeListener(
      _onStudioChanged,
    );

    _creativeHelpTimer?.cancel();

    messageController.dispose();

    scrollController.dispose();

    super.dispose();
  }
}
