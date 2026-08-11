import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/app/my_app.dart';

import 'package:versin/core/services/sync_manager.dart';

import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';

import 'package:versin/modules/studio/controllers/studio_controller.dart';
import 'package:versin/modules/studio/services/studio_window_service.dart';
import 'package:versin/modules/studio/windows/lyrics_window.dart';
import 'package:versin/modules/studio/windows/mind_map_window.dart';

// ============================================================
// CANAIS ENTRE A JANELA PRINCIPAL E AS JANELAS DO STUDIO
// ============================================================
//
// Cada janela do desktop_multi_window roda em um Flutter Engine
// independente.
//
// Por isso o GetIt da janela principal NÃO é compartilhado com
// LyricsWindow e MindMapWindow.
//
// O StudioController principal continua sendo a fonte da verdade.
// As janelas externas recebem e enviam mudanças por estes canais.
//
// ============================================================

const WindowMethodChannel _lyricsChannel = WindowMethodChannel(
  'versin_studio_lyrics',
  mode: ChannelMode.bidirectional,
);

const WindowMethodChannel _mindMapChannel = WindowMethodChannel(
  'versin_studio_mind_map',
  mode: ChannelMode.bidirectional,
);

// ============================================================
// MAIN
// ============================================================

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // DESCOBRIR QUAL JANELA ESTE ENGINE REPRESENTA
  // ============================================================
  //
  // No Desktop:
  //
  // janela principal
  //      -> arguments vazio / tipo desconhecido
  //
  // janela da letra
  //      -> studio_lyrics
  //
  // janela do mapa
  //      -> studio_mind_map
  //
  // ============================================================

  if (_isDesktopPlatform) {
    final currentWindow = await WindowController.fromCurrentEngine();

    final windowType = StudioWindowArguments.getType(currentWindow.arguments);

    // ==========================================================
    // JANELA EXTERNA DA LETRA
    // ==========================================================

    if (windowType == StudioWindowType.lyrics) {
      runApp(LyricsWindow(arguments: currentWindow.arguments));

      return;
    }

    // ==========================================================
    // JANELA EXTERNA DO MAPA
    // ==========================================================

    if (windowType == StudioWindowType.mindMap) {
      runApp(MindMapWindow(arguments: currentWindow.arguments));

      return;
    }
  }

  // ============================================================
  // JANELA PRINCIPAL DO VERSIN
  // ============================================================

  await _initializeMainApplication();

  runApp(const MyApp());
}

// ============================================================
// DETECTAR DESKTOP
// ============================================================

bool get _isDesktopPlatform {
  if (kIsWeb) {
    return false;
  }

  return defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

// ============================================================
// INICIALIZAÇÃO DA APLICAÇÃO PRINCIPAL
// ============================================================

Future<void> _initializeMainApplication() async {
  // ============================================================
  // 0. URL WEB SEM #
  // ============================================================

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // ============================================================
  // 1. GETIT
  // ============================================================

  if (!GetIt.instance.isRegistered<DashboardController>()) {
    setupLocator();
  }

  // ============================================================
  // 2. SQFLITE FFI
  // ============================================================

  if (_isDesktopPlatform) {
    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;
  }

  // ============================================================
  // 3. VARIÁVEIS DE AMBIENTE
  // ============================================================

  await dotenv.load(fileName: '.env');

  // ============================================================
  // 4. SUPABASE
  // ============================================================

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  // ============================================================
  // 5. SINCRONIZAÇÃO OFFLINE
  // ============================================================

  SyncManager().watchConnection();

  // ============================================================
  // 6. COMUNICAÇÃO COM AS JANELAS EXTERNAS
  // ============================================================

  if (_isDesktopPlatform) {
    await _configureStudioWindowChannels();
  }
}

// ============================================================
// CONFIGURAR IPC DO STUDIO
// ============================================================

Future<void> _configureStudioWindowChannels() async {
  final studio = GetIt.I<StudioController>();

  // ============================================================
  // LETRA
  // ============================================================

  await _lyricsChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      // ======================================================
      // LETRA ALTERADA NA JANELA EXTERNA
      // ======================================================

      case 'lyricsChanged':
        final data = _asMap(call.arguments);

        final lyrics = data['lyrics']?.toString() ?? '';

        studio.setLyrics(lyrics);

        return true;

      // ======================================================
      // ENCAIXAR LETRA NOVAMENTE
      // ======================================================

      case 'dockLyrics':
        final data = _asMap(call.arguments);

        final lyrics = data['lyrics']?.toString();

        if (lyrics != null) {
          studio.setLyrics(lyrics);
        }

        studio.dockLyrics();

        await StudioWindowService.instance.dockLyricsWindow();

        return true;

      default:
        return null;
    }
  });

  // ============================================================
  // MAPA
  // ============================================================

  await _mindMapChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      // ======================================================
      // JANELA DO MAPA PEDIU O ESTADO MAIS RECENTE
      // ======================================================

      case 'requestMindMap':
        await _pushMindMapToExternalWindow(studio);

        return true;

      // ======================================================
      // SELECIONAR NÓ
      // ======================================================

      case 'selectMindMapNode':
        final data = _asMap(call.arguments);

        final rawNodeId = data['node_id'];

        studio.selectMindMapNode(
          rawNodeId == null ? null : rawNodeId.toString(),
        );

        return true;

      // ======================================================
      // MOVER NÓ
      // ======================================================

      case 'setMindMapNodePosition':
        final data = _asMap(call.arguments);

        final nodeId = data['node_id']?.toString() ?? '';

        final x = _asDouble(data['x']);

        final y = _asDouble(data['y']);

        if (nodeId.isNotEmpty) {
          studio.setMindMapNodePosition(nodeId, Offset(x, y));
        }

        return true;

      // ======================================================
      // REMOVER NÓ
      // ======================================================

      case 'removeMindMapNode':
        final data = _asMap(call.arguments);

        final nodeId = data['node_id']?.toString() ?? '';

        if (nodeId.isNotEmpty) {
          studio.removeMindMapNode(nodeId);
        }

        return true;

      // ======================================================
      // NÓ → TIMELINE
      // ======================================================

      case 'addMindMapNodeToTimeline':
        final data = _asMap(call.arguments);

        final nodeId = data['node_id']?.toString() ?? '';

        final text = data['text']?.toString() ?? '';

        bool added = false;

        if (nodeId.isNotEmpty) {
          added = studio.addNodeToTimeline(nodeId);
        }

        // Se por algum motivo o nó já não existir no
        // StudioController, ainda aproveitamos o texto recebido.
        if (!added && text.trim().isNotEmpty) {
          studio.addTimelineWord(text);
        }

        return true;

      // ======================================================
      // CONECTAR NÓS
      // ======================================================

      case 'connectMindMapNodes':
        final data = _asMap(call.arguments);

        final firstNodeId = data['first_node_id']?.toString() ?? '';

        final secondNodeId = data['second_node_id']?.toString() ?? '';

        if (firstNodeId.isNotEmpty && secondNodeId.isNotEmpty) {
          studio.connectMindMapNodes(firstNodeId, secondNodeId);
        }

        return true;

      // ======================================================
      // ENCAIXAR MAPA NOVAMENTE
      // ======================================================

      case 'dockMindMap':
        studio.dockMindMap();

        await StudioWindowService.instance.dockMindMapWindow();

        return true;

      default:
        return null;
    }
  });

  // ============================================================
  // MANTER AS JANELAS EXTERNAS ATUALIZADAS
  // ============================================================
  //
  // Quando o StudioController muda pela janela principal,
  // propagamos o estado para a janela externa.
  //
  // As janelas externas já evitam reenviar a mesma alteração
  // quando recebem uma sincronização.
  //
  // ============================================================

  studio.addListener(() {
    _pushStudioStateToExternalWindows(studio);
  });

  // ============================================================
  // QUANDO UMA NOVA JANELA É CRIADA
  // ============================================================
  //
  // Isso é especialmente importante porque o serviço pode criar
  // a janela somente com o tipo/projectId.
  //
  // Assim que ela aparece, enviamos LETRA e MAPA atuais.
  //
  // ============================================================

  onWindowsChanged.listen((_) {
    _pushStudioStateToExternalWindows(studio);
  });

  // Primeira tentativa de sincronização.
  await _pushStudioStateToExternalWindows(studio);
}

// ============================================================
// ENVIAR TODO O ESTADO EXTERNO
// ============================================================

Future<void> _pushStudioStateToExternalWindows(StudioController studio) async {
  await Future.wait([
    _pushLyricsToExternalWindow(studio),
    _pushMindMapToExternalWindow(studio),
  ]);
}

// ============================================================
// ENVIAR LETRA
// ============================================================

Future<void> _pushLyricsToExternalWindow(StudioController studio) async {
  try {
    await _lyricsChannel.invokeMethod('setProject', {
      'project_id': _studioProjectId(studio),
      'lyrics': studio.lyrics,
    });
  } catch (_) {
    // É normal falhar quando a janela da letra ainda não existe.
  }
}

// ============================================================
// ENVIAR MAPA
// ============================================================

Future<void> _pushMindMapToExternalWindow(StudioController studio) async {
  try {
    await _mindMapChannel.invokeMethod('setMindMap', {
      'project_id': _studioProjectId(studio),
      'nodes': studio.mindMapNodes
          .map(
            (node) => {
              'id': node.id,
              'text': node.text,
              'type': node.type.name,
              'x': node.x,
              'y': node.y,
              'connections': List<String>.from(node.connections),
            },
          )
          .toList(),
    });
  } catch (_) {
    // É normal falhar quando a janela do mapa ainda não existe.
  }
}

// ============================================================
// ID DO PROJETO
// ============================================================

String _studioProjectId(StudioController studio) {
  try {
    final data = studio.exportProject();

    final id = data['id']?.toString().trim();

    if (id != null && id.isNotEmpty) {
      return id;
    }
  } catch (_) {
    // fallback abaixo
  }

  return studio.title;
}

// ============================================================
// CONVERTER DYNAMIC → MAP
// ============================================================

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return {};
}

// ============================================================
// CONVERTER PARA DOUBLE
// ============================================================

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
