import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project_message_model.dart';
import 'project_chat_service.dart';

// ============================================================
// GLOBAL CHAT SERVICE
// ============================================================
//
// Serviço utilizado pelo sistema GLOBAL de notificações do chat.
//
// Responsabilidades:
//
// - fornecer o usuário autenticado;
// - acompanhar mensagens de UMA Studio Session em Realtime;
// - acompanhar mensagens de TODAS as Studio Sessions permitidas
//   ao usuário em Realtime;
// - resolver o nome de um remetente;
// - manter toda comunicação com Supabase fora do controller.
//
// Este serviço NÃO:
//
// - controla UI;
// - controla banner;
// - mantém contador de não lidas;
// - decide se uma mensagem deve gerar notificação;
// - substitui o ProjectChatService.
//
// Arquitetura:
//
// Supabase
//    ↓
// ProjectChatService
//    ↓
// GlobalChatService
//    ↓
// GlobalChatController
//    ↓
// GlobalChatBanner
//
// IMPORTANTE:
//
// streamAllMessages() não ignora a RLS.
//
// O Supabase continua retornando somente as mensagens que o
// usuário autenticado possui permissão para visualizar.
//
// ============================================================

class GlobalChatService {
  // ==========================================================
  // DATABASE
  // ==========================================================

  static const String _messagesTable = 'project_messages';

  // ==========================================================
  // SERVICES
  // ==========================================================

  final ProjectChatService _projectChatService;

  final SupabaseClient _supabase;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  GlobalChatService({
    ProjectChatService? projectChatService,
    SupabaseClient? supabase,
  }) : _projectChatService =
           projectChatService ??
           ProjectChatService(),
       _supabase =
           supabase ??
           Supabase.instance.client;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  String? get currentUserId {
    final userId = _projectChatService.currentUserId?.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return null;
    }

    return userId;
  }

  // ==========================================================
  // AUTHENTICATED
  // ==========================================================

  bool get isAuthenticated {
    return currentUserId !=
        null;
  }

  // ==========================================================
  // REQUIRE CURRENT USER
  // ==========================================================

  String requireCurrentUserId() {
    final userId = currentUserId;

    if (userId ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return userId;
  }

  // ==========================================================
  // STREAM MESSAGES
  // ==========================================================
  //
  // Stream de UMA Studio Session.
  //
  // Reutiliza o stream oficial do ProjectChatService.
  //
  // Isso é importante porque:
  //
  // - não duplicamos regra de acesso ao banco;
  // - mantemos o mesmo filtro por projectId;
  // - mantemos o mesmo ProjectMessageModel;
  // - mudanças futuras no chat continuam centralizadas.
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
    final normalizedProjectId = projectId.trim();

    if (normalizedProjectId.isEmpty) {
      throw ArgumentError(
        'projectId não pode ser vazio.',
      );
    }

    return _projectChatService.streamMessages(
      projectId: normalizedProjectId,
    );
  }

  // ==========================================================
  // STREAM ALL MESSAGES
  // ==========================================================
  //
  // Stream GLOBAL usado pelo Dashboard.
  //
  // Diferente de streamMessages(), este método NÃO recebe
  // projectId.
  //
  // Ele acompanha project_messages de todas as Studio Sessions
  // que a RLS permite ao usuário autenticado visualizar.
  //
  // Exemplo:
  //
  // Studio Session A
  //   └── mensagem nova
  //
  // Studio Session B
  //   └── mensagem nova
  //
  // Dashboard
  //   └── GlobalChatController
  //        └── recebe ambas
  //
  // A segurança continua sendo responsabilidade da RLS.
  //
  // ==========================================================

  Stream<
    List<
      ProjectMessageModel
    >
  >
  streamAllMessages() {
    // ========================================================
    // AUTH
    // ========================================================

    requireCurrentUserId();

    // ========================================================
    // REALTIME
    // ========================================================

    return _supabase
        .from(
          _messagesTable,
        )
        .stream(
          primaryKey: [
            'id',
          ],
        )
        .order(
          'created_at',
          ascending: true,
        )
        .map(
          (
            rows,
          ) {
            final messages =
                <
                  ProjectMessageModel
                >[];

            for (final row in rows) {
              try {
                final message = ProjectMessageModel.fromMap(
                  Map<
                    String,
                    dynamic
                  >.from(
                    row,
                  ),
                );

                // ============================================
                // ID
                // ============================================

                if (message.id.trim().isEmpty) {
                  continue;
                }

                // ============================================
                // PROJECT
                // ============================================

                if (message.projectId.trim().isEmpty) {
                  continue;
                }

                messages.add(
                  message,
                );
              } catch (
                error,
                stackTrace
              ) {
                debugPrint(
                  '[GLOBAL CHAT SERVICE] '
                  'Mensagem inválida ignorada: '
                  '$error',
                );

                debugPrint(
                  '[GLOBAL CHAT SERVICE] '
                  '$stackTrace',
                );
              }
            }

            // ==============================================
            // ORDENAR DEFENSIVAMENTE
            // ==============================================

            messages.sort(
              (
                first,
                second,
              ) => first.createdAt.compareTo(
                second.createdAt,
              ),
            );

            return List<
              ProjectMessageModel
            >.unmodifiable(
              messages,
            );
          },
        );
  }

  // ==========================================================
  // RESOLVE SENDER NAME
  // ==========================================================

  Future<
    String
  >
  resolveSenderName({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return 'Membro';
    }

    try {
      final profile = await _supabase
          .from(
            'profiles',
          )
          .select(
            'id, artist_name, name, username',
          )
          .eq(
            'id',
            normalizedUserId,
          )
          .maybeSingle();

      return _resolveProfileDisplayName(
        profile,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[GLOBAL CHAT SERVICE] '
        'Erro ao buscar perfil '
        '$normalizedUserId: '
        '$error',
      );

      debugPrint(
        '[GLOBAL CHAT SERVICE] '
        'StackTrace: '
        '$stackTrace',
      );

      return 'Membro';
    }
  }

  // ==========================================================
  // RESOLVE MULTIPLE SENDER NAMES
  // ==========================================================
  //
  // Pode ser usado futuramente caso o sistema precise resolver
  // vários remetentes de uma vez.
  //
  // ==========================================================

  Future<
    Map<
      String,
      String
    >
  >
  resolveSenderNames({
    required Iterable<
      String
    >
    userIds,
  }) async {
    final normalizedIds = userIds
        .map(
          (
            userId,
          ) => userId.trim(),
        )
        .where(
          (
            userId,
          ) => userId.isNotEmpty,
        )
        .toSet();

    if (normalizedIds.isEmpty) {
      return const <
        String,
        String
      >{};
    }

    try {
      final profiles = await _supabase
          .from(
            'profiles',
          )
          .select(
            'id, artist_name, name, username',
          )
          .inFilter(
            'id',
            normalizedIds.toList(),
          );

      final result =
          <
            String,
            String
          >{};

      for (final rawProfile in profiles) {
        final profile =
            Map<
              String,
              dynamic
            >.from(
              rawProfile,
            );

        final id = profile['id']?.toString().trim();

        if (id ==
                null ||
            id.isEmpty) {
          continue;
        }

        result[id] = _resolveProfileDisplayName(
          profile,
        );
      }

      // ======================================================
      // IDS SEM PERFIL
      // ======================================================

      for (final userId in normalizedIds) {
        result.putIfAbsent(
          userId,
          () => 'Membro',
        );
      }

      return result;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[GLOBAL CHAT SERVICE] '
        'Erro ao buscar perfis: '
        '$error',
      );

      debugPrint(
        '[GLOBAL CHAT SERVICE] '
        'StackTrace: '
        '$stackTrace',
      );

      return {
        for (final userId in normalizedIds) userId: 'Membro',
      };
    }
  }

  // ==========================================================
  // PROFILE DISPLAY NAME
  // ==========================================================
  //
  // Mesma prioridade utilizada pela ChatView:
  //
  // 1. artist_name
  // 2. name
  // 3. username
  // 4. Membro
  //
  // ==========================================================

  String _resolveProfileDisplayName(
    Map<
      String,
      dynamic
    >?
    profile,
  ) {
    if (profile ==
        null) {
      return 'Membro';
    }

    // ========================================================
    // ARTIST NAME
    // ========================================================

    final artistName = profile['artist_name']?.toString().trim();

    if (artistName !=
            null &&
        artistName.isNotEmpty) {
      return artistName;
    }

    // ========================================================
    // NAME
    // ========================================================

    final name = profile['name']?.toString().trim();

    if (name !=
            null &&
        name.isNotEmpty) {
      return name;
    }

    // ========================================================
    // USERNAME
    // ========================================================

    final username = profile['username']?.toString().trim().replaceFirst(
      RegExp(
        r'^@+',
      ),
      '',
    );

    if (username !=
            null &&
        username.isNotEmpty) {
      return '@$username';
    }

    // ========================================================
    // FALLBACK
    // ========================================================

    return 'Membro';
  }
}
