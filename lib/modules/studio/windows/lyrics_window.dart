import 'dart:async';
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

// ============================================================
// JANELA EXTERNA DA LETRA
// ============================================================

class LyricsWindow
    extends
        StatefulWidget {
  final String arguments;

  const LyricsWindow({
    super.key,
    required this.arguments,
  });

  @override
  State<
    LyricsWindow
  >
  createState() => _LyricsWindowState();
}

class _LyricsWindowState
    extends
        State<
          LyricsWindow
        >
    with
        WindowListener {
  // ============================================================
  // CANAL DE COMUNICAÇÃO ENTRE JANELAS
  // ============================================================

  static const WindowMethodChannel _channel = WindowMethodChannel(
    'versin_studio_lyrics',
    mode: ChannelMode.bidirectional,
  );

  // ============================================================
  // EDITOR
  // ============================================================

  late final TextEditingController _lyricsController;

  late final FocusNode _focusNode;

  // ============================================================
  // ESTADO
  // ============================================================

  String _projectId = '';

  bool _isUpdatingFromMainWindow = false;

  bool _isReady = false;

  bool _isSending = false;

  bool _isDocking = false;

  bool _windowManagerReady = false;

  int _characterCount = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final data = _parseArguments(
      widget.arguments,
    );

    _projectId =
        data['project_id']?.toString() ??
        '';

    final initialLyrics =
        data['lyrics']?.toString() ??
        '';

    _lyricsController = TextEditingController(
      text: initialLyrics,
    );

    _focusNode = FocusNode();

    _characterCount = initialLyrics.length;

    _lyricsController.addListener(
      _onLyricsChanged,
    );

    _configureChannel();

    _initializeNativeWindow();

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        setState(
          () {
            _isReady = true;
          },
        );

        _focusNode.requestFocus();
      },
    );
  }

  // ============================================================
  // WINDOW MANAGER
  // ============================================================

  Future<
    void
  >
  _initializeNativeWindow() async {
    try {
      await windowManager.ensureInitialized();

      if (!mounted) {
        return;
      }

      windowManager.addListener(
        this,
      );

      await windowManager.setPreventClose(
        true,
      );

      _windowManagerReady = true;

      debugPrint(
        '[LYRICS WINDOW] Fechamento nativo interceptado.',
      );
    } catch (
      e
    ) {
      debugPrint(
        '[LYRICS WINDOW] Erro ao inicializar window_manager: $e',
      );
    }
  }

  // ============================================================
  // X NATIVO
  // ============================================================

  @override
  void onWindowClose() {
    unawaited(
      _dockWindow(),
    );
  }

  // ============================================================
  // CONFIGURAR CANAL
  // ============================================================

  Future<
    void
  >
  _configureChannel() async {
    try {
      await _channel.setMethodCallHandler(
        (
          call,
        ) async {
          switch (call.method) {
            // ==================================================
            // RECEBER LETRA
            // ==================================================

            case 'setLyrics':
              final value =
                  call.arguments?.toString() ??
                  '';

              _updateLyricsFromMain(
                value,
              );

              return true;

            // ==================================================
            // RECEBER PROJETO
            // ==================================================

            case 'setProject':
              final arguments = call.arguments;

              if (arguments
                  is Map) {
                final map =
                    Map<
                      String,
                      dynamic
                    >.from(
                      arguments,
                    );

                _projectId =
                    map['project_id']?.toString() ??
                    '';

                final lyrics =
                    map['lyrics']?.toString() ??
                    '';

                _updateLyricsFromMain(
                  lyrics,
                );
              }

              return true;

            // ==================================================
            // FOCO
            // ==================================================

            case 'focusEditor':
              if (mounted) {
                _focusNode.requestFocus();
              }

              return true;

            default:
              return null;
          }
        },
      );
    } catch (
      e
    ) {
      debugPrint(
        '[LYRICS WINDOW] Erro ao configurar canal: $e',
      );
    }
  }

  // ============================================================
  // ALTERAÇÃO LOCAL DA LETRA
  // ============================================================

  void _onLyricsChanged() {
    _characterCount = _lyricsController.text.length;

    if (mounted) {
      setState(
        () {},
      );
    }

    if (_isUpdatingFromMainWindow) {
      return;
    }

    unawaited(
      _sendLyricsToMainWindow(),
    );
  }

  // ============================================================
  // ENVIAR LETRA PARA JANELA PRINCIPAL
  // ============================================================

  Future<
    void
  >
  _sendLyricsToMainWindow() async {
    if (_isSending) {
      return;
    }

    _isSending = true;

    try {
      await _channel.invokeMethod(
        'lyricsChanged',
        {
          'project_id': _projectId,
          'lyrics': _lyricsController.text,
        },
      );
    } catch (
      e
    ) {
      debugPrint(
        '[LYRICS WINDOW] Erro ao enviar letra: $e',
      );
    } finally {
      _isSending = false;
    }
  }

  // ============================================================
  // RECEBER ALTERAÇÃO DA JANELA PRINCIPAL
  // ============================================================

  void _updateLyricsFromMain(
    String value,
  ) {
    if (_lyricsController.text ==
        value) {
      return;
    }

    _isUpdatingFromMainWindow = true;

    final currentSelection = _lyricsController.selection;

    final safeOffset = currentSelection.baseOffset.clamp(
      0,
      value.length,
    );

    _lyricsController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(
        offset: safeOffset,
      ),
    );

    _characterCount = value.length;

    _isUpdatingFromMainWindow = false;

    if (mounted) {
      setState(
        () {},
      );
    }
  }

  // ============================================================
  // ENCAIXAR NOVAMENTE
  // ============================================================

  Future<
    void
  >
  _dockWindow() async {
    if (_isDocking) {
      return;
    }

    _isDocking = true;

    if (mounted) {
      setState(
        () {},
      );
    }

    try {
      await _sendLyricsToMainWindow();

      await _channel.invokeMethod(
        'dockLyrics',
        {
          'project_id': _projectId,
          'lyrics': _lyricsController.text,
        },
      );

      debugPrint(
        '[LYRICS WINDOW] Solicitação de encaixe enviada.',
      );
    } catch (
      e
    ) {
      debugPrint(
        '[LYRICS WINDOW] Erro ao encaixar janela: $e',
      );
    } finally {
      await Future<
        void
      >.delayed(
        const Duration(
          milliseconds: 200,
        ),
      );

      _isDocking = false;

      if (mounted) {
        setState(
          () {},
        );
      }
    }
  }

  // ============================================================
  // ARGUMENTOS
  // ============================================================

  Map<
    String,
    dynamic
  >
  _parseArguments(
    String raw,
  ) {
    if (raw.trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(
        raw,
      );

      if (decoded
          is Map<
            String,
            dynamic
          >) {
        return decoded;
      }

      if (decoded
          is Map) {
        return Map<
          String,
          dynamic
        >.from(
          decoded,
        );
      }

      return {};
    } catch (
      e
    ) {
      debugPrint(
        '[LYRICS WINDOW] Argumentos inválidos: $e',
      );

      return {};
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_windowManagerReady) {
      windowManager.removeListener(
        this,
      );
    }

    _lyricsController.removeListener(
      _onLyricsChanged,
    );

    _lyricsController.dispose();

    _focusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    const activeColor = Color(
      0xFFE100FF,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: const Color(
          0xFF0D0D0D,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // =================================================
              // HEADER
              // =================================================
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                decoration: const BoxDecoration(
                  color: Color(
                    0xFF111111,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white10,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: activeColor,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    const Text(
                      'LETRA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const Spacer(),

                    if (_projectId.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 10,
                        ),
                        child: Text(
                          _projectId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 9,
                          ),
                        ),
                      ),

                    Tooltip(
                      message: 'Encaixar no Studio',
                      child: IconButton(
                        onPressed: _isDocking
                            ? null
                            : () {
                                unawaited(
                                  _dockWindow(),
                                );
                              },
                        icon: Icon(
                          Icons.call_merge_rounded,
                          color: _isDocking
                              ? Colors.white24
                              : activeColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // =================================================
              // EDITOR
              // =================================================
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(
                    14,
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF111111,
                      ),
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: 0.06,
                        ),
                      ),
                    ),
                    child: _isReady
                        ? TextField(
                            controller: _lyricsController,
                            focusNode: _focusNode,
                            expands: true,
                            minLines: null,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.55,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Escreva sua letra...',
                              hintStyle: TextStyle(
                                color: Colors.white24,
                              ),
                              contentPadding: EdgeInsets.all(
                                18,
                              ),
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: activeColor,
                            ),
                          ),
                  ),
                ),
              ),

              // =================================================
              // STATUS
              // =================================================
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                decoration: const BoxDecoration(
                  color: Color(
                    0xFF111111,
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white10,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(
                          0xFF00FF66,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Text(
                      _isDocking
                          ? 'ENCAIXANDO...'
                          : 'SINCRONIZADO COM O STUDIO',
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '$_characterCount caracteres',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
