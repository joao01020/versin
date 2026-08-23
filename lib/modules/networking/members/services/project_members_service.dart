import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project_member_model.dart';

// ============================================================
// PROJECT MEMBERS SERVICE
// ============================================================
//
// Responsável por:
//
// - localizar a Studio Session;
// - ler projects.members;
// - buscar os profiles correspondentes;
// - converter em ProjectMemberModel;
// - ordenar participantes;
// - identificar o usuário atual.
//
// Fluxo:
//
// projectId
//    ↓
// projects.members
//    ↓
// [uuidA, uuidB, uuidC]
//    ↓
// profiles
//    ↓
// ProjectMemberModel
//
// ============================================================

class ProjectMembersService {
  // ==========================================================
  // TABELAS
  // ==========================================================

  static const String _projectsTable = 'projects';

  static const String _profilesTable = 'profiles';

  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  ProjectMembersService({
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
  // BUSCAR MEMBROS
  // ==========================================================

  Future<
    List<
      ProjectMemberModel
    >
  >
  getMembers({
    required String projectId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    try {
      // ========================================================
      // BUSCAR PROJETO
      // ========================================================

      final project = await _supabase
          .from(
            _projectsTable,
          )
          .select(
            'id, members',
          )
          .eq(
            'id',
            normalizedProjectId,
          )
          .maybeSingle();

      if (project ==
          null) {
        throw StateError(
          'Projeto não encontrado.',
        );
      }

      // ========================================================
      // IDS DOS MEMBROS
      // ========================================================

      final memberIds = _readIds(
        project['members'],
      );

      if (memberIds.isEmpty) {
        return const <
          ProjectMemberModel
        >[];
      }

      // ========================================================
      // BUSCAR PERFIS
      // ========================================================

      final response = await _supabase
          .from(
            _profilesTable,
          )
          .select(
            '''
                id,
                username,
                name,
                artist_name,
                primary_role,
                roles,
                avatar_url,
                is_online
                ''',
          )
          .inFilter(
            'id',
            memberIds,
          );

      // ========================================================
      // CONVERTER
      // ========================================================

      final members = response
          .map(
            (
              row,
            ) => ProjectMemberModel.fromMap(
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
              member,
            ) => member.id.isNotEmpty,
          )
          .toList();

      // ========================================================
      // ORDENAR
      // ========================================================
      //
      // Prioridade:
      //
      // 1. usuário atual;
      // 2. online;
      // 3. nome.
      //
      // ========================================================

      final userId = currentUserId;

      members.sort(
        (
          first,
          second,
        ) {
          // ====================================================
          // USUÁRIO ATUAL
          // ====================================================

          if (userId !=
              null) {
            final firstIsMe =
                first.id ==
                userId;

            final secondIsMe =
                second.id ==
                userId;

            if (firstIsMe &&
                !secondIsMe) {
              return -1;
            }

            if (secondIsMe &&
                !firstIsMe) {
              return 1;
            }
          }

          // ====================================================
          // ONLINE
          // ====================================================

          if (first.isOnline !=
              second.isOnline) {
            return first.isOnline
                ? -1
                : 1;
          }

          // ====================================================
          // NOME
          // ====================================================

          return first.displayName.toLowerCase().compareTo(
            second.displayName.toLowerCase(),
          );
        },
      );

      // ========================================================
      // LOG
      // ========================================================

      debugPrint(
        '[PROJECT MEMBERS] '
        '${members.length} membro(s) carregado(s).',
      );

      for (final member in members) {
        debugPrint(
          '[PROJECT MEMBERS] '
          '${member.displayName} | '
          '${member.usernameLabel} | '
          '${member.roleLabel}',
        );
      }

      return List<
        ProjectMemberModel
      >.unmodifiable(
        members,
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[PROJECT MEMBERS] '
        'Erro Supabase: '
        '${error.message}',
      );

      debugPrint(
        '[PROJECT MEMBERS] '
        'Código: '
        '${error.code}',
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT MEMBERS] '
        'Erro inesperado: '
        '$error',
      );

      debugPrint(
        '[PROJECT MEMBERS] '
        'StackTrace: '
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ==========================================================
  // LER IDS
  // ==========================================================

  List<
    String
  >
  _readIds(
    dynamic value,
  ) {
    if (value
        is! Iterable) {
      return const <
        String
      >[];
    }

    return value
        .map(
          (
            item,
          ) => item.toString().trim(),
        )
        .where(
          (
            item,
          ) => item.isNotEmpty,
        )
        .toSet()
        .toList(
          growable: false,
        );
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
