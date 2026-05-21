import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/modules/login/domain/repositories/auth_repository.dart';
import 'package:versin/modules/login/data/repositories/auth_repository_impl.dart';

class LoginController {
  final AuthRepository _authRepository;

  // Inversão de dependência pronta para o ecossistema modular do Versin
  LoginController({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepositoryImpl();

  final formKey = GlobalKey<FormState>();

  // Controles de Entrada (Inputs)
  final nameController = TextEditingController();
  final userController = TextEditingController();
  final walletController = TextEditingController();

  // Estados Reativos com ValueNotifier (UI reage em tempo real sem setState global)
  final ValueNotifier<bool> isLocalFieldsExpanded = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isUsernameAvailable = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isNameRepresented = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  Timer? _debounce;

  void initListeners() {
    userController.addListener(() {
      final text = userController.text.trim().toLowerCase();
      if (text.isNotEmpty) {
        walletController.text = "wallet@$text";
        _runDebounceCheck(text);
      } else {
        walletController.text = "";
        isUsernameAvailable.value = false;
        isNameRepresented.value = false;
      }
    });
  }

  void _runDebounceCheck(String username) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Debounce de 500ms para evitar sobrecarga de requisições na API do Supabase
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final isTaken = await _authRepository.isUsernameTaken(username);
      isUsernameAvailable.value = !isTaken;
    });
  }

  void toggleLocalFields() {
    isLocalFieldsExpanded.value = !isLocalFieldsExpanded.value;
  }

  void setIdentityRepresentation(bool value) {
    isNameRepresented.value = value;
  }

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      await _authRepository.signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      debugPrint("Versin-auth [UI Error]: OAuth Google falhou: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGitHub() async {
    try {
      isLoading.value = true;
      await _authRepository.signInWithOAuth(OAuthProvider.github);
    } catch (e) {
      debugPrint("Versin-auth [UI Error]: OAuth GitHub falhou: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> registerCustomProfile() async {
    if (!formKey.currentState!.validate() || !isNameRepresented.value) {
      return false;
    }

    final username = userController.text.trim();
    if (username.isEmpty || !isUsernameAvailable.value) return false;

    isLoading.value = true;
    try {
      final success = await _authRepository.registerLocalChassi(
        username: username,
        displayName: nameController.text.trim(),
        walletAddress: walletController.text,
      );
      isLoading.value = false;
      return success;
    } catch (e) {
      debugPrint("Versin-auth [UI Error]: Falha ao registrar chassi: $e");
      isLoading.value = false;
      return false;
    }
  }

  void dispose() {
    nameController.dispose();
    userController.dispose();
    walletController.dispose();
    isLocalFieldsExpanded.dispose();
    isUsernameAvailable.dispose();
    isNameRepresented.dispose();
    isLoading.dispose();
    _debounce?.cancel();
  }
}