import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/creative_production_month.dart';

// ============================================================
// CREATIVE ACTIVITY EVENT TYPE
// ============================================================
//
// Mantém os nomes dos eventos centralizados.
//
// Esses valores precisam permanecer sincronizados com:
//
// public.creative_activity_events.event_type
//
// e com a RPC:
//
// record_creative_activity_event()
//
// ============================================================

enum CreativeActivityEventType {
  projectCreated('project_created'),

  compositionSession('composition_session'),

  taskCompleted('task_completed'),

  collaborationStarted('collaboration_started'),

  fileAdded('file_added');

  final String value;

  const CreativeActivityEventType(this.value);
}

// ============================================================
// CREATIVE ACTIVITY SERVICE
// ============================================================
//
// Responsável exclusivamente pela comunicação com o Supabase
// para o sistema de produção criativa.
//
// RESPONSABILIDADES:
//
// - registrar eventos de atividade;
// - consultar o resumo mensal;
// - normalizar a resposta da RPC.
//
// NÃO:
//
// - calcula score;
// - conhece widgets;
// - gerencia loading da interface;
// - decide pesos;
// - calcula crescimento percentual.
//
// Essas responsabilidades ficam em:
//
// CreativeProductionService
// CreativeProductionController
//
// ============================================================

class CreativeActivityService {
  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase;

  // ==========================================================
  // RPC
  // ==========================================================

  static const String _recordEventRpc = 'record_creative_activity_event';

  static const String _monthlyActivityRpc = 'get_creative_activity_monthly';

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  CreativeActivityService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  User? get currentUser {
    return _supabase.auth.currentUser;
  }

  // ==========================================================
  // USER ID
  // ==========================================================

  String? get currentUserId {
    final userId = currentUser?.id.trim();

    if (userId == null || userId.isEmpty) {
      return null;
    }

    return userId;
  }

  // ==========================================================
  // AUTHENTICATED
  // ==========================================================

  bool get isAuthenticated {
    return currentUserId != null;
  }

  // ==========================================================
  // REGISTRAR EVENTO
  // ==========================================================
  //
  // user_id NÃO é enviado.
  //
  // A RPC utiliza:
  //
  // auth.uid()
  //
  // vindo do JWT Supabase.
  //
  // Isso impede o cliente de registrar um evento em nome de
  // outro usuário.
  //
  // sourceId deve ser usado sempre que houver uma entidade
  // persistente relacionada.
  //
  // Exemplos:
  //
  // taskCompleted
  // sourceId = taskId
  //
  // projectCreated
  // sourceId = projectId
  //
  // fileAdded
  // sourceId = storedWorkId
  //
  // ==========================================================

  Future<String> recordEvent({
    required CreativeActivityEventType eventType,
    String? projectId,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) async {
    // ========================================================
    // AUTH
    // ========================================================

    final userId = currentUserId;

    if (userId == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    // ========================================================
    // NORMALIZAÇÃO
    // ========================================================

    final normalizedProjectId = _normalizeOptionalString(projectId);

    final normalizedSourceId = _normalizeOptionalString(sourceId);

    final normalizedMetadata = _normalizeMetadata(metadata);

    // ========================================================
    // LOG
    // ========================================================

    debugPrint(
      '[CREATIVE ACTIVITY] '
      'Registrando evento: '
      '${eventType.value}',
    );

    debugPrint(
      '[CREATIVE ACTIVITY] '
      'User ID: $userId',
    );

    if (normalizedProjectId != null) {
      debugPrint(
        '[CREATIVE ACTIVITY] '
        'Project ID: $normalizedProjectId',
      );
    }

    if (normalizedSourceId != null) {
      debugPrint(
        '[CREATIVE ACTIVITY] '
        'Source ID: $normalizedSourceId',
      );
    }

    try {
      // ======================================================
      // RPC
      // ======================================================

      final response = await _supabase.rpc(
        _recordEventRpc,
        params: <String, dynamic>{
          'p_event_type': eventType.value,

          'p_project_id': normalizedProjectId,

          'p_source_id': normalizedSourceId,

          'p_metadata': normalizedMetadata,
        },
      );

      // ======================================================
      // RESPONSE
      // ======================================================

      final eventId = response?.toString().trim();

      if (eventId == null || eventId.isEmpty) {
        throw StateError('O Supabase não retornou o ID do evento criativo.');
      }

      debugPrint(
        '[CREATIVE ACTIVITY] '
        'Evento registrado: $eventId',
      );

      return eventId;
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[CREATIVE ACTIVITY] '
        'Erro Supabase ao registrar evento: '
        '${error.message}',
      );

      debugPrint(
        '[CREATIVE ACTIVITY] '
        'Código: ${error.code}',
      );

      debugPrint('$stackTrace');

      rethrow;
    } on AuthException catch (error, stackTrace) {
      debugPrint(
        '[CREATIVE ACTIVITY] '
        'Erro de autenticação: '
        '${error.message}',
      );

      debugPrint('$stackTrace');

      rethrow;
    } catch (error, stackTrace) {
      debugPrint(
        '[CREATIVE ACTIVITY] '
        'Erro inesperado ao registrar evento: '
        '$error',
      );

      debugPrint('$stackTrace');

      rethrow;
    }
  }

  // ==========================================================
  // REGISTRAR PROJETO CRIADO
  // ==========================================================

  Future<String> recordProjectCreated({
    required String projectId,
    Map<String, dynamic>? metadata,
  }) {
    return recordEvent(
      eventType: CreativeActivityEventType.projectCreated,
      projectId: projectId,
      sourceId: projectId,
      metadata: metadata,
    );
  }

  // ==========================================================
  // REGISTRAR SESSÃO DE COMPOSIÇÃO
  // ==========================================================
  //
  // sessionId deve ser único para cada sessão.
  //
  // Futuramente podemos colocar em metadata:
  //
  // duration_seconds
  // words_written
  // project_title
  //
  // ==========================================================

  Future<String> recordCompositionSession({
    required String sessionId,
    String? projectId,
    Map<String, dynamic>? metadata,
  }) {
    return recordEvent(
      eventType: CreativeActivityEventType.compositionSession,
      projectId: projectId,
      sourceId: sessionId,
      metadata: metadata,
    );
  }

  // ==========================================================
  // REGISTRAR TAREFA CONCLUÍDA
  // ==========================================================

  Future<String> recordTaskCompleted({
    required String taskId,
    String? projectId,
    Map<String, dynamic>? metadata,
  }) {
    return recordEvent(
      eventType: CreativeActivityEventType.taskCompleted,
      projectId: projectId,
      sourceId: taskId,
      metadata: metadata,
    );
  }

  // ==========================================================
  // REGISTRAR COLABORAÇÃO
  // ==========================================================
  //
  // sourceId deve preferencialmente ser:
  //
  // invitationId
  //
  // ou algum ID persistente referente à colaboração.
  //
  // ==========================================================

  Future<String> recordCollaborationStarted({
    required String sourceId,
    String? projectId,
    Map<String, dynamic>? metadata,
  }) {
    return recordEvent(
      eventType: CreativeActivityEventType.collaborationStarted,
      projectId: projectId,
      sourceId: sourceId,
      metadata: metadata,
    );
  }

  // ==========================================================
  // REGISTRAR ARQUIVO ADICIONADO
  // ==========================================================

  Future<String> recordFileAdded({
    required String fileId,
    String? projectId,
    Map<String, dynamic>? metadata,
  }) {
    return recordEvent(
      eventType: CreativeActivityEventType.fileAdded,
      projectId: projectId,
      sourceId: fileId,
      metadata: metadata,
    );
  }

  // ==========================================================
  // BUSCAR PRODUÇÃO MENSAL
  // ==========================================================
  //
  // A RPC retorna todos os meses solicitados, inclusive aqueles
  // em que não houve atividade.
  //
  // Ordem esperada:
  //
  // mês mais antigo
  // ↓
  // mês atual
  //
  // ==========================================================

  Future<List<CreativeProductionMonth>> fetchMonthlyActivity({
    int months = 12,
  }) async {
    // ========================================================
    // AUTH
    // ========================================================

    final userId = currentUserId;

    if (userId == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    // ========================================================
    // NORMALIZAR PERÍODO
    // ========================================================
    //
    // Mantemos a mesma faixa aceita pela RPC:
    //
    // 1..24
    //
    // ========================================================

    final normalizedMonths = months.clamp(1, 24);

    debugPrint(
      '[CREATIVE ACTIVITY] '
      'Buscando atividade dos últimos '
      '$normalizedMonths meses.',
    );

    debugPrint(
      '[CREATIVE ACTIVITY] '
      'User ID: $userId',
    );

    try {
      // ======================================================
      // RPC
      // ======================================================

      final response = await _supabase.rpc(
        _monthlyActivityRpc,
        params: <String, dynamic>{'p_months': normalizedMonths},
      );

      // ======================================================
      // DEBUG — RESPOSTA BRUTA DA RPC
      // ======================================================
      //
      // Temporário para diagnosticar o fluxo:
      //
      // Supabase
      //   ↓
      // CreativeActivityService
      //   ↓
      // CreativeProductionMonth
      //
      // ======================================================

      debugPrint(
        '[CREATIVE ACTIVITY] '
        '===============================',
      );

      debugPrint(
        '[CREATIVE ACTIVITY] '
        'RAW RPC RESPONSE:',
      );

      debugPrint(response.toString());

      debugPrint(
        '[CREATIVE ACTIVITY] '
        '===============================',
      );

      // ======================================================
      // NORMALIZAR RESPONSE
      // ======================================================

      final rows = _normalizeRows(response);

      if (rows.isEmpty) {
        debugPrint(
          '[CREATIVE ACTIVITY] '
          'RPC mensal retornou lista vazia.',
        );

        return const <CreativeProductionMonth>[];
      }

      // ======================================================
      // MAPEAR
      // ======================================================

      final monthsData = rows
          .map(CreativeProductionMonth.fromMap)
          .toList(growable: false);

      // ======================================================
      // DEBUG — DADOS MAPEADOS
      // ======================================================
      //
      // Mostra exatamente o que o model recebeu da RPC.
      //
      // ======================================================

      for (final month in monthsData) {
        debugPrint(
          '[CREATIVE ACTIVITY] '
          '${month.month.year}-'
          '${month.month.month.toString().padLeft(2, '0')} | '
          'projects=${month.projectsCreated} | '
          'sessions=${month.compositionSessions} | '
          'tasks=${month.tasksCompleted} | '
          'collabs=${month.collaborationsStarted} | '
          'files=${month.filesAdded}',
        );
      }

      // ======================================================
      // ORDENAR
      // ======================================================
      //
      // Defesa adicional mesmo que a RPC já retorne ASC.
      //
      // ======================================================

      final sorted = List<CreativeProductionMonth>.from(monthsData)
        ..sort((a, b) {
          return a.month.compareTo(b.month);
        });

      debugPrint(
        '[CREATIVE ACTIVITY] '
        '${sorted.length} mês(es) recebido(s).',
      );

      return List<CreativeProductionMonth>.unmodifiable(sorted);
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[CREATIVE ACTIVITY] '
        'Erro Supabase ao consultar produção mensal: '
        '${error.message}',
      );

      debugPrint(
        '[CREATIVE ACTIVITY] '
        'Código: ${error.code}',
      );

      debugPrint('$stackTrace');

      rethrow;
    } on AuthException catch (error, stackTrace) {
      debugPrint(
        '[CREATIVE ACTIVITY] '
        'Erro de autenticação ao consultar produção: '
        '${error.message}',
      );

      debugPrint('$stackTrace');

      rethrow;
    } catch (error, stackTrace) {
      debugPrint(
        '[CREATIVE ACTIVITY] '
        'Erro inesperado ao consultar produção mensal: '
        '$error',
      );

      debugPrint('$stackTrace');

      rethrow;
    }
  }

  // ==========================================================
  // NORMALIZAR ROWS
  // ==========================================================

  static List<Map<String, dynamic>> _normalizeRows(dynamic response) {
    if (response == null) {
      return const <Map<String, dynamic>>[];
    }

    // ========================================================
    // LIST
    // ========================================================

    if (response is List) {
      final rows = <Map<String, dynamic>>[];

      for (final item in response) {
        if (item is Map<String, dynamic>) {
          rows.add(item);

          continue;
        }

        if (item is Map) {
          rows.add(Map<String, dynamic>.from(item));
        }
      }

      return rows;
    }

    // ========================================================
    // MAP ÚNICO
    // ========================================================
    //
    // Não é esperado atualmente, mas mantemos compatibilidade.
    //
    // ========================================================

    if (response is Map<String, dynamic>) {
      return <Map<String, dynamic>>[response];
    }

    if (response is Map) {
      return <Map<String, dynamic>>[Map<String, dynamic>.from(response)];
    }

    throw StateError(
      'Formato inesperado retornado pela RPC de produção criativa.',
    );
  }

  // ==========================================================
  // NORMALIZAR STRING OPCIONAL
  // ==========================================================

  static String? _normalizeOptionalString(String? value) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ==========================================================
  // NORMALIZAR METADATA
  // ==========================================================

  static Map<String, dynamic> _normalizeMetadata(
    Map<String, dynamic>? metadata,
  ) {
    if (metadata == null || metadata.isEmpty) {
      return <String, dynamic>{};
    }

    return Map<String, dynamic>.unmodifiable(
      Map<String, dynamic>.from(metadata),
    );
  }
}
