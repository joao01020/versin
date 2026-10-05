import 'dart:async';
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';

// ============================================================
// TIPOS DE JANELA DO STUDIO
// ============================================================

enum StudioWindowType {
  lyrics,
  mindMap,
}

// ============================================================
// ARGUMENTOS DAS JANELAS
// ============================================================

class StudioWindowArguments {
  static const String typeKey = 'type';

  static const String projectIdKey = 'project_id';

  static const String lyricsType = 'studio_lyrics';

  static const String mindMapType = 'studio_mind_map';

  // ============================================================
  // CRIAR JSON — LETRA
  // ============================================================

  static String lyrics({
    String? projectId,
  }) {
    return jsonEncode(
      {
        typeKey: lyricsType,
        if (projectId !=
            null)
          projectIdKey: projectId,
      },
    );
  }

  // ============================================================
  // CRIAR JSON — MAPA
  // ============================================================

  static String mindMap({
    String? projectId,
  }) {
    return jsonEncode(
      {
        typeKey: mindMapType,
        if (projectId !=
            null)
          projectIdKey: projectId,
      },
    );
  }

  // ============================================================
  // LER ARGUMENTOS
  // ============================================================

  static Map<
    String,
    dynamic
  >
  parse(
    String rawArguments,
  ) {
    if (rawArguments.trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(
        rawArguments,
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
        '[STUDIO WINDOW] Erro ao interpretar argumentos: $e',
      );

      return {};
    }
  }

  // ============================================================
  // DESCOBRIR TIPO
  // ============================================================

  static StudioWindowType? getType(
    String rawArguments,
  ) {
    final arguments = parse(
      rawArguments,
    );

    final type = arguments[typeKey];

    switch (type) {
      case lyricsType:
        return StudioWindowType.lyrics;

      case mindMapType:
        return StudioWindowType.mindMap;

      default:
        return null;
    }
  }

  // ============================================================
  // PROJECT ID
  // ============================================================

  static String? getProjectId(
    String rawArguments,
  ) {
    final arguments = parse(
      rawArguments,
    );

    final value = arguments[projectIdKey];

    if (value ==
        null) {
      return null;
    }

    return value.toString();
  }
}

// ============================================================
// SERVICE
// ============================================================

class StudioWindowService {
  StudioWindowService._() {
    _listenToWindowChanges();
  }

  static final StudioWindowService instance = StudioWindowService._();

  // ============================================================
  // WINDOWS
  // ============================================================

  WindowController? _lyricsWindow;

  WindowController? _mindMapWindow;

  // ============================================================
  // ESTADO
  // ============================================================

  StreamSubscription<
    void
  >?
  _windowsSubscription;

  bool _refreshing = false;

  bool _openingLyrics = false;

  bool _openingMindMap = false;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get hasLyricsWindow =>
      _lyricsWindow !=
      null;

  bool get hasMindMapWindow =>
      _mindMapWindow !=
      null;

  String? get lyricsWindowId => _lyricsWindow?.windowId;

  String? get mindMapWindowId => _mindMapWindow?.windowId;

  // ============================================================
  // ESCUTAR ALTERAÇÕES DAS JANELAS
  // ============================================================
  //
  // onWindowsChanged avisa quando uma janela é criada
  // ou destruída.
  //
  // Mesmo que normalmente usemos hide() ao encaixar,
  // isso protege o serviço caso uma janela seja encerrada
  // de outra forma.
  //
  // ============================================================

  void _listenToWindowChanges() {
    _windowsSubscription = onWindowsChanged.listen(
      (
        _,
      ) {
        unawaited(
          refreshWindows(),
        );
      },
      onError:
          (
            Object error,
            StackTrace stackTrace,
          ) {
            debugPrint(
              '[STUDIO WINDOW] Erro no monitor de janelas: $error',
            );
          },
    );
  }

  // ============================================================
  // ABRIR LETRA
  // ============================================================

  Future<
    WindowController
  >
  openLyricsWindow({
    String? projectId,
  }) async {
    if (_openingLyrics) {
      final existing = await _getLyricsWindow();

      if (existing !=
          null) {
        await existing.show();

        return existing;
      }
    }

    _openingLyrics = true;

    try {
      final existing = await _getLyricsWindow();

      if (existing !=
          null) {
        _lyricsWindow = existing;

        await existing.show();

        debugPrint(
          '[STUDIO WINDOW] Janela da letra reutilizada: '
          '${existing.windowId}',
        );

        return existing;
      }

      final controller = await WindowController.create(
        WindowConfiguration(
          hiddenAtLaunch: true,
          arguments: StudioWindowArguments.lyrics(
            projectId: projectId,
          ),
        ),
      );

      _lyricsWindow = controller;

      await controller.show();

      debugPrint(
        '[STUDIO WINDOW] Janela da letra criada: '
        '${controller.windowId}',
      );

      return controller;
    } finally {
      _openingLyrics = false;
    }
  }

  // ============================================================
  // ABRIR MAPA
  // ============================================================

  Future<
    WindowController
  >
  openMindMapWindow({
    String? projectId,
  }) async {
    if (_openingMindMap) {
      final existing = await _getMindMapWindow();

      if (existing !=
          null) {
        await existing.show();

        return existing;
      }
    }

    _openingMindMap = true;

    try {
      final existing = await _getMindMapWindow();

      if (existing !=
          null) {
        _mindMapWindow = existing;

        await existing.show();

        debugPrint(
          '[STUDIO WINDOW] Janela do mapa reutilizada: '
          '${existing.windowId}',
        );

        return existing;
      }

      final controller = await WindowController.create(
        WindowConfiguration(
          hiddenAtLaunch: true,
          arguments: StudioWindowArguments.mindMap(
            projectId: projectId,
          ),
        ),
      );

      _mindMapWindow = controller;

      await controller.show();

      debugPrint(
        '[STUDIO WINDOW] Janela do mapa criada: '
        '${controller.windowId}',
      );

      return controller;
    } finally {
      _openingMindMap = false;
    }
  }

  // ============================================================
  // ABRIR POR TIPO
  // ============================================================

  Future<
    WindowController
  >
  openWindow(
    StudioWindowType type, {
    String? projectId,
  }) {
    switch (type) {
      case StudioWindowType.lyrics:
        return openLyricsWindow(
          projectId: projectId,
        );

      case StudioWindowType.mindMap:
        return openMindMapWindow(
          projectId: projectId,
        );
    }
  }

  // ============================================================
  // MOSTRAR LETRA
  // ============================================================

  Future<
    void
  >
  showLyricsWindow() async {
    final window = await _getLyricsWindow();

    if (window ==
        null) {
      debugPrint(
        '[STUDIO WINDOW] Nenhuma janela da letra disponível para mostrar.',
      );

      return;
    }

    _lyricsWindow = window;

    try {
      await window.show();
    } catch (
      e
    ) {
      debugPrint(
        '[STUDIO WINDOW] Erro ao mostrar janela da letra: $e',
      );

      _lyricsWindow = null;

      rethrow;
    }
  }

  // ============================================================
  // MOSTRAR MAPA
  // ============================================================

  Future<
    void
  >
  showMindMapWindow() async {
    final window = await _getMindMapWindow();

    if (window ==
        null) {
      debugPrint(
        '[STUDIO WINDOW] Nenhuma janela do mapa disponível para mostrar.',
      );

      return;
    }

    _mindMapWindow = window;

    try {
      await window.show();
    } catch (
      e
    ) {
      debugPrint(
        '[STUDIO WINDOW] Erro ao mostrar janela do mapa: $e',
      );

      _mindMapWindow = null;

      rethrow;
    }
  }

  // ============================================================
  // OCULTAR LETRA
  // ============================================================

  Future<
    void
  >
  hideLyricsWindow() async {
    final window = await _getLyricsWindow();

    if (window ==
        null) {
      _lyricsWindow = null;

      return;
    }

    _lyricsWindow = window;

    try {
      await window.hide();

      debugPrint(
        '[STUDIO WINDOW] Janela da letra ocultada.',
      );
    } catch (
      e
    ) {
      debugPrint(
        '[STUDIO WINDOW] Erro ao ocultar janela da letra: $e',
      );

      _lyricsWindow = null;
    }
  }

  // ============================================================
  // OCULTAR MAPA
  // ============================================================

  Future<
    void
  >
  hideMindMapWindow() async {
    final window = await _getMindMapWindow();

    if (window ==
        null) {
      _mindMapWindow = null;

      return;
    }

    _mindMapWindow = window;

    try {
      await window.hide();

      debugPrint(
        '[STUDIO WINDOW] Janela do mapa ocultada.',
      );
    } catch (
      e
    ) {
      debugPrint(
        '[STUDIO WINDOW] Erro ao ocultar janela do mapa: $e',
      );

      _mindMapWindow = null;
    }
  }

  // ============================================================
  // ENCAIXAR LETRA
  // ============================================================
  //
  // "Encaixar" NÃO fecha a janela.
  //
  // Apenas:
  //
  // 1. oculta a janela externa;
  // 2. mantém o Flutter Engine vivo;
  // 3. deixa o StudioController mostrar LETRA novamente;
  // 4. permite reaproveitar a mesma janela no próximo detach.
  //
  // ============================================================

  Future<
    void
  >
  dockLyricsWindow() async {
    await hideLyricsWindow();

    debugPrint(
      '[STUDIO WINDOW] Letra encaixada no Studio.',
    );
  }

  // ============================================================
  // ENCAIXAR MAPA
  // ============================================================

  Future<
    void
  >
  dockMindMapWindow() async {
    await hideMindMapWindow();

    debugPrint(
      '[STUDIO WINDOW] Mapa encaixado no Studio.',
    );
  }

  // ============================================================
  // OBTER LETRA
  // ============================================================

  Future<
    WindowController?
  >
  _getLyricsWindow() async {
    final cached = _lyricsWindow;

    if (cached !=
        null) {
      final stillExists = await _windowExists(
        cached.windowId,
      );

      if (stillExists) {
        return cached;
      }

      _lyricsWindow = null;
    }

    final found = await _findExistingWindow(
      StudioWindowType.lyrics,
    );

    _lyricsWindow = found;

    return found;
  }

  // ============================================================
  // OBTER MAPA
  // ============================================================

  Future<
    WindowController?
  >
  _getMindMapWindow() async {
    final cached = _mindMapWindow;

    if (cached !=
        null) {
      final stillExists = await _windowExists(
        cached.windowId,
      );

      if (stillExists) {
        return cached;
      }

      _mindMapWindow = null;
    }

    final found = await _findExistingWindow(
      StudioWindowType.mindMap,
    );

    _mindMapWindow = found;

    return found;
  }

  // ============================================================
  // VERIFICAR SE JANELA AINDA EXISTE
  // ============================================================

  Future<
    bool
  >
  _windowExists(
    String windowId,
  ) async {
    try {
      final windows = await WindowController.getAll();

      return windows.any(
        (
          window,
        ) =>
            window.windowId ==
            windowId,
      );
    } catch (
      e
    ) {
      debugPrint(
        '[STUDIO WINDOW] Erro ao validar janela $windowId: $e',
      );

      return false;
    }
  }

  // ============================================================
  // PROCURAR JANELA EXISTENTE
  // ============================================================

  Future<
    WindowController?
  >
  _findExistingWindow(
    StudioWindowType type,
  ) async {
    try {
      final windows = await WindowController.getAll();

      for (final window in windows) {
        final windowType = StudioWindowArguments.getType(
          window.arguments,
        );

        if (windowType ==
            type) {
          return window;
        }
      }

      return null;
    } catch (
      e
    ) {
      debugPrint(
        '[STUDIO WINDOW] Erro ao procurar janela existente: $e',
      );

      return null;
    }
  }

  // ============================================================
  // ATUALIZAR REFERÊNCIAS
  // ============================================================

  Future<
    void
  >
  refreshWindows() async {
    if (_refreshing) {
      return;
    }

    _refreshing = true;

    try {
      final windows = await WindowController.getAll();

      WindowController? lyrics;

      WindowController? mindMap;

      for (final window in windows) {
        final type = StudioWindowArguments.getType(
          window.arguments,
        );

        switch (type) {
          case StudioWindowType.lyrics:
            lyrics ??= window;
            break;

          case StudioWindowType.mindMap:
            mindMap ??= window;
            break;

          case null:
            break;
        }
      }

      _lyricsWindow = lyrics;

      _mindMapWindow = mindMap;
    } catch (
      e
    ) {
      debugPrint(
        '[STUDIO WINDOW] Erro ao atualizar referências: $e',
      );
    } finally {
      _refreshing = false;
    }
  }

  // ============================================================
  // LIMPAR REFERÊNCIA
  // ============================================================

  void clearLyricsReference() {
    _lyricsWindow = null;
  }

  void clearMindMapReference() {
    _mindMapWindow = null;
  }

  void clearReferences() {
    _lyricsWindow = null;

    _mindMapWindow = null;
  }

  // ============================================================
  // DISPOSE DO SERVICE
  // ============================================================
  //
  // Normalmente este singleton vive durante toda a aplicação.
  // O método existe para testes ou encerramento controlado.
  //
  // ============================================================

  Future<
    void
  >
  dispose() async {
    await _windowsSubscription?.cancel();

    _windowsSubscription = null;

    clearReferences();
  }
}
