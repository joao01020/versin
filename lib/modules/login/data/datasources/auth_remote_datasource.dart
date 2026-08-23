import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// AUTH REMOTE DATASOURCE
// ============================================================

abstract class AuthRemoteDatasource {
  // ==========================================================
  // EMAIL
  // ==========================================================

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? username,
    String? displayName,
  });

  // ==========================================================
  // OAUTH
  // ==========================================================

  Future<void> signInWithOAuth(OAuthProvider provider);

  // ==========================================================
  // SESSÃO
  // ==========================================================

  Future<void> signOut();

  Future<User?> getCurrentUser();

  // ==========================================================
  // PERFIL
  // ==========================================================

  Future<Map<String, dynamic>?> getRemoteProfile(String userId);

  Future<String?> getArtistName(String userId);

  Future<void> saveArtistName({
    required String userId,
    required String artistName,
  });

  Future<bool> isUsernameTaken(String username);
}

// ============================================================
// IMPLEMENTAÇÃO
// ============================================================

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================================
  // LOGIN COM EMAIL
  // ==========================================================

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    debugPrint('[VERSIN AUTH] Tentando login: $normalizedEmail');

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      debugPrint('[VERSIN AUTH] Login realizado.');

      debugPrint('[VERSIN AUTH] User ID: ${response.user?.id}');

      debugPrint('[VERSIN AUTH] Email: ${response.user?.email}');

      debugPrint('[VERSIN AUTH] Sessão: ${response.session != null}');

      return response;
    } on AuthException catch (error) {
      debugPrint('[VERSIN AUTH] Login AuthException:');

      debugPrint('[VERSIN AUTH] Mensagem: ${error.message}');

      debugPrint('[VERSIN AUTH] Status: ${error.statusCode}');

      rethrow;
    } catch (error) {
      debugPrint('[VERSIN AUTH] Erro inesperado no login: $error');

      rethrow;
    }
  }

  // ==========================================================
  // CRIAR CONTA COM EMAIL
  // ==========================================================

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? username,
    String? displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    debugPrint('[VERSIN AUTH] ========================================');

    debugPrint('[VERSIN AUTH] INICIANDO CADASTRO');

    debugPrint('[VERSIN AUTH] Email: $normalizedEmail');

    debugPrint('[VERSIN AUTH] ========================================');

    try {
      final response = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          if (username != null && username.trim().isNotEmpty)
            'username': username.trim(),

          if (displayName != null && displayName.trim().isNotEmpty)
            'display_name': displayName.trim(),
        },
      );

      final user = response.user;

      final session = response.session;

      debugPrint('[VERSIN AUTH] Cadastro retornado pelo Supabase.');

      debugPrint('[VERSIN AUTH] User ID: ${user?.id}');

      debugPrint('[VERSIN AUTH] Email: ${user?.email}');

      debugPrint('[VERSIN AUTH] Usuário criado: ${user != null}');

      debugPrint('[VERSIN AUTH] Sessão criada: ${session != null}');

      debugPrint(
        '[VERSIN AUTH] Email confirmado: '
        '${user?.emailConfirmedAt != null}',
      );

      if (user == null) {
        debugPrint('[VERSIN AUTH] ATENÇÃO: Supabase não retornou usuário.');
      }

      if (user != null && session == null) {
        debugPrint(
          '[VERSIN AUTH] Conta criada aguardando confirmação de email.',
        );
      }

      if (user != null && session != null) {
        debugPrint('[VERSIN AUTH] Conta criada e autenticada.');
      }

      debugPrint('[VERSIN AUTH] ========================================');

      return response;
    } on AuthException catch (error) {
      debugPrint('[VERSIN AUTH] ========================================');

      debugPrint('[VERSIN AUTH] CADASTRO FALHOU');

      debugPrint('[VERSIN AUTH] Mensagem: ${error.message}');

      debugPrint('[VERSIN AUTH] Status: ${error.statusCode}');

      debugPrint('[VERSIN AUTH] ========================================');

      rethrow;
    } catch (error) {
      debugPrint('[VERSIN AUTH] ========================================');

      debugPrint('[VERSIN AUTH] ERRO INESPERADO NO CADASTRO');

      debugPrint('[VERSIN AUTH] $error');

      debugPrint('[VERSIN AUTH] ========================================');

      rethrow;
    }
  }

  // ==========================================================
  // OAUTH
  // ==========================================================

  @override
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    // ========================================================
    // REDIRECT OAUTH
    // ========================================================
    //
    // WEB:
    //
    // O callback volta para a raiz do Versin:
    //
    // http://localhost:8080
    //
    // Em produção, Uri.base.origin passa automaticamente a
    // representar o domínio real.
    //
    // A raiz é controlada pelo AuthWrapper, que decide entre:
    //
    // - LoginPage;
    // - DashboardPage.
    //
    // Isso evita retornar diretamente para /dashboard antes de
    // a sessão OAuth estar restaurada.
    //
    // DESKTOP:
    //
    // O callback utiliza o protocolo customizado do Versin:
    //
    // versin://auth/callback
    //
    // ========================================================

    final redirectTo = kIsWeb ? Uri.base.origin : 'versin://auth/callback';

    debugPrint(
      '[VERSIN AUTH] '
      'Iniciando OAuth com ${provider.name}.',
    );

    debugPrint(
      '[VERSIN AUTH] '
      'OAuth redirect: $redirectTo',
    );

    try {
      final started = await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo: redirectTo,
      );

      debugPrint(
        '[VERSIN AUTH] '
        'OAuth iniciado: $started',
      );
    } on AuthException catch (error) {
      debugPrint(
        '[VERSIN AUTH] '
        'OAuth falhou: ${error.message}',
      );

      debugPrint(
        '[VERSIN AUTH] '
        'Status: ${error.statusCode}',
      );

      rethrow;
    } catch (error, stackTrace) {
      debugPrint(
        '[VERSIN AUTH] '
        'Erro inesperado ao iniciar OAuth: $error',
      );

      debugPrint('$stackTrace');

      rethrow;
    }
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();

      debugPrint('[VERSIN AUTH] Logout realizado.');
    } on AuthException catch (error) {
      debugPrint('[VERSIN AUTH] Logout falhou: ${error.message}');

      rethrow;
    }
  }

  // ==========================================================
  // USUÁRIO ATUAL
  // ==========================================================

  @override
  Future<User?> getCurrentUser() async {
    return _supabase.auth.currentUser;
  }

  // ==========================================================
  // PERFIL REMOTO
  // ==========================================================

  @override
  Future<Map<String, dynamic>?> getRemoteProfile(String userId) async {
    try {
      return await _supabase
          .from('profiles')
          .select(
            'username, '
            'artist_name, '
            'artist_name_updated_at, '
            'wallet_address',
          )
          .eq('id', userId)
          .maybeSingle();
    } catch (error) {
      debugPrint('[VERSIN AUTH] Erro ao buscar perfil: $error');

      rethrow;
    }
  }

  // ==========================================================
  // BUSCAR NOME ARTÍSTICO
  // ==========================================================

  @override
  Future<String?> getArtistName(String userId) async {
    try {
      final result = await _supabase
          .from('profiles')
          .select('artist_name')
          .eq('id', userId)
          .maybeSingle();

      if (result == null) {
        return null;
      }

      final value = result['artist_name'];

      if (value == null) {
        return null;
      }

      final artistName = value.toString().trim();

      if (artistName.isEmpty) {
        return null;
      }

      return artistName;
    } catch (error) {
      debugPrint('[VERSIN AUTH] Erro ao buscar nome artístico: $error');

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

    try {
      await _supabase.from('profiles').upsert({
        'id': userId,

        'artist_name': normalizedArtistName,

        'artist_name_updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'id');

      debugPrint(
        '[VERSIN AUTH] Nome artístico salvo remotamente: '
        '$normalizedArtistName',
      );
    } on PostgrestException catch (error) {
      debugPrint(
        '[VERSIN AUTH] Erro Supabase ao salvar '
        'nome artístico: ${error.message}',
      );

      rethrow;
    } catch (error) {
      debugPrint('[VERSIN AUTH] Erro ao salvar nome artístico: $error');

      rethrow;
    }
  }

  // ==========================================================
  // VERIFICAR USERNAME
  // ==========================================================

  @override
  Future<bool> isUsernameTaken(String username) async {
    final normalizedUsername = username.trim().toLowerCase();

    if (normalizedUsername.isEmpty) {
      return false;
    }

    try {
      final result = await _supabase
          .from('profiles')
          .select('username')
          .eq('username', normalizedUsername)
          .maybeSingle();

      return result != null;
    } catch (error) {
      debugPrint('[VERSIN AUTH] Erro ao verificar username: $error');

      rethrow;
    }
  }
}
