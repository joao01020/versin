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
  StudioWindowService._();

  static final StudioWindowService instance = StudioWindowService._();

  // ============================================================
  // WINDOWS
  // ============================================================

  WindowController? _lyricsWindow;

  WindowController? _mindMapWindow;

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
  // ABRIR LETRA
  // ============================================================

  Future<
    WindowController
  >
  openLyricsWindow({
    String? projectId,
  }) async {
    final existing = await _findExistingWindow(
      StudioWindowType.lyrics,
    );

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
    final existing = await _findExistingWindow(
      StudioWindowType.mindMap,
    );

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
    final window =
        _lyricsWindow ??
        await _findExistingWindow(
          StudioWindowType.lyrics,
        );

    if (window ==
        null) {
      return;
    }

    _lyricsWindow = window;

    await window.show();
  }

  // ============================================================
  // MOSTRAR MAPA
  // ============================================================

  Future<
    void
  >
  showMindMapWindow() async {
    final window =
        _mindMapWindow ??
        await _findExistingWindow(
          StudioWindowType.mindMap,
        );

    if (window ==
        null) {
      return;
    }

    _mindMapWindow = window;

    await window.show();
  }

  // ============================================================
  // OCULTAR LETRA
  // ============================================================

  Future<
    void
  >
  hideLyricsWindow() async {
    final window =
        _lyricsWindow ??
        await _findExistingWindow(
          StudioWindowType.lyrics,
        );

    if (window ==
        null) {
      return;
    }

    _lyricsWindow = window;

    await window.hide();
  }

  // ============================================================
  // OCULTAR MAPA
  // ============================================================

  Future<
    void
  >
  hideMindMapWindow() async {
    final window =
        _mindMapWindow ??
        await _findExistingWindow(
          StudioWindowType.mindMap,
        );

    if (window ==
        null) {
      return;
    }

    _mindMapWindow = window;

    await window.hide();
  }

  // ============================================================
  // ENCAIXAR LETRA
  // ============================================================
  //
  // Nesta primeira versão "encaixar" significa ocultar
  // a janela externa.
  //
  // Depois o StudioPage recebe a informação e volta a mostrar
  // o painel LETRA dentro do layout principal.
  //
  // ============================================================

  Future<
    void
  >
  dockLyricsWindow() async {
    await hideLyricsWindow();

    debugPrint(
      '[STUDIO WINDOW] Letra preparada para encaixar.',
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
      '[STUDIO WINDOW] Mapa preparado para encaixar.',
    );
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
    _lyricsWindow = await _findExistingWindow(
      StudioWindowType.lyrics,
    );

    _mindMapWindow = await _findExistingWindow(
      StudioWindowType.mindMap,
    );
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
}
