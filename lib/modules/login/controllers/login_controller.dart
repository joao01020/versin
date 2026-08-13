import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/login/data/repositories/auth_repository_impl.dart';
import 'package:versin/modules/login/domain/repositories/auth_repository.dart';

class LoginController {
  final AuthRepository _authRepository;

  LoginController({
    AuthRepository? authRepository,
  }) : _authRepository =
           authRepository ??
           AuthRepositoryImpl();

  // ============================================================
  // FORM
  // ============================================================

  final formKey =
      GlobalKey<
        FormState
      >();

  // ============================================================
  // AUTH
  // ============================================================

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  // ============================================================
  // PERFIL
  // ============================================================

  final nameController = TextEditingController();

  final userController = TextEditingController();

  final walletController = TextEditingController();

  // ============================================================
  // ESTADOS
  // ============================================================

  final ValueNotifier<
    bool
  >
  isLocalFieldsExpanded =
      ValueNotifier<
        bool
      >(
        false,
      );

  final ValueNotifier<
    bool
  >
  isUsernameAvailable =
      ValueNotifier<
        bool
      >(
        false,
      );

  final ValueNotifier<
    bool
  >
  isNameRepresented =
      ValueNotifier<
        bool
      >(
        false,
      );

  final ValueNotifier<
    bool
  >
  isLoading =
      ValueNotifier<
        bool
      >(
        false,
      );

  final ValueNotifier<
    String?
  >
  errorMessage =
      ValueNotifier<
        String?
      >(
        null,
      );

  final ValueNotifier<
    String?
  >
  artistName =
      ValueNotifier<
        String?
      >(
        null,
      );

  // ============================================================
  // INTERNO
  // ============================================================

  Timer? _debounce;

  bool _disposed = false;

  // ============================================================
  // BYPASS DEV
  // ============================================================

  void bypassToDashboard(
    BuildContext context,
  ) {
    Navigator.pushReplacementNamed(
      context,
      '/dashboard',
    );
  }

  // ============================================================
  // LISTENERS
  // ============================================================

  void initListeners() {
    if (_disposed) {
      return;
    }

    userController.addListener(
      _onUsernameChanged,
    );
  }

  void _onUsernameChanged() {
    if (_disposed) {
      return;
    }

    final username = userController.text.trim().toLowerCase();

    if (username.isEmpty) {
      walletController.clear();

      _setUsernameAvailable(
        false,
      );

      _setNameRepresented(
        false,
      );

      return;
    }

    walletController.text = 'wallet@$username';

    _runDebounceCheck(
      username,
    );
  }

  // ============================================================
  // USERNAME
  // ============================================================

  void _runDebounceCheck(
    String username,
  ) {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(
        milliseconds: 500,
      ),
      () async {
        if (_disposed) {
          return;
        }

        try {
          final isTaken = await _authRepository.isUsernameTaken(
            username,
          );

          if (_disposed) {
            return;
          }

          _setUsernameAvailable(
            !isTaken,
          );
        } catch (
          error
        ) {
          if (_disposed) {
            return;
          }

          _setUsernameAvailable(
            false,
          );

          debugPrint(
            '[VERSIN AUTH] Erro ao verificar username: $error',
          );
        }
      },
    );
  }

  // ============================================================
  // UI
  // ============================================================

  void toggleLocalFields() {
    if (_disposed) {
      return;
    }

    isLocalFieldsExpanded.value = !isLocalFieldsExpanded.value;
  }

  void setIdentityRepresentation(
    bool value,
  ) {
    _setNameRepresented(
      value,
    );
  }

  void clearError() {
    _setError(
      null,
    );
  }

  // ============================================================
  // LOGIN EMAIL
  // ============================================================

  Future<
    bool
  >
  loginWithEmail() async {
    if (_disposed ||
        isLoading.value) {
      return false;
    }

    final email = emailController.text.trim();

    final password = passwordController.text;

    if (email.isEmpty) {
      _setError(
        'Informe seu email.',
      );

      return false;
    }

    if (password.isEmpty) {
      _setError(
        'Informe sua senha.',
      );

      return false;
    }

    _setLoading(
      true,
    );

    _setError(
      null,
    );

    try {
      final success = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );

      if (_disposed) {
        return success;
      }

      if (!success) {
        _setError(
          'Email ou senha inválidos.',
        );

        return false;
      }

      // ========================================================
      // CARREGAR NOME ARTÍSTICO
      // ========================================================

      final currentArtistName = await _authRepository.getArtistName();

      if (!_disposed) {
        _setArtistName(
          currentArtistName,
        );
      }

      return true;
    } on AuthException catch (
      error
    ) {
      debugPrint(
        '[VERSIN AUTH] Login falhou: ${error.message}',
      );

      if (!_disposed) {
        _setError(
          _translateAuthError(
            error,
          ),
        );
      }

      return false;
    } catch (
      error
    ) {
      debugPrint(
        '[VERSIN AUTH] Erro inesperado no login: $error',
      );

      if (!_disposed) {
        _setError(
          'Não foi possível entrar agora.',
        );
      }

      return false;
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // CADASTRO EMAIL
  // ============================================================

  Future<
    bool
  >
  createAccountWithEmail() async {
    if (_disposed ||
        isLoading.value) {
      return false;
    }

    final email = emailController.text.trim();

    final password = passwordController.text;

    if (email.isEmpty) {
      _setError(
        'Informe seu email.',
      );

      return false;
    }

    if (!_isValidEmail(
      email,
    )) {
      _setError(
        'Informe um email válido.',
      );

      return false;
    }

    if (password.length <
        6) {
      _setError(
        'A senha deve ter pelo menos 6 caracteres.',
      );

      return false;
    }

    _setLoading(
      true,
    );

    _setError(
      null,
    );

    try {
      final success = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
      );

      if (_disposed) {
        return success;
      }

      if (!success) {
        _setError(
          'Não foi possível criar a conta.',
        );
      }

      return success;
    } on AuthException catch (
      error
    ) {
      debugPrint(
        '[VERSIN AUTH] Cadastro falhou: ${error.message}',
      );

      if (!_disposed) {
        _setError(
          _translateAuthError(
            error,
          ),
        );
      }

      return false;
    } catch (
      error
    ) {
      debugPrint(
        '[VERSIN AUTH] Erro inesperado no cadastro: $error',
      );

      if (!_disposed) {
        _setError(
          'Não foi possível criar a conta agora.',
        );
      }

      return false;
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // NOME ARTÍSTICO
  // ============================================================

  Future<
    String?
  >
  getArtistName() async {
    if (_disposed) {
      return null;
    }

    try {
      final value = await _authRepository.getArtistName();

      if (!_disposed) {
        _setArtistName(
          value,
        );
      }

      return value;
    } catch (
      error
    ) {
      debugPrint(
        '[VERSIN PROFILE] Erro ao buscar nome artístico: $error',
      );

      return null;
    }
  }

  Future<
    bool
  >
  hasArtistName() async {
    if (_disposed) {
      return false;
    }

    try {
      final hasName = await _authRepository.hasArtistName();

      if (!hasName) {
        _setArtistName(
          null,
        );
      }

      return hasName;
    } catch (
      error
    ) {
      debugPrint(
        '[VERSIN PROFILE] Erro ao verificar nome artístico: $error',
      );

      return false;
    }
  }

  Future<
    bool
  >
  saveArtistName(
    String value,
  ) async {
    if (_disposed ||
        isLoading.value) {
      return false;
    }

    final normalizedName = value.trim().replaceAll(
      RegExp(
        r'\s+',
      ),
      ' ',
    );

    if (normalizedName.isEmpty) {
      _setError(
        'Digite seu nome artístico.',
      );

      return false;
    }

    if (normalizedName.length <
        2) {
      _setError(
        'O nome artístico deve ter pelo menos 2 caracteres.',
      );

      return false;
    }

    if (normalizedName.length >
        40) {
      _setError(
        'O nome artístico deve ter no máximo 40 caracteres.',
      );

      return false;
    }

    _setLoading(
      true,
    );

    _setError(
      null,
    );

    try {
      final success = await _authRepository.saveArtistName(
        normalizedName,
      );

      if (_disposed) {
        return success;
      }

      if (!success) {
        _setError(
          'Não foi possível salvar o nome artístico.',
        );

        return false;
      }

      _setArtistName(
        normalizedName,
      );

      debugPrint(
        '[VERSIN PROFILE] Nome artístico definido: '
        '$normalizedName',
      );

      return true;
    } catch (
      error
    ) {
      debugPrint(
        '[VERSIN PROFILE] Erro ao salvar nome artístico: $error',
      );

      if (!_disposed) {
        _setError(
          'Não foi possível salvar o nome artístico.',
        );
      }

      return false;
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // GOOGLE
  // ============================================================

  Future<
    void
  >
  loginWithGoogle() async {
    if (_disposed ||
        isLoading.value) {
      return;
    }

    _setLoading(
      true,
    );

    _setError(
      null,
    );

    try {
      await _authRepository.signInWithOAuth(
        OAuthProvider.google,
      );
    } catch (
      error
    ) {
      debugPrint(
        '[VERSIN AUTH] OAuth Google falhou: $error',
      );

      if (!_disposed) {
        _setError(
          'Não foi possível entrar com Google.',
        );
      }
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // GITHUB
  // ============================================================

  Future<
    void
  >
  loginWithGitHub() async {
    if (_disposed ||
        isLoading.value) {
      return;
    }

    _setLoading(
      true,
    );

    _setError(
      null,
    );

    try {
      await _authRepository.signInWithOAuth(
        OAuthProvider.github,
      );
    } catch (
      error
    ) {
      debugPrint(
        '[VERSIN AUTH] OAuth GitHub falhou: $error',
      );

      if (!_disposed) {
        _setError(
          'Não foi possível entrar com GitHub.',
        );
      }
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // PERFIL LOCAL
  // ============================================================

  Future<
    bool
  >
  registerCustomProfile() async {
    if (_disposed) {
      return false;
    }

    final form = formKey.currentState;

    if (form ==
            null ||
        !form.validate() ||
        !isNameRepresented.value) {
      return false;
    }

    final username = userController.text.trim();

    if (username.isEmpty ||
        !isUsernameAvailable.value) {
      _setError(
        'Escolha um username disponível.',
      );

      return false;
    }

    if (isLoading.value) {
      return false;
    }

    _setLoading(
      true,
    );

    _setError(
      null,
    );

    try {
      final success = await _authRepository.registerLocalChassi(
        username: username,
        displayName: nameController.text.trim(),
        walletAddress: walletController.text.trim(),
      );

      if (_disposed) {
        return success;
      }

      if (!success) {
        _setError(
          'Você precisa estar autenticado para criar o perfil.',
        );
      }

      return success;
    } catch (
      error
    ) {
      debugPrint(
        '[VERSIN AUTH] Falha ao registrar perfil: $error',
      );

      if (!_disposed) {
        _setError(
          'Não foi possível criar o perfil.',
        );
      }

      return false;
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<
    bool
  >
  logout() async {
    if (_disposed ||
        isLoading.value) {
      return false;
    }

    _setLoading(
      true,
    );

    _setError(
      null,
    );

    try {
      await _authRepository.signOut();

      if (!_disposed) {
        _setArtistName(
          null,
        );
      }

      return true;
    } catch (
      error
    ) {
      debugPrint(
        '[VERSIN AUTH] Logout falhou: $error',
      );

      if (!_disposed) {
        _setError(
          'Não foi possível sair da conta.',
        );
      }

      return false;
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // USER ID
  // ============================================================

  Future<
    String?
  >
  getCurrentUserId() {
    return _authRepository.getCurrentUserId();
  }

  // ============================================================
  // HELPERS DE ESTADO
  // ============================================================

  void _setLoading(
    bool value,
  ) {
    if (_disposed) {
      return;
    }

    isLoading.value = value;
  }

  void _setError(
    String? message,
  ) {
    if (_disposed) {
      return;
    }

    errorMessage.value = message;
  }

  void _setUsernameAvailable(
    bool value,
  ) {
    if (_disposed) {
      return;
    }

    isUsernameAvailable.value = value;
  }

  void _setNameRepresented(
    bool value,
  ) {
    if (_disposed) {
      return;
    }

    isNameRepresented.value = value;
  }

  void _setArtistName(
    String? value,
  ) {
    if (_disposed) {
      return;
    }

    final normalized = value?.trim();

    artistName.value =
        normalized ==
                null ||
            normalized.isEmpty
        ? null
        : normalized;
  }

  // ============================================================
  // VALIDAÇÕES
  // ============================================================

  bool _isValidEmail(
    String email,
  ) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(
      email,
    );
  }

  String _translateAuthError(
    AuthException error,
  ) {
    final message = error.message.toLowerCase();

    if (message.contains(
      'invalid login credentials',
    )) {
      return 'Email ou senha inválidos.';
    }

    if (message.contains(
      'email not confirmed',
    )) {
      return 'Confirme seu email antes de entrar.';
    }

    if (message.contains(
      'user already registered',
    )) {
      return 'Este email já possui uma conta.';
    }

    if (message.contains(
      'password',
    )) {
      return 'A senha informada não é válida.';
    }

    if (message.contains(
      'email',
    )) {
      return 'O email informado não é válido.';
    }

    return error.message;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _debounce?.cancel();

    _debounce = null;

    userController.removeListener(
      _onUsernameChanged,
    );

    nameController.dispose();
    userController.dispose();
    walletController.dispose();

    emailController.dispose();
    passwordController.dispose();

    isLocalFieldsExpanded.dispose();
    isUsernameAvailable.dispose();
    isNameRepresented.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    artistName.dispose();
  }
}
