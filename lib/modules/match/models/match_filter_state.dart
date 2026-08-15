import 'package:versin/modules/profile/models/music_role.dart';

// ============================================================
// MATCH FILTER STATE
// ============================================================
//
// Estado imutável dos filtros do módulo Match.
//
// Responsabilidades:
//
// - armazenar funções profissionais selecionadas;
// - armazenar filtro somente online;
// - armazenar filtro de interesse mútuo;
// - informar se existem filtros ativos;
// - permitir cópia segura do estado;
// - permitir limpeza dos filtros.
//
// Este model NÃO:
//
// - acessa Supabase;
// - executa filtragem;
// - desenha modal;
// - conhece BuildContext;
// - conhece MatchController.
//
// ============================================================

class MatchFilterState {
  // ============================================================
  // FUNÇÕES PROFISSIONAIS
  // ============================================================

  final Set<
    MusicRole
  >
  selectedRoles;

  // ============================================================
  // SOMENTE ONLINE
  // ============================================================

  final bool onlyOnline;

  // ============================================================
  // INTERESSE MÚTUO
  // ============================================================

  final bool mutualInterestOnly;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const MatchFilterState({
    this.selectedRoles =
        const <
          MusicRole
        >{},
    this.onlyOnline = false,
    this.mutualInterestOnly = false,
  });

  // ============================================================
  // ESTADO INICIAL
  // ============================================================

  const MatchFilterState.initial()
    : selectedRoles =
          const <
            MusicRole
          >{},
      onlyOnline = false,
      mutualInterestOnly = false;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get hasSelectedRoles {
    return selectedRoles.isNotEmpty;
  }

  bool get hasActiveFilters {
    return selectedRoles.isNotEmpty ||
        onlyOnline ||
        mutualInterestOnly;
  }

  int get activeFilterCount {
    var count = 0;

    if (selectedRoles.isNotEmpty) {
      count++;
    }

    if (onlyOnline) {
      count++;
    }

    if (mutualInterestOnly) {
      count++;
    }

    return count;
  }

  // ============================================================
  // ROLE SELECIONADA
  // ============================================================

  bool containsRole(
    MusicRole role,
  ) {
    return selectedRoles.contains(
      role,
    );
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  MatchFilterState copyWith({
    Set<
      MusicRole
    >?
    selectedRoles,
    bool? onlyOnline,
    bool? mutualInterestOnly,
  }) {
    return MatchFilterState(
      selectedRoles:
          selectedRoles !=
              null
          ? Set<
              MusicRole
            >.unmodifiable(
              selectedRoles,
            )
          : this.selectedRoles,
      onlyOnline:
          onlyOnline ??
          this.onlyOnline,
      mutualInterestOnly:
          mutualInterestOnly ??
          this.mutualInterestOnly,
    );
  }

  // ============================================================
  // TOGGLE ROLE
  // ============================================================

  MatchFilterState toggleRole(
    MusicRole role,
  ) {
    final updatedRoles =
        Set<
          MusicRole
        >.from(
          selectedRoles,
        );

    if (updatedRoles.contains(
      role,
    )) {
      updatedRoles.remove(
        role,
      );
    } else {
      updatedRoles.add(
        role,
      );
    }

    return copyWith(
      selectedRoles: updatedRoles,
    );
  }

  // ============================================================
  // LIMPAR ROLES
  // ============================================================

  MatchFilterState clearRoles() {
    return copyWith(
      selectedRoles:
          const <
            MusicRole
          >{},
    );
  }

  // ============================================================
  // LIMPAR TUDO
  // ============================================================

  MatchFilterState clear() {
    return const MatchFilterState.initial();
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'MatchFilterState('
        'roles: ${selectedRoles.map((role) => role.key).toList()}, '
        'onlyOnline: $onlyOnline, '
        'mutualInterestOnly: $mutualInterestOnly'
        ')';
  }
}
