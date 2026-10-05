import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/transfer_recipient_model.dart';

// ============================================================
// AUTHORSHIP TRANSFER SERVICE
// ============================================================
//
// Responsável por:
//
// - pesquisar usuários;
// - resolver @username -> userId;
// - resolver UUID -> usuário;
// - retornar TransferRecipientModel;
// - preparar destinatários para transferência de autoria.
//
// A transferência da obra continua sendo responsabilidade de:
//
// TransferAuthorshipPage
//        ↓
// StorageController
//        ↓
// StorageRepository
//        ↓
// backend
//
// ============================================================

class AuthorshipTransferService {
  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  AuthorshipTransferService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // ==========================================================
  // USUÁRIO ATUAL
  // ==========================================================

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ==========================================================
  // NORMALIZAR PESQUISA
  // ==========================================================

  String normalizeQuery(String query) {
    return query.trim().replaceFirst(RegExp(r'^@+'), '').trim();
  }

  // ==========================================================
  // BUSCAR UM USUÁRIO
  // ==========================================================
  //
  // Aceita:
  //
  // @joao
  // joao
  // UUID
  //
  // ==========================================================

  Future<TransferRecipientModel?> findUser(
    String query, {
    bool excludeCurrentUser = true,
  }) async {
    final normalized = normalizeQuery(query);

    if (normalized.isEmpty) {
      return null;
    }

    TransferRecipientModel? recipient;

    if (_looksLikeUuid(normalized)) {
      recipient = await findUserById(normalized);
    } else {
      recipient = await findUserByUsername(normalized);
    }

    if (recipient == null) {
      return null;
    }

    if (excludeCurrentUser && _isCurrentUser(recipient.userId)) {
      return null;
    }

    return recipient;
  }

  // ==========================================================
  // BUSCAR POR USERNAME
  // ==========================================================

  Future<TransferRecipientModel?> findUserByUsername(String username) async {
    final normalized = normalizeQuery(username);

    if (normalized.isEmpty) {
      return null;
    }

    try {
      final result = await _supabase
          .from('profiles')
          .select('id, username, display_name, avatar_url')
          .ilike('username', normalized)
          .maybeSingle();

      if (result == null) {
        return null;
      }

      return _mapRecipient(result);
    } on PostgrestException catch (error) {
      throw AuthorshipTransferException(
        message: 'Não foi possível pesquisar o usuário.',
        code: error.code,
        details: error.message,
      );
    } catch (error) {
      throw AuthorshipTransferException(
        message: 'Erro ao pesquisar usuário.',
        details: error.toString(),
      );
    }
  }

  // ==========================================================
  // BUSCAR POR ID
  // ==========================================================

  Future<TransferRecipientModel?> findUserById(String userId) async {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    try {
      final result = await _supabase
          .from('profiles')
          .select('id, username, display_name, avatar_url')
          .eq('id', normalized)
          .maybeSingle();

      if (result == null) {
        return null;
      }

      return _mapRecipient(result);
    } on PostgrestException catch (error) {
      throw AuthorshipTransferException(
        message: 'Não foi possível localizar o usuário.',
        code: error.code,
        details: error.message,
      );
    } catch (error) {
      throw AuthorshipTransferException(
        message: 'Erro ao localizar usuário.',
        details: error.toString(),
      );
    }
  }

  // ==========================================================
  // PESQUISAR USUÁRIOS
  // ==========================================================
  //
  // Usado para autocomplete.
  //
  // Exemplo:
  //
  // jo
  //
  // João Vitor
  // @joao
  //
  // João Pedro
  // @joaopedro
  //
  // ==========================================================

  Future<List<TransferRecipientModel>> searchUsers(
    String query, {
    int limit = 8,
    bool excludeCurrentUser = true,
  }) async {
    final normalized = normalizeQuery(query);

    if (normalized.isEmpty) {
      return const [];
    }

    final safeLimit = limit.clamp(1, 20);

    try {
      final response = await _supabase
          .from('profiles')
          .select('id, username, display_name, avatar_url')
          .or(
            'username.ilike.%$normalized%,'
            'display_name.ilike.%$normalized%',
          )
          .order('username', ascending: true)
          .limit(safeLimit);

      final results = <TransferRecipientModel>[];

      for (final item in response) {
        final recipient = _mapRecipient(Map<String, dynamic>.from(item));

        if (recipient == null) {
          continue;
        }

        if (excludeCurrentUser && _isCurrentUser(recipient.userId)) {
          continue;
        }

        results.add(recipient);
      }

      return results;
    } on PostgrestException catch (error) {
      throw AuthorshipTransferException(
        message: 'Não foi possível pesquisar usuários.',
        code: error.code,
        details: error.message,
      );
    } catch (error) {
      throw AuthorshipTransferException(
        message: 'Erro ao pesquisar usuários.',
        details: error.toString(),
      );
    }
  }

  // ==========================================================
  // VERIFICAR SE USUÁRIO EXISTE
  // ==========================================================

  Future<bool> userExists(String userId) async {
    final user = await findUserById(userId);

    return user != null;
  }

  // ==========================================================
  // MAPEAR USUÁRIO
  // ==========================================================

  TransferRecipientModel? _mapRecipient(Map<String, dynamic> data) {
    final recipient = TransferRecipientModel.fromMap(data);

    if (!recipient.isValid) {
      return null;
    }

    return recipient;
  }

  // ==========================================================
  // USUÁRIO ATUAL?
  // ==========================================================

  bool _isCurrentUser(String userId) {
    final current = currentUserId;

    if (current == null || current.isEmpty) {
      return false;
    }

    return current == userId.trim();
  }

  // ==========================================================
  // DETECTAR UUID
  // ==========================================================

  bool _looksLikeUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-'
      r'[0-9a-fA-F]{4}-'
      r'[1-5][0-9a-fA-F]{3}-'
      r'[89abAB][0-9a-fA-F]{3}-'
      r'[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}

// ============================================================
// EXCEPTION
// ============================================================

class AuthorshipTransferException implements Exception {
  final String message;

  final String? code;

  final String? details;

  const AuthorshipTransferException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() {
    final buffer = StringBuffer(message);

    if (code != null && code!.isNotEmpty) {
      buffer.write(' [$code]');
    }

    if (details != null && details!.isNotEmpty) {
      buffer.write(' $details');
    }

    return buffer.toString();
  }
}
