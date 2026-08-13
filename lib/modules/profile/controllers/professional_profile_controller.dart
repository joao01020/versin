import 'package:flutter/foundation.dart';

import 'package:versin/modules/profile/data/repositories/professional_profile_repository_impl.dart';
import 'package:versin/modules/profile/models/music_role.dart';
import 'package:versin/modules/profile/models/professional_profile_model.dart';
import 'package:versin/modules/profile/repositories/professional_profile_repository.dart';

// ============================================================
// PROFESSIONAL PROFILE CONTROLLER
// ============================================================
//
// Responsabilidades:
//
// - carregar o perfil profissional completo;
// - controlar funções exercidas;
// - controlar função principal;
// - controlar profissionais procurados;
// - validar os dados;
// - controlar loading;
// - controlar salvamento;
// - controlar mensagens;
// - chamar Repository.
//
// NÃO acessa diretamente:
//
// - Supabase;
// - SQLite;
// - API.
//
// Fluxo:
//
// View / Dashboard
//        ↓
// ProfessionalProfileController
//        ↓
// ProfessionalProfileRepository
//        ↓
// ProfessionalProfileRepositoryImpl
//        ↓
// ProfessionalProfileRemoteDatasource
//        ↓
// Supabase
//
// ============================================================

class ProfessionalProfileController
    extends
        ChangeNotifier {
  // ============================================================
  // DEPENDÊNCIA
  // ============================================================

  final ProfessionalProfileRepository _repository;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  ProfessionalProfileController({
    ProfessionalProfileRepository? repository,
  }) : _repository =
           repository ??
           ProfessionalProfileRepositoryImpl();

  // ============================================================
  // ESTADO
  // ============================================================

  final Set<
    MusicRole
  >
  _selectedRoles = {};

  final Set<
    MusicRole
  >
  _lookingForRoles = {};

  MusicRole? _primaryRole;

  bool _isLoading = false;

  bool _isSaving = false;

  bool _hasLoaded = false;

  String? _errorMessage;

  String? _successMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  Set<
    MusicRole
  >
  get selectedRoles => Set.unmodifiable(
    _selectedRoles,
  );

  Set<
    MusicRole
  >
  get lookingForRoles => Set.unmodifiable(
    _lookingForRoles,
  );

  MusicRole? get primaryRole => _primaryRole;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  bool get hasLoaded => _hasLoaded;

  String? get errorMessage => _errorMessage;

  String? get successMessage => _successMessage;

  bool get hasSelectedRoles => _selectedRoles.isNotEmpty;

  bool get hasLookingForRoles => _lookingForRoles.isNotEmpty;

  bool get canSave =>
      !_isLoading &&
      !_isSaving &&
      _selectedRoles.isNotEmpty &&
      _primaryRole !=
          null;

  // ============================================================
  // LABEL DA FUNÇÃO PRINCIPAL
  // ============================================================

  String get primaryRoleLabel {
    final role = _primaryRole;

    if (role ==
        null) {
      return 'Não informado';
    }

    final label = role.label.trim();

    if (label.isEmpty) {
      return 'Não informado';
    }

    return label;
  }

  // ============================================================
  // LABELS DOS PROFISSIONAIS PROCURADOS
  // ============================================================

  List<
    String
  >
  get lookingForRoleLabels {
    return MusicRole.toLabels(
      _lookingForRoles,
    );
  }

  // ============================================================
  // MODEL ATUAL
  // ============================================================

  ProfessionalProfileModel get profile {
    return ProfessionalProfileModel(
      roles: _selectedRoles.toList(),

      primaryRole: _primaryRole,

      lookingForRoles: _lookingForRoles.toList(),
    );
  }

  // ============================================================
  // CARREGAR PERFIL
  // ============================================================

  Future<
    void
  >
  load({
    bool force = false,
  }) async {
    if (_isLoading) {
      return;
    }

    if (_hasLoaded &&
        !force) {
      return;
    }

    _isLoading = true;

    _errorMessage = null;

    notifyListeners();

    try {
      // ========================================================
      // BUSCAR PERFIL COMPLETO
      // ========================================================

      final loadedProfile = await _repository.getProfessionalProfile();

      // ========================================================
      // FUNÇÕES
      // ========================================================

      _selectedRoles
        ..clear()
        ..addAll(
          loadedProfile.roles,
        );

      // ========================================================
      // QUEM PROCURA
      // ========================================================

      _lookingForRoles
        ..clear()
        ..addAll(
          loadedProfile.lookingForRoles,
        );

      // ========================================================
      // FUNÇÃO PRINCIPAL
      // ========================================================

      final loadedPrimaryRole = loadedProfile.primaryRole;

      if (loadedPrimaryRole !=
              null &&
          _selectedRoles.contains(
            loadedPrimaryRole,
          )) {
        _primaryRole = loadedPrimaryRole;
      } else {
        _primaryRole = _selectedRoles.isEmpty
            ? null
            : _selectedRoles.first;
      }

      _hasLoaded = true;

      debugPrint(
        '[PROFILE CONTROLLER] Perfil profissional carregado.',
      );

      debugPrint(
        '[PROFILE CONTROLLER] Função principal: '
        '${_primaryRole?.key ?? "não informado"}',
      );

      debugPrint(
        '[PROFILE CONTROLLER] Habilidades: '
        '${_selectedRoles.map((role) => role.key).toList()}',
      );

      debugPrint(
        '[PROFILE CONTROLLER] Procura: '
        '${_lookingForRoles.map((role) => role.key).toList()}',
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE CONTROLLER] '
        'Erro ao carregar perfil profissional: $error',
      );

      _selectedRoles.clear();

      _lookingForRoles.clear();

      _primaryRole = null;

      _errorMessage = 'Não foi possível carregar o perfil profissional.';
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // RECARREGAR
  // ============================================================

  Future<
    void
  >
  refresh() async {
    await load(
      force: true,
    );
  }

  // ============================================================
  // VERIFICAR HABILIDADE
  // ============================================================

  bool isRoleSelected(
    MusicRole role,
  ) {
    return _selectedRoles.contains(
      role,
    );
  }

  // ============================================================
  // VERIFICAR FUNÇÃO PRINCIPAL
  // ============================================================

  bool isPrimaryRole(
    MusicRole role,
  ) {
    return _primaryRole ==
        role;
  }

  // ============================================================
  // VERIFICAR PROFISSIONAL PROCURADO
  // ============================================================

  bool isLookingForRoleSelected(
    MusicRole role,
  ) {
    return _lookingForRoles.contains(
      role,
    );
  }

  // ============================================================
  // SELECIONAR / REMOVER HABILIDADE
  // ============================================================

  void toggleRole(
    MusicRole role,
  ) {
    if (_isLoading ||
        _isSaving) {
      return;
    }

    _clearMessages();

    // ==========================================================
    // REMOVER
    // ==========================================================

    if (_selectedRoles.contains(
      role,
    )) {
      _selectedRoles.remove(
        role,
      );

      if (_primaryRole ==
          role) {
        _primaryRole = _selectedRoles.isEmpty
            ? null
            : _selectedRoles.first;
      }

      notifyListeners();

      return;
    }

    // ==========================================================
    // ADICIONAR
    // ==========================================================

    _selectedRoles.add(
      role,
    );

    _primaryRole ??= role;

    notifyListeners();
  }

  // ============================================================
  // DEFINIR FUNÇÃO PRINCIPAL
  // ============================================================

  void setPrimaryRole(
    MusicRole role,
  ) {
    if (_isLoading ||
        _isSaving) {
      return;
    }

    if (!_selectedRoles.contains(
      role,
    )) {
      return;
    }

    if (_primaryRole ==
        role) {
      return;
    }

    _primaryRole = role;

    _clearMessages();

    notifyListeners();
  }

  // ============================================================
  // SELECIONAR / REMOVER PROFISSIONAL PROCURADO
  // ============================================================

  void toggleLookingForRole(
    MusicRole role,
  ) {
    if (_isLoading ||
        _isSaving) {
      return;
    }

    _clearMessages();

    if (_lookingForRoles.contains(
      role,
    )) {
      _lookingForRoles.remove(
        role,
      );
    } else {
      _lookingForRoles.add(
        role,
      );
    }

    notifyListeners();
  }

  // ============================================================
  // LIMPAR PROFISSIONAIS PROCURADOS
  // ============================================================

  void clearLookingForRoles() {
    if (_isLoading ||
        _isSaving ||
        _lookingForRoles.isEmpty) {
      return;
    }

    _lookingForRoles.clear();

    _clearMessages();

    notifyListeners();
  }

  // ============================================================
  // SALVAR PERFIL PROFISSIONAL
  // ============================================================

  Future<
    bool
  >
  save() async {
    if (_isLoading ||
        _isSaving) {
      return false;
    }

    // ==========================================================
    // VALIDAR HABILIDADES
    // ==========================================================

    if (_selectedRoles.isEmpty) {
      _setError(
        'Selecione pelo menos uma habilidade.',
      );

      return false;
    }

    // ==========================================================
    // VALIDAR FUNÇÃO PRINCIPAL
    // ==========================================================

    final primaryRole = _primaryRole;

    if (primaryRole ==
            null ||
        !_selectedRoles.contains(
          primaryRole,
        )) {
      _setError(
        'Escolha uma função principal.',
      );

      return false;
    }

    // ==========================================================
    // VALIDAR QUEM PROCURA
    // ==========================================================
    //
    // Aqui exigimos pelo menos um tipo de profissional
    // procurado para que o perfil possa participar do Match.
    //
    // Se preferir permitir salvar sem isso, podemos remover
    // essa validação depois.
    //
    // ==========================================================

    if (_lookingForRoles.isEmpty) {
      _setError(
        'Selecione pelo menos um profissional com quem deseja se conectar.',
      );

      return false;
    }

    // ==========================================================
    // MODEL
    // ==========================================================

    final profileToSave = ProfessionalProfileModel(
      roles: _selectedRoles.toList(),

      primaryRole: primaryRole,

      lookingForRoles: _lookingForRoles.toList(),
    );

    // ==========================================================
    // SALVAMENTO
    // ==========================================================

    _isSaving = true;

    _clearMessages();

    notifyListeners();

    try {
      await _repository.saveProfessionalProfile(
        profileToSave,
      );

      _hasLoaded = true;

      _successMessage = 'Perfil profissional salvo com sucesso.';

      debugPrint(
        '[PROFILE CONTROLLER] Perfil profissional salvo.',
      );

      debugPrint(
        '[PROFILE CONTROLLER] Função principal: '
        '${primaryRole.key}',
      );

      debugPrint(
        '[PROFILE CONTROLLER] Habilidades: '
        '${_selectedRoles.map((role) => role.key).toList()}',
      );

      debugPrint(
        '[PROFILE CONTROLLER] Procura: '
        '${_lookingForRoles.map((role) => role.key).toList()}',
      );

      return true;
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE CONTROLLER] '
        'Erro ao salvar perfil profissional: $error',
      );

      _errorMessage = 'Não foi possível salvar o perfil profissional.';

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // DEFINIR PERFIL MANUALMENTE
  // ============================================================

  void setProfile(
    ProfessionalProfileModel profile,
  ) {
    if (_isLoading ||
        _isSaving) {
      return;
    }

    // ==========================================================
    // FUNÇÕES
    // ==========================================================

    _selectedRoles
      ..clear()
      ..addAll(
        profile.roles,
      );

    // ==========================================================
    // PROCURA
    // ==========================================================

    _lookingForRoles
      ..clear()
      ..addAll(
        profile.lookingForRoles,
      );

    // ==========================================================
    // FUNÇÃO PRINCIPAL
    // ==========================================================

    final providedPrimaryRole = profile.primaryRole;

    if (providedPrimaryRole !=
            null &&
        _selectedRoles.contains(
          providedPrimaryRole,
        )) {
      _primaryRole = providedPrimaryRole;
    } else {
      _primaryRole = _selectedRoles.isEmpty
          ? null
          : _selectedRoles.first;
    }

    _hasLoaded = true;

    _clearMessages();

    notifyListeners();
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    if (_isSaving) {
      return;
    }

    _selectedRoles.clear();

    _lookingForRoles.clear();

    _primaryRole = null;

    _isLoading = false;

    _hasLoaded = false;

    _clearMessages();

    notifyListeners();
  }

  // ============================================================
  // LIMPAR MENSAGENS
  // ============================================================

  void clearMessages() {
    if (_errorMessage ==
            null &&
        _successMessage ==
            null) {
      return;
    }

    _clearMessages();

    notifyListeners();
  }

  // ============================================================
  // ERRO
  // ============================================================

  void _setError(
    String message,
  ) {
    _errorMessage = message;

    _successMessage = null;

    notifyListeners();
  }

  // ============================================================
  // LIMPAR MENSAGENS INTERNAMENTE
  // ============================================================

  void _clearMessages() {
    _errorMessage = null;

    _successMessage = null;
  }
}
