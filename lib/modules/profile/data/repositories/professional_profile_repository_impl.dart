import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/core/cache/app_cache_service.dart';
import 'package:versin/core/cache/cache_keys.dart';
import 'package:versin/core/cache/cache_policy.dart';
import 'package:versin/core/cache/request_deduplicator.dart';
import 'package:versin/modules/profile/data/datasources/professional_profile_remote_datasource.dart';
import 'package:versin/modules/profile/models/professional_profile_model.dart';
import 'package:versin/modules/profile/repositories/professional_profile_repository.dart';

// ============================================================
// PROFESSIONAL PROFILE REPOSITORY IMPLEMENTATION
// ============================================================
//
// Implementação concreta do:
//
// ProfessionalProfileRepository
//
// Responsabilidades:
//
// - receber operações vindas do Controller;
// - validar regras básicas do perfil profissional;
// - normalizar os dados;
// - encaminhar os dados para o Datasource;
// - manter o Controller independente do Supabase.
//
// Esta camada NÃO acessa diretamente:
//
// - Supabase;
// - SQLite;
// - interface.
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

class ProfessionalProfileRepositoryImpl
    implements ProfessionalProfileRepository {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final ProfessionalProfileRemoteDatasource _remoteDatasource;
  final AppCacheService _cache = AppCacheService.instance;
  final RequestDeduplicator _deduplicator = RequestDeduplicator.instance;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  ProfessionalProfileRepositoryImpl({
    ProfessionalProfileRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
           remoteDatasource ?? ProfessionalProfileRemoteDatasourceImpl();

  // ============================================================
  // BUSCAR PERFIL PROFISSIONAL
  // ============================================================
  //
  // Busca em uma única operação:
  //
  // - roles;
  // - primary_role;
  // - looking_for_roles.
  //
  // O Datasource devolve um ProfessionalProfileModel pronto.
  //
  // ============================================================

  @override
  Future<ProfessionalProfileModel> getProfessionalProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id.trim();
    if (userId == null || userId.isEmpty)
      return ProfessionalProfileModel.empty();

    final key = CacheKeys.professionalProfile(userId);
    final cached = await _cache.read(
      key,
      policy: CachePolicy.professionalProfile,
    );
    if (cached != null) {
      final profile = _decodeProfile(cached.value);
      if (cached.isFresh) return profile;
      unawaited(_refreshProfessionalProfile(userId));
      return profile;
    }
    return _refreshProfessionalProfile(userId);
  }

  Future<ProfessionalProfileModel> _refreshProfessionalProfile(String userId) {
    final key = CacheKeys.professionalProfile(userId);
    return _deduplicator.run<ProfessionalProfileModel>('remote:$key', () async {
      try {
        final profile = await _remoteDatasource.getProfessionalProfile();
        await _cache.write(key, profile.toMap());
        return profile;
      } catch (_) {
        final stale = await _cache.read(
          key,
          policy: CachePolicy.professionalProfile,
          allowStale: true,
        );
        if (stale != null) return _decodeProfile(stale.value);
        rethrow;
      }
    });
  }

  ProfessionalProfileModel _decodeProfile(dynamic raw) {
    if (raw is! Map) return ProfessionalProfileModel.empty();
    return ProfessionalProfileModel.fromMap(Map<String, dynamic>.from(raw));
  }

  // ============================================================
  // SALVAR PERFIL PROFISSIONAL
  // ============================================================

  @override
  Future<void> saveProfessionalProfile(ProfessionalProfileModel profile) async {
    // ==========================================================
    // NORMALIZAR FUNÇÕES DO USUÁRIO
    // ==========================================================

    final normalizedRoles = profile.roles.toSet().toList();

    // ==========================================================
    // NORMALIZAR PROFISSIONAIS PROCURADOS
    // ==========================================================

    final normalizedLookingForRoles = profile.lookingForRoles.toSet().toList();

    // ==========================================================
    // FUNÇÃO PRINCIPAL
    // ==========================================================

    final primaryRole = profile.primaryRole;

    // ==========================================================
    // VALIDAR FUNÇÕES
    // ==========================================================

    if (normalizedRoles.isEmpty) {
      throw ArgumentError(
        'É necessário informar pelo menos uma função profissional.',
      );
    }

    // ==========================================================
    // VALIDAR FUNÇÃO PRINCIPAL
    // ==========================================================

    if (primaryRole == null) {
      throw ArgumentError(
        'É necessário informar uma função profissional principal.',
      );
    }

    if (!normalizedRoles.contains(primaryRole)) {
      throw ArgumentError(
        'A função principal precisa estar entre as funções selecionadas.',
      );
    }

    // ==========================================================
    // CRIAR PERFIL NORMALIZADO
    // ==========================================================
    //
    // Criamos uma nova instância para garantir que arrays
    // duplicados não sejam enviados para o banco.
    //
    // Exemplo:
    //
    // roles:
    //
    // [
    //   beatmaker,
    //   beatmaker,
    //   artist
    // ]
    //
    // passa a ser:
    //
    // [
    //   beatmaker,
    //   artist
    // ]
    //
    // O mesmo acontece com lookingForRoles.
    //
    // ==========================================================

    final normalizedProfile = ProfessionalProfileModel(
      roles: normalizedRoles,
      primaryRole: primaryRole,
      lookingForRoles: normalizedLookingForRoles,
    );

    // ==========================================================
    // SALVAR NO DATASOURCE
    // ==========================================================

    await _remoteDatasource.saveProfessionalProfile(normalizedProfile);

    final userId = Supabase.instance.client.auth.currentUser?.id.trim();
    if (userId != null && userId.isNotEmpty) {
      await _cache.write(
        CacheKeys.professionalProfile(userId),
        normalizedProfile.toMap(),
      );
    }
  }
}
