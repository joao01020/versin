import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/profile/models/professional_profile_model.dart';

// ============================================================
// PROFESSIONAL PROFILE REMOTE DATASOURCE
// ============================================================
//
// Responsável exclusivamente pela comunicação remota
// relacionada ao perfil profissional.
//
// Esta é a camada que conhece o Supabase.
//
// Fluxo:
//
// ProfessionalProfileSettingsPage
//              ↓
// ProfessionalProfileController
//              ↓
// ProfessionalProfileRepository
//              ↓
// ProfessionalProfileRepositoryImpl
//              ↓
// ProfessionalProfileRemoteDatasource
//              ↓
// Supabase
//
// ============================================================

abstract class ProfessionalProfileRemoteDatasource {
  // ==========================================================
  // BUSCAR PERFIL PROFISSIONAL
  // ==========================================================
  //
  // Busca em uma única chamada:
  //
  // - primary_role
  // - roles
  // - looking_for_roles
  //
  // ==========================================================

  Future<
    ProfessionalProfileModel
  >
  getProfessionalProfile();

  // ==========================================================
  // SALVAR PERFIL PROFISSIONAL
  // ==========================================================

  Future<
    void
  >
  saveProfessionalProfile(
    ProfessionalProfileModel profile,
  );
}

// ============================================================
// IMPLEMENTAÇÃO SUPABASE
// ============================================================

class ProfessionalProfileRemoteDatasourceImpl
    implements
        ProfessionalProfileRemoteDatasource {
  // ============================================================
  // DEPENDÊNCIA
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  ProfessionalProfileRemoteDatasourceImpl({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ============================================================
  // BUSCAR PERFIL PROFISSIONAL
  // ============================================================

  @override
  Future<
    ProfessionalProfileModel
  >
  getProfessionalProfile() async {
    // ==========================================================
    // USUÁRIO AUTENTICADO
    // ==========================================================

    final user = _supabase.auth.currentUser;

    if (user ==
        null) {
      debugPrint(
        '[PROFILE REMOTE] Nenhum usuário autenticado.',
      );

      return ProfessionalProfileModel.empty();
    }

    // ==========================================================
    // LOG
    // ==========================================================

    debugPrint(
      '[PROFILE REMOTE] ========================================',
    );

    debugPrint(
      '[PROFILE REMOTE] Carregando perfil profissional.',
    );

    debugPrint(
      '[PROFILE REMOTE] User ID: ${user.id}',
    );

    // ==========================================================
    // BUSCAR NO SUPABASE
    // ==========================================================

    try {
      final result = await _supabase
          .from(
            'profiles',
          )
          .select(
            'primary_role, roles, looking_for_roles',
          )
          .eq(
            'id',
            user.id,
          )
          .maybeSingle();

      // ========================================================
      // PERFIL NÃO EXISTE
      // ========================================================

      if (result ==
          null) {
        debugPrint(
          '[PROFILE REMOTE] Perfil remoto não encontrado.',
        );

        debugPrint(
          '[PROFILE REMOTE] ========================================',
        );

        return ProfessionalProfileModel.empty();
      }

      // ========================================================
      // CONVERTER PARA MODEL
      // ========================================================

      final profile = ProfessionalProfileModel.fromMap(
        result,
      );

      // ========================================================
      // LOG
      // ========================================================

      debugPrint(
        '[PROFILE REMOTE] Perfil profissional carregado.',
      );

      debugPrint(
        '[PROFILE REMOTE] Função principal: '
        '${profile.primaryRole?.key ?? "não informado"}',
      );

      debugPrint(
        '[PROFILE REMOTE] Funções: '
        '${profile.roles.map((role) => role.key).toList()}',
      );

      debugPrint(
        '[PROFILE REMOTE] Procura: '
        '${profile.lookingForRoles.map((role) => role.key).toList()}',
      );

      debugPrint(
        '[PROFILE REMOTE] ========================================',
      );

      return profile;
    } on PostgrestException catch (
      error
    ) {
      // ========================================================
      // ERRO POSTGREST
      // ========================================================

      debugPrint(
        '[PROFILE REMOTE] ========================================',
      );

      debugPrint(
        '[PROFILE REMOTE] Erro ao carregar perfil profissional.',
      );

      debugPrint(
        '[PROFILE REMOTE] Mensagem: ${error.message}',
      );

      debugPrint(
        '[PROFILE REMOTE] Código: ${error.code}',
      );

      debugPrint(
        '[PROFILE REMOTE] Detalhes: ${error.details}',
      );

      debugPrint(
        '[PROFILE REMOTE] Hint: ${error.hint}',
      );

      debugPrint(
        '[PROFILE REMOTE] ========================================',
      );

      rethrow;
    } catch (
      error
    ) {
      // ========================================================
      // ERRO INESPERADO
      // ========================================================

      debugPrint(
        '[PROFILE REMOTE] ========================================',
      );

      debugPrint(
        '[PROFILE REMOTE] Erro inesperado ao carregar perfil.',
      );

      debugPrint(
        '[PROFILE REMOTE] $error',
      );

      debugPrint(
        '[PROFILE REMOTE] ========================================',
      );

      rethrow;
    }
  }

  // ============================================================
  // SALVAR PERFIL PROFISSIONAL
  // ============================================================

  @override
  Future<
    void
  >
  saveProfessionalProfile(
    ProfessionalProfileModel profile,
  ) async {
    // ==========================================================
    // USUÁRIO AUTENTICADO
    // ==========================================================

    final user = _supabase.auth.currentUser;

    if (user ==
        null) {
      throw const AuthException(
        'Usuário não autenticado.',
      );
    }

    // ==========================================================
    // VALIDAÇÕES
    // ==========================================================

    if (profile.roles.isEmpty) {
      throw ArgumentError(
        'É necessário selecionar pelo menos uma função profissional.',
      );
    }

    final primaryRole = profile.primaryRole;

    if (primaryRole ==
        null) {
      throw ArgumentError(
        'É necessário selecionar uma função principal.',
      );
    }

    if (!profile.roles.contains(
      primaryRole,
    )) {
      throw ArgumentError(
        'A função principal precisa estar entre as funções selecionadas.',
      );
    }

    // ==========================================================
    // NORMALIZAR
    // ==========================================================

    final normalizedProfile = ProfessionalProfileModel(
      roles: profile.roles.toSet().toList(),

      primaryRole: primaryRole,

      lookingForRoles: profile.lookingForRoles.toSet().toList(),
    );

    final data = normalizedProfile.toMap();

    // ==========================================================
    // LOG
    // ==========================================================

    debugPrint(
      '[PROFILE REMOTE] ========================================',
    );

    debugPrint(
      '[PROFILE REMOTE] Salvando perfil profissional.',
    );

    debugPrint(
      '[PROFILE REMOTE] User ID: ${user.id}',
    );

    debugPrint(
      '[PROFILE REMOTE] Função principal: '
      '${normalizedProfile.primaryRole?.key}',
    );

    debugPrint(
      '[PROFILE REMOTE] Funções: '
      '${normalizedProfile.roles.map((role) => role.key).toList()}',
    );

    debugPrint(
      '[PROFILE REMOTE] Procura: '
      '${normalizedProfile.lookingForRoles.map((role) => role.key).toList()}',
    );

    // ==========================================================
    // SALVAR NO SUPABASE
    // ==========================================================

    try {
      await _supabase
          .from(
            'profiles',
          )
          .update(
            data,
          )
          .eq(
            'id',
            user.id,
          );

      // ========================================================
      // SUCESSO
      // ========================================================

      debugPrint(
        '[PROFILE REMOTE] Perfil profissional salvo.',
      );

      debugPrint(
        '[PROFILE REMOTE] ========================================',
      );
    } on PostgrestException catch (
      error
    ) {
      // ========================================================
      // ERRO DO BANCO / POSTGREST
      // ========================================================

      debugPrint(
        '[PROFILE REMOTE] ========================================',
      );

      debugPrint(
        '[PROFILE REMOTE] Erro do Supabase.',
      );

      debugPrint(
        '[PROFILE REMOTE] Mensagem: ${error.message}',
      );

      debugPrint(
        '[PROFILE REMOTE] Código: ${error.code}',
      );

      debugPrint(
        '[PROFILE REMOTE] Detalhes: ${error.details}',
      );

      debugPrint(
        '[PROFILE REMOTE] Hint: ${error.hint}',
      );

      debugPrint(
        '[PROFILE REMOTE] ========================================',
      );

      rethrow;
    } on AuthException catch (
      error
    ) {
      // ========================================================
      // ERRO AUTENTICAÇÃO
      // ========================================================

      debugPrint(
        '[PROFILE REMOTE] ========================================',
      );

      debugPrint(
        '[PROFILE REMOTE] Erro de autenticação.',
      );

      debugPrint(
        '[PROFILE REMOTE] Mensagem: ${error.message}',
      );

      debugPrint(
        '[PROFILE REMOTE] ========================================',
      );

      rethrow;
    } catch (
      error
    ) {
      // ========================================================
      // ERRO INESPERADO
      // ========================================================

      debugPrint(
        '[PROFILE REMOTE] ========================================',
      );

      debugPrint(
        '[PROFILE REMOTE] Erro inesperado.',
      );

      debugPrint(
        '[PROFILE REMOTE] $error',
      );

      debugPrint(
        '[PROFILE REMOTE] ========================================',
      );

      rethrow;
    }
  }
}
