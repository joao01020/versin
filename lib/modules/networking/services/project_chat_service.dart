import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/project_message_model.dart';

// ============================================================
// PROJECT CHAT SERVICE
// ============================================================
//
// Responsável pela comunicação entre:
//
// Flutter
//    ↓
// public.project_messages
//    ↓
// Supabase Realtime
//
// Este service:
//
// - identifica o usuário autenticado;
// - busca mensagens;
// - envia mensagens;
// - abre stream realtime;
// - valida conteúdo;
// - mantém cada conversa isolada pelo projectId.
//
// A autorização real continua protegida pelas políticas RLS
// configuradas no Supabase.
//
// ============================================================

class ProjectChatService {
  // ==========================================================
  // TABELA
  // ==========================================================

  static const String _table = 'project_messages';

  // ==========================================================
  // LIMITES
  // ==========================================================

  static const int maxMessageLength = 4000;

  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  ProjectChatService({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ==========================================================
  // USUÁRIO ATUAL
  // ==========================================================

  String? get currentUserId {
    final id = _supabase.auth.currentUser?.id.trim();

    if (id ==
            null ||
        id.isEmpty) {
      return null;
    }

    return id;
  }

  // ==========================================================
  // USUÁRIO OBRIGATÓRIO
  // ==========================================================

  String requireCurrentUserId() {
    final id = currentUserId;

    if (id ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return id;
  }

  // ==========================================================
  // STREAM DE MENSAGENS
  // ==========================================================
  //
  // O stream:
  //
  // 1. recebe o estado inicial;
  // 2. continua ouvindo inserts / updates / deletes;
  // 3. entrega somente mensagens do projectId informado.
  //
  // ==========================================================

  Stream<
    List<
      ProjectMessageModel
    >
  >
  streamMessages({
    required String projectId,
  }) {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    return _supabase
        .from(
          _table,
        )
        .stream(
          primaryKey: [
            'id',
          ],
        )
        .eq(
          'project_id',
          normalizedProjectId,
        )
        .order(
          'created_at',
          ascending: true,
        )
        .map(
          (
            rows,
          ) {
            return rows
                .map(
                  (
                    row,
                  ) => ProjectMessageModel.fromMap(
                    Map<
                      String,
                      dynamic
                    >.from(
                      row,
                    ),
                  ),
                )
                .where(
                  (
                    message,
                  ) =>
                      message.id.isNotEmpty &&
                      message.projectId ==
                          normalizedProjectId,
                )
                .toList(
                  growable: false,
                );
          },
        );
  }

  // ==========================================================
  // CARREGAR MENSAGENS
  // ==========================================================
  //
  // Não é obrigatório para o Realtime, pois stream() já envia
  // o estado inicial.
  //
  // Mantemos este método para:
  //
  // - paginação futura;
  // - histórico;
  // - carregamento manual;
  // - testes.
  //
  // ==========================================================

  Future<
    List<
      ProjectMessageModel
    >
  >
  getMessages({
    required String projectId,
    int limit = 200,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedLimit = limit.clamp(
      1,
      500,
    );

    try {
      final response = await _supabase
          .from(
            _table,
          )
          .select(
            '''
                id,
                project_id,
                sender_id,
                content,
                created_at
                ''',
          )
          .eq(
            'project_id',
            normalizedProjectId,
          )
          .order(
            'created_at',
            ascending: false,
          )
          .limit(
            normalizedLimit,
          );

      final messages = response
          .map(
            (
              row,
            ) => ProjectMessageModel.fromMap(
              Map<
                String,
                dynamic
              >.from(
                row,
              ),
            ),
          )
          .toList();

      // A consulta busca do mais recente para o mais antigo
      // para permitir LIMIT eficiente.
      //
      // Invertemos para a UI:
      //
      // antigo
      //   ↓
      // novo

      return messages.reversed.toList(
        growable: false,
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[PROJECT CHAT] '
        'Erro ao carregar mensagens: '
        '${error.message}',
      );

      rethrow;
    }
  }

  // ==========================================================
  // ENVIAR MENSAGEM
  // ==========================================================

  Future<
    ProjectMessageModel
  >
  sendMessage({
    required String projectId,
    required String content,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedContent = _normalizeMessage(
      content,
    );

    final userId = requireCurrentUserId();

    try {
      // ========================================================
      // INSERT
      // ========================================================

      final response = await _supabase
          .from(
            _table,
          )
          .insert(
            {
              'project_id': normalizedProjectId,

              'sender_id': userId,

              'content': normalizedContent,
            },
          )
          .select(
            '''
                id,
                project_id,
                sender_id,
                content,
                created_at
                ''',
          )
          .single();

      // ========================================================
      // MODEL
      // ========================================================

      final message = ProjectMessageModel.fromMap(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );

      if (message.id.isEmpty) {
        throw StateError(
          'Mensagem criada sem ID.',
        );
      }

      debugPrint(
        '[PROJECT CHAT] '
        'Mensagem enviada: '
        '${message.id}',
      );

      return message;
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[PROJECT CHAT] '
        'Erro Supabase ao enviar mensagem: '
        '${error.message}',
      );

      debugPrint(
        '[PROJECT CHAT] '
        'Código: '
        '${error.code}',
      );

      rethrow;
    }
  }

  // ==========================================================
  // APAGAR MENSAGEM
  // ==========================================================
  //
  // A política RLS deve permitir apagar somente mensagens do
  // próprio sender.
  //
  // ==========================================================

  Future<
    void
  >
  deleteMessage({
    required String messageId,
  }) async {
    final normalizedMessageId = _required(
      messageId,
      'messageId',
    );

    final userId = requireCurrentUserId();

    try {
      await _supabase
          .from(
            _table,
          )
          .delete()
          .eq(
            'id',
            normalizedMessageId,
          )
          .eq(
            'sender_id',
            userId,
          );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[PROJECT CHAT] '
        'Erro ao apagar mensagem: '
        '${error.message}',
      );

      rethrow;
    }
  }

  // ==========================================================
  // NORMALIZAR MENSAGEM
  // ==========================================================

  String _normalizeMessage(
    String content,
  ) {
    final normalized = content.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'A mensagem não pode ser vazia.',
      );
    }

    if (normalized.length >
        maxMessageLength) {
      throw ArgumentError(
        'A mensagem pode possuir no máximo '
        '$maxMessageLength caracteres.',
      );
    }

    return normalized;
  }

  // ==========================================================
  // REQUIRED
  // ==========================================================

  String _required(
    String value,
    String field,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        '$field não pode ser vazio.',
      );
    }

    return normalized;
  }
}
