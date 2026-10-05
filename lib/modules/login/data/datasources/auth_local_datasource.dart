import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'package:versin/core/database/database_helper.dart';

// ============================================================
// AUTH LOCAL DATASOURCE
// ============================================================
//
// Responsável pelo cache local do perfil.
//
// DESKTOP / MOBILE:
//
// Utiliza SQLite.
//
// WEB:
//
// O SQLite utilizado pelo Versin não está disponível.
// Portanto, operações locais tornam-se no-op.
//
// A fonte principal dos dados continua sendo o Supabase.
//
// ============================================================

abstract class AuthLocalDatasource {
  Future<void> saveLocalProfile({
    required String userId,
    required String username,
    required String wallet,
    String? artistName,
  });

  Future<void> saveArtistName({
    required String userId,
    required String artistName,
  });

  Future<String?> getArtistName(String userId);

  Future<void> clearLocalProfile();
}

// ============================================================
// IMPLEMENTAÇÃO
// ============================================================

class AuthLocalDatasourceImpl implements AuthLocalDatasource {
  // ==========================================================
  // DISPONIBILIDADE DO CACHE LOCAL
  // ==========================================================

  bool get _supportsLocalDatabase {
    return !kIsWeb;
  }

  // ==========================================================
  // SALVAR PERFIL
  // ==========================================================

  @override
  Future<void> saveLocalProfile({
    required String userId,
    required String username,
    required String wallet,
    String? artistName,
  }) async {
    if (!_supportsLocalDatabase) {
      debugPrint(
        '[VERSIN AUTH] '
        'Cache SQLite ignorado no Web ao salvar perfil.',
      );

      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;

      final normalizedUsername = username.trim();

      final normalizedWallet = wallet.trim();

      final normalizedArtistName = artistName?.trim();

      final normalizedWalletAddress = normalizedWallet.isEmpty
          ? ''
          : normalizedWallet.startsWith('wallet@')
          ? normalizedWallet
          : 'wallet@$normalizedWallet';

      // ======================================================
      // ATUALIZAR PERFIL EXISTENTE
      // ======================================================

      final updatedRows = await db.update(
        'user_profile',
        {
          'name': normalizedUsername,
          'wallet': normalizedWalletAddress,
          if (normalizedArtistName != null && normalizedArtistName.isNotEmpty)
            'artist_name': normalizedArtistName,
          'synced': 1,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      // ======================================================
      // CRIAR PERFIL
      // ======================================================

      if (updatedRows == 0) {
        await db.insert('user_profile', {
          'id': userId,
          'name': normalizedUsername,
          'artist_name': normalizedArtistName,
          'wallet': normalizedWalletAddress,
          'synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      debugPrint(
        '[VERSIN AUTH] '
        'Perfil sincronizado no SQLite.',
      );
    } catch (error) {
      debugPrint(
        '[VERSIN AUTH] '
        'Erro ao salvar perfil local: $error',
      );

      rethrow;
    }
  }

  // ==========================================================
  // SALVAR NOME ARTÍSTICO
  // ==========================================================

  @override
  Future<void> saveArtistName({
    required String userId,
    required String artistName,
  }) async {
    final normalizedArtistName = artistName.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    if (normalizedArtistName.isEmpty) {
      throw ArgumentError('O nome artístico não pode ser vazio.');
    }

    if (!_supportsLocalDatabase) {
      debugPrint(
        '[VERSIN AUTH] '
        'Cache SQLite ignorado no Web ao salvar '
        'nome artístico.',
      );

      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;

      // ======================================================
      // ATUALIZAR
      // ======================================================

      final updatedRows = await db.update(
        'user_profile',
        {'artist_name': normalizedArtistName, 'synced': 1},
        where: 'id = ?',
        whereArgs: [userId],
      );

      // ======================================================
      // PERFIL AINDA NÃO EXISTE
      // ======================================================

      if (updatedRows == 0) {
        await db.insert('user_profile', {
          'id': userId,
          'name': '',
          'artist_name': normalizedArtistName,
          'wallet': '',
          'synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      debugPrint(
        '[VERSIN AUTH] '
        'Nome artístico salvo localmente: '
        '$normalizedArtistName',
      );
    } catch (error) {
      debugPrint(
        '[VERSIN AUTH] '
        'Erro ao salvar nome artístico '
        'no SQLite: $error',
      );

      rethrow;
    }
  }

  // ==========================================================
  // BUSCAR NOME ARTÍSTICO
  // ==========================================================

  @override
  Future<String?> getArtistName(String userId) async {
    if (!_supportsLocalDatabase) {
      debugPrint(
        '[VERSIN AUTH] '
        'Consulta SQLite ignorada no Web.',
      );

      return null;
    }

    try {
      final db = await DatabaseHelper.instance.database;

      final result = await db.query(
        'user_profile',
        columns: ['artist_name'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (result.isEmpty) {
        debugPrint(
          '[VERSIN AUTH] '
          'Perfil local não encontrado '
          'para artist_name.',
        );

        return null;
      }

      final value = result.first['artist_name'];

      if (value == null) {
        return null;
      }

      final artistName = value.toString().trim();

      if (artistName.isEmpty) {
        return null;
      }

      debugPrint(
        '[VERSIN AUTH] '
        'Nome artístico carregado '
        'do SQLite: $artistName',
      );

      return artistName;
    } catch (error) {
      debugPrint(
        '[VERSIN AUTH] '
        'Erro ao buscar nome artístico '
        'no SQLite: $error',
      );

      return null;
    }
  }

  // ==========================================================
  // LIMPAR PERFIL LOCAL
  // ==========================================================

  @override
  Future<void> clearLocalProfile() async {
    // ========================================================
    // WEB
    // ========================================================
    //
    // Não existe cache SQLite nesta implementação Web.
    //
    // O logout remoto já foi realizado pelo
    // AuthRemoteDatasource.
    //
    // ========================================================

    if (!_supportsLocalDatabase) {
      debugPrint(
        '[VERSIN AUTH] '
        'Limpeza SQLite ignorada no Web.',
      );

      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;

      await db.delete('user_profile');

      debugPrint(
        '[VERSIN AUTH] '
        'Perfil local removido.',
      );
    } catch (error) {
      debugPrint(
        '[VERSIN AUTH] '
        'Erro ao remover perfil local: $error',
      );

      rethrow;
    }
  }
}
