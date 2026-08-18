import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/profile/services/profile_name_cache_service.dart';

import '../models/project_invitation_model.dart';

// ============================================================
// PROJECT INVITATION SERVICE
// ============================================================
//
// Responsável por:
//
// - identificar usuário autenticado;
// - escutar convites recebidos em Realtime;
// - retornar somente convites pendentes;
// - enriquecer convite com nome de quem convidou;
// - enriquecer convite com nome da Studio Session;
// - aceitar convite;
// - recusar convite;
// - buscar convites pendentes manualmente.
//
// Banco:
//
// public.project_invitations
//
// RPC:
//
// accept_project_invitation(invitation_id)
// reject_project_invitation(invitation_id)
//
// IMPORTANTE:
//
// Este service NÃO:
//
// - controla Widget;
// - mostra banner;
// - usa BuildContext;
// - navega;
// - mantém estado visual.
//
// Essas responsabilidades ficam no Controller / UI.
//
// ============================================================

class ProjectInvitationService {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // CACHE
  // ============================================================
  //
  // Nomes de perfil usam o cache central da aplicação.
  //
  // Títulos de projeto continuam locais porque pertencem
  // especificamente ao contexto de convites.
  //
  // ============================================================

  final ProfileNameCacheService _profileNameCacheService;

  final Map<
    String,
    String
  >
  _projectTitleCache =
      <
        String,
        String
      >{};

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  ProjectInvitationService({
    SupabaseClient? supabase,
    ProfileNameCacheService? profileNameCacheService,
  }) : _supabase =
           supabase ??
           Supabase.instance.client,
       _profileNameCacheService =
           profileNameCacheService ??
           ProfileNameCacheService();

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get currentUserId {
    final userId = _supabase.auth.currentUser?.id.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return null;
    }

    return userId;
  }

  bool get isAuthenticated {
    return currentUserId !=
        null;
  }

  // ============================================================
  // STREAM DE CONVITES PENDENTES
  // ============================================================
  //
  // O stream acompanha somente linhas cujo invited_user_id
  // pertence ao usuário atual.
  //
  // O filtro de status é feito localmente porque o mesmo convite
  // precisa desaparecer imediatamente quando muda de:
  //
  // pending
  //
  // para:
  //
  // accepted / rejected.
  //
  // ============================================================

  Stream<
    List<
      ProjectInvitationModel
    >
  >
  watchPendingInvitations() {
    final userId = currentUserId;

    if (userId ==
        null) {
      return Stream<
        List<
          ProjectInvitationModel
        >
      >.value(
        const <
          ProjectInvitationModel
        >[],
      );
    }

    debugPrint(
      '[PROJECT INVITATION] '
      'Realtime iniciado para: $userId',
    );

    // ==========================================================
    // REALTIME
    // ==========================================================
    //
    // O SupabaseStream entrega:
    //
    // - snapshot inicial;
    // - INSERT;
    // - UPDATE;
    // - DELETE;
    //
    // filtrados pelo usuário convidado.
    //
    // O status não é filtrado no servidor porque precisamos
    // receber também a mudança:
    //
    // pending -> accepted/rejected
    //
    // para o badge desaparecer imediatamente.
    //
    // ==========================================================

    return _supabase
        .from(
          'project_invitations',
        )
        .stream(
          primaryKey: [
            'id',
          ],
        )
        .eq(
          'invited_user_id',
          userId,
        )
        .asyncMap(
          (
            rows,
          ) async {
            final pendingRows = rows
                .where(
                  (
                    row,
                  ) {
                    final status = row['status']?.toString().trim().toLowerCase();

                    return status ==
                        'pending';
                  },
                )
                .toList(
                  growable: false,
                );

            if (pendingRows.isEmpty) {
              return const <
                ProjectInvitationModel
              >[];
            }

            // ====================================================
            // ENRIQUECER EM PARALELO
            // ====================================================
            //
            // Evita esperar convite por convite quando vários
            // chegam juntos.
            //
            // ====================================================

            final invitations = await Future.wait(
              pendingRows.map(
                (
                  row,
                ) async {
                  final invitation = ProjectInvitationModel.fromMap(
                    Map<
                      String,
                      dynamic
                    >.from(
                      row,
                    ),
                  );

                  return _enrichInvitation(
                    invitation,
                  );
                },
              ),
            );

            invitations.sort(
              (
                a,
                b,
              ) {
                return b.createdAt.compareTo(
                  a.createdAt,
                );
              },
            );

            debugPrint(
              '[PROJECT INVITATION] '
              'Realtime atualizado. '
              'Pendentes: ${invitations.length}',
            );

            return List<
              ProjectInvitationModel
            >.unmodifiable(
              invitations,
            );
          },
        );
  }

  // ============================================================
  // BUSCAR CONVITES PENDENTES
  // ============================================================

  Future<
    List<
      ProjectInvitationModel
    >
  >
  loadPendingInvitations() async {
    final userId = currentUserId;

    if (userId ==
        null) {
      return const <
        ProjectInvitationModel
      >[];
    }

    try {
      final response = await _supabase
          .from(
            'project_invitations',
          )
          .select()
          .eq(
            'invited_user_id',
            userId,
          )
          .eq(
            'status',
            'pending',
          )
          .order(
            'created_at',
            ascending: false,
          );

      final rows =
          List<
            Map<
              String,
              dynamic
            >
          >.from(
            response,
          );

      final invitations = await Future.wait(
        rows.map(
          (
            row,
          ) async {
            final invitation = ProjectInvitationModel.fromMap(
              row,
            );

            return _enrichInvitation(
              invitation,
            );
          },
        ),
      );

      invitations.sort(
        (
          a,
          b,
        ) {
          return b.createdAt.compareTo(
            a.createdAt,
          );
        },
      );

      return List<
        ProjectInvitationModel
      >.unmodifiable(
        invitations,
      );
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      _logPostgrestError(
        operation: 'carregar convites pendentes',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      _logUnexpectedError(
        operation: 'carregar convites pendentes',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // CREATE INVITATION
  // ============================================================
  //
  // Cria um convite pendente para uma Studio Session.
  //
  // Regras:
  //
  // - usuário precisa estar autenticado;
  // - não pode convidar a si mesmo;
  // - somente founder pode convidar;
  // - usuário já membro não recebe novo convite;
  // - convite pending duplicado não é criado.
  //
  // Retorna:
  //
  // ProjectInvitationModel
  // -> convite criado ou já existente.
  //
  // ============================================================

  Future<
    ProjectInvitationModel
  >
  createInvitation({
    required String projectId,
    required String invitedUserId,
  }) async {
    final normalizedProjectId = projectId.trim();
    final normalizedInvitedUserId = invitedUserId.trim();
    final inviterId = _requireAuthenticatedUser();

    if (normalizedProjectId.isEmpty) {
      throw ArgumentError(
        'ID do projeto não pode ficar vazio.',
      );
    }

    if (normalizedInvitedUserId.isEmpty) {
      throw ArgumentError(
        'ID do usuário convidado não pode ficar vazio.',
      );
    }

    if (inviterId ==
        normalizedInvitedUserId) {
      throw StateError(
        'Você não pode convidar a si mesmo.',
      );
    }

    try {
      // ========================================================
      // PROJECT
      // ========================================================

      final project = await _supabase
          .from(
            'projects',
          )
          .select(
            'id, title, members, founders',
          )
          .eq(
            'id',
            normalizedProjectId,
          )
          .maybeSingle();

      if (project ==
          null) {
        throw StateError(
          'Studio Session não encontrada.',
        );
      }

      final members = _readStringSet(
        project['members'],
      );

      final founders = _readStringSet(
        project['founders'],
      );

      // ========================================================
      // FOUNDER
      // ========================================================

      if (!founders.contains(
        inviterId,
      )) {
        throw StateError(
          'Somente fundadores podem convidar novos membros.',
        );
      }

      // ========================================================
      // ALREADY MEMBER
      // ========================================================

      if (members.contains(
        normalizedInvitedUserId,
      )) {
        throw StateError(
          'Este usuário já faz parte da equipe.',
        );
      }

      // ========================================================
      // EXISTING PENDING INVITATION
      // ========================================================

      final existing = await _supabase
          .from(
            'project_invitations',
          )
          .select()
          .eq(
            'project_id',
            normalizedProjectId,
          )
          .eq(
            'invited_user_id',
            normalizedInvitedUserId,
          )
          .eq(
            'status',
            'pending',
          )
          .maybeSingle();

      if (existing !=
          null) {
        final invitation = ProjectInvitationModel.fromMap(
          Map<
            String,
            dynamic
          >.from(
            existing,
          ),
        );

        return _enrichInvitation(
          invitation,
        );
      }

      // ========================================================
      // INSERT
      // ========================================================

      final inserted = await _supabase
          .from(
            'project_invitations',
          )
          .insert(
            {
              'project_id': normalizedProjectId,
              'invited_by': inviterId,
              'invited_user_id': normalizedInvitedUserId,
              'status': 'pending',
            },
          )
          .select()
          .single();

      final invitation = ProjectInvitationModel.fromMap(
        Map<
          String,
          dynamic
        >.from(
          inserted,
        ),
      );

      debugPrint(
        '[PROJECT INVITATION] '
        'Convite criado: '
        '${invitation.id} | '
        '$inviterId -> $normalizedInvitedUserId | '
        'projeto: $normalizedProjectId',
      );

      return _enrichInvitation(
        invitation,
      );
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      _logPostgrestError(
        operation: 'criar convite',
        error: error,
        stackTrace: stackTrace,
      );

      // UNIQUE de convite pending.
      //
      // Se outra operação criou o convite entre a checagem e o
      // INSERT, buscamos a linha existente e retornamos ela.
      if (error.code ==
          '23505') {
        final existing = await _supabase
            .from(
              'project_invitations',
            )
            .select()
            .eq(
              'project_id',
              normalizedProjectId,
            )
            .eq(
              'invited_user_id',
              normalizedInvitedUserId,
            )
            .eq(
              'status',
              'pending',
            )
            .maybeSingle();

        if (existing !=
            null) {
          return _enrichInvitation(
            ProjectInvitationModel.fromMap(
              Map<
                String,
                dynamic
              >.from(
                existing,
              ),
            ),
          );
        }
      }

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      _logUnexpectedError(
        operation: 'criar convite',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // HAS PENDING INVITATION
  // ============================================================

  Future<
    bool
  >
  hasPendingInvitation({
    required String projectId,
    required String invitedUserId,
  }) async {
    final normalizedProjectId = projectId.trim();
    final normalizedInvitedUserId = invitedUserId.trim();

    if (normalizedProjectId.isEmpty ||
        normalizedInvitedUserId.isEmpty) {
      return false;
    }

    try {
      final existing = await _supabase
          .from(
            'project_invitations',
          )
          .select(
            'id',
          )
          .eq(
            'project_id',
            normalizedProjectId,
          )
          .eq(
            'invited_user_id',
            normalizedInvitedUserId,
          )
          .eq(
            'status',
            'pending',
          )
          .maybeSingle();

      return existing !=
          null;
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      _logPostgrestError(
        operation: 'verificar convite pendente',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      _logUnexpectedError(
        operation: 'verificar convite pendente',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // PENDING INVITED USER IDS
  // ============================================================

  Future<
    Set<
      String
    >
  >
  loadPendingInvitedUserIds(
    String projectId,
  ) async {
    final normalizedProjectId = projectId.trim();
    final inviterId = currentUserId;

    if (normalizedProjectId.isEmpty ||
        inviterId ==
            null) {
      return <
        String
      >{};
    }

    try {
      final response = await _supabase
          .from(
            'project_invitations',
          )
          .select(
            'invited_user_id',
          )
          .eq(
            'project_id',
            normalizedProjectId,
          )
          .eq(
            'invited_by',
            inviterId,
          )
          .eq(
            'status',
            'pending',
          );

      final result =
          <
            String
          >{};

      for (final row in response) {
        final userId = row['invited_user_id']?.toString().trim();

        if (userId !=
                null &&
            userId.isNotEmpty) {
          result.add(
            userId,
          );
        }
      }

      return result;
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      _logPostgrestError(
        operation: 'carregar usuários com convite pendente',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      _logUnexpectedError(
        operation: 'carregar usuários com convite pendente',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // ACCEPT
  // ============================================================
  //
  // A função do banco:
  //
  // - valida auth.uid();
  // - valida status pending;
  // - adiciona usuário em projects.members;
  // - altera status para accepted;
  // - define responded_at;
  // - retorna project_id.
  //
  // ============================================================

  Future<
    String?
  >
  acceptInvitation(
    String invitationId,
  ) async {
    final normalizedInvitationId = invitationId.trim();

    if (normalizedInvitationId.isEmpty) {
      throw ArgumentError(
        'ID do convite não pode ficar vazio.',
      );
    }

    _requireAuthenticatedUser();

    try {
      final result = await _supabase.rpc(
        'accept_project_invitation',
        params: {
          'invitation_id': normalizedInvitationId,
        },
      );

      final projectId = result?.toString().trim();

      debugPrint(
        '[PROJECT INVITATION] '
        'Convite aceito: '
        '$normalizedInvitationId'
        '${projectId != null && projectId.isNotEmpty ? " | projeto: $projectId" : ""}',
      );

      if (projectId ==
              null ||
          projectId.isEmpty) {
        return null;
      }

      return projectId;
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      _logPostgrestError(
        operation: 'aceitar convite',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      _logUnexpectedError(
        operation: 'aceitar convite',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<
    void
  >
  rejectInvitation(
    String invitationId,
  ) async {
    final normalizedInvitationId = invitationId.trim();

    if (normalizedInvitationId.isEmpty) {
      throw ArgumentError(
        'ID do convite não pode ficar vazio.',
      );
    }

    _requireAuthenticatedUser();

    try {
      await _supabase.rpc(
        'reject_project_invitation',
        params: {
          'invitation_id': normalizedInvitationId,
        },
      );

      debugPrint(
        '[PROJECT INVITATION] '
        'Convite recusado: '
        '$normalizedInvitationId',
      );
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      _logPostgrestError(
        operation: 'recusar convite',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      _logUnexpectedError(
        operation: 'recusar convite',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // ENRIQUECER CONVITE
  // ============================================================

  Future<
    ProjectInvitationModel
  >
  _enrichInvitation(
    ProjectInvitationModel invitation,
  ) async {
    final inviterName = await _resolveProfileName(
      invitation.invitedBy,
    );

    final projectTitle = await _resolveProjectTitle(
      invitation.projectId,
    );

    return invitation.copyWith(
      inviterName: inviterName,
      projectTitle: projectTitle,
    );
  }

  // ============================================================
  // RESOLVER NOME DO CONVIDADOR
  // ============================================================
  //
  // Prioridade:
  //
  // 1. artist_name
  // 2. name
  // 3. @username
  // 4. Membro
  //
  // ============================================================

  Future<
    String
  >
  _resolveProfileName(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return 'Membro';
    }

    try {
      final resolved = await _profileNameCacheService.getName(
        normalizedUserId,
      );

      final normalizedName = resolved.trim();

      if (normalizedName.isEmpty) {
        return 'Membro';
      }

      return normalizedName;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT INVITATION] '
        'Erro ao resolver nome do convidador '
        '$normalizedUserId: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      return 'Membro';
    }
  }

  // ============================================================
  // RESOLVER TÍTULO DO PROJETO
  // ============================================================

  Future<
    String
  >
  _resolveProjectTitle(
    String projectId,
  ) async {
    final normalizedProjectId = projectId.trim();

    if (normalizedProjectId.isEmpty) {
      return 'Studio Session';
    }

    final cached = _projectTitleCache[normalizedProjectId];

    if (cached !=
            null &&
        cached.isNotEmpty) {
      return cached;
    }

    try {
      final project = await _supabase
          .from(
            'projects',
          )
          .select(
            'id, title',
          )
          .eq(
            'id',
            normalizedProjectId,
          )
          .maybeSingle();

      final title = project?['title']?.toString().trim();

      final resolved =
          title !=
                  null &&
              title.isNotEmpty
          ? title
          : 'Studio Session';

      _projectTitleCache[normalizedProjectId] = resolved;

      return resolved;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT INVITATION] '
        'Erro ao resolver título do projeto '
        '$normalizedProjectId: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      return 'Studio Session';
    }
  }

  // ============================================================
  // READ STRING SET
  // ============================================================

  Set<
    String
  >
  _readStringSet(
    dynamic value,
  ) {
    if (value
        is! List) {
      return <
        String
      >{};
    }

    return value
        .map(
          (
            item,
          ) =>
              item?.toString().trim() ??
              '',
        )
        .where(
          (
            item,
          ) => item.isNotEmpty,
        )
        .toSet();
  }

  // ============================================================
  // AUTH GUARD
  // ============================================================

  String _requireAuthenticatedUser() {
    final userId = currentUserId;

    if (userId ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return userId;
  }

  // ============================================================
  // CLEAR CACHE
  // ============================================================

  void clearCache() {
    _projectTitleCache.clear();
  }

  // ============================================================
  // POSTGREST LOG
  // ============================================================

  void _logPostgrestError({
    required String operation,
    required PostgrestException error,
    required StackTrace stackTrace,
  }) {
    debugPrint(
      '[PROJECT INVITATION] '
      'Erro Supabase ao $operation: '
      '${error.message}',
    );

    debugPrint(
      '[PROJECT INVITATION] '
      'Código: ${error.code}',
    );

    debugPrint(
      '[PROJECT INVITATION] '
      'Detalhes: ${error.details}',
    );

    debugPrint(
      '$stackTrace',
    );
  }

  // ============================================================
  // UNEXPECTED ERROR LOG
  // ============================================================

  void _logUnexpectedError({
    required String operation,
    required Object error,
    required StackTrace stackTrace,
  }) {
    debugPrint(
      '[PROJECT INVITATION] '
      'Erro ao $operation: '
      '$error',
    );

    debugPrint(
      '$stackTrace',
    );
  }
}
