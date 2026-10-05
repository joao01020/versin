import 'package:flutter/material.dart';

import 'package:versin/modules/match/models/match_filter_state.dart';
import 'package:versin/modules/profile/models/music_role.dart';

// ============================================================
// MATCH FILTER SHEET
// ============================================================
//
// Modal responsável por editar filtros do módulo Match.
//
// Responsabilidades:
//
// - receber estado inicial;
// - permitir selecionar funções;
// - permitir somente online;
// - permitir somente interesse mútuo;
// - limpar filtros;
// - retornar novo MatchFilterState.
//
// Este widget NÃO:
//
// - aplica filtros;
// - acessa repository;
// - acessa Supabase;
// - conhece MatchController.
//
// ============================================================

abstract final class MatchFilterSheet {
  // ==========================================================
  // ABRIR
  // ==========================================================

  static Future<
    MatchFilterState?
  >
  show({
    required BuildContext context,
    required MatchFilterState initialState,
    Color accentColor = const Color(
      0xFFE100FF,
    ),
  }) {
    return showModalBottomSheet<
      MatchFilterState
    >(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (
            context,
          ) {
            return _MatchFilterSheetContent(
              initialState: initialState,
              accentColor: accentColor,
            );
          },
    );
  }
}

// ============================================================
// CONTENT
// ============================================================

class _MatchFilterSheetContent
    extends
        StatefulWidget {
  final MatchFilterState initialState;

  final Color accentColor;

  const _MatchFilterSheetContent({
    required this.initialState,
    required this.accentColor,
  });

  @override
  State<
    _MatchFilterSheetContent
  >
  createState() => _MatchFilterSheetContentState();
}

// ============================================================
// STATE
// ============================================================

class _MatchFilterSheetContentState
    extends
        State<
          _MatchFilterSheetContent
        > {
  // ============================================================
  // ESTADO LOCAL
  // ============================================================

  late MatchFilterState _state;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _state = widget.initialState;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final bottomInset = MediaQuery.of(
      context,
    ).viewInsets.bottom;

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 620,
      ),
      margin: const EdgeInsets.only(
        top: 80,
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        20,
        22,
        22 +
            bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Color(
          0xFF15122C,
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            26,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================================================
              // HANDLE
              // ================================================
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.18,
                    ),
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ================================================
              // HEADER
              // ================================================
              _buildHeader(),

              const SizedBox(
                height: 24,
              ),

              // ================================================
              // FUNÇÃO PROFISSIONAL
              // ================================================
              _buildSectionTitle(
                title: 'Função profissional',
                subtitle: 'Escolha uma ou mais funções.',
              ),

              const SizedBox(
                height: 12,
              ),

              _buildRoles(),

              const SizedBox(
                height: 24,
              ),

              // ================================================
              // DISPONIBILIDADE
              // ================================================
              _buildSectionTitle(
                title: 'Disponibilidade',
                subtitle: 'Filtre quem está disponível agora.',
              ),

              const SizedBox(
                height: 10,
              ),

              _buildOptionTile(
                icon: Icons.circle,
                title: 'Somente online',
                description: 'Mostrar apenas usuários conectados.',
                value: _state.onlyOnline,
                onChanged:
                    (
                      value,
                    ) {
                      setState(
                        () {
                          _state = _state.copyWith(
                            onlyOnline: value,
                          );
                        },
                      );
                    },
              ),

              const SizedBox(
                height: 24,
              ),

              // ================================================
              // COMPATIBILIDADE
              // ================================================
              _buildSectionTitle(
                title: 'Compatibilidade',
                subtitle: 'Refine o tipo de conexão desejada.',
              ),

              const SizedBox(
                height: 10,
              ),

              _buildOptionTile(
                icon: Icons.handshake_outlined,
                title: 'Interesse mútuo',
                description: 'Mostrar apenas quem também procura sua função.',
                value: _state.mutualInterestOnly,
                onChanged:
                    (
                      value,
                    ) {
                      setState(
                        () {
                          _state = _state.copyWith(
                            mutualInterestOnly: value,
                          );
                        },
                      );
                    },
              ),

              const SizedBox(
                height: 28,
              ),

              // ================================================
              // AÇÕES
              // ================================================
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtros de conexão',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                _state.hasActiveFilters
                    ? '${_state.activeFilterCount} filtro(s) ativo(s)'
                    : 'Refine os profissionais encontrados',
                style: TextStyle(
                  color: _state.hasActiveFilters
                      ? widget.accentColor
                      : Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Fechar',
          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },
          icon: const Icon(
            Icons.close_rounded,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TÍTULO DE SEÇÃO
  // ============================================================

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 2,
        ),

        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ROLES
  // ============================================================

  Widget _buildRoles() {
    final roles = MusicRole.values;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roles.map(
        (
          role,
        ) {
          final selected = _state.containsRole(
            role,
          );

          return FilterChip(
            selected: selected,
            onSelected:
                (
                  _,
                ) {
                  setState(
                    () {
                      _state = _state.toggleRole(
                        role,
                      );
                    },
                  );
                },
            showCheckmark: false,
            label: Text(
              role.label,
            ),
            avatar: selected
                ? Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: widget.accentColor,
                  )
                : null,
            backgroundColor: Colors.white.withValues(
              alpha: 0.035,
            ),
            selectedColor: widget.accentColor.withValues(
              alpha: 0.10,
            ),
            side: BorderSide(
              color: selected
                  ? widget.accentColor.withValues(
                      alpha: 0.35,
                    )
                  : Colors.white.withValues(
                      alpha: 0.07,
                    ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                20,
              ),
            ),
            labelStyle: TextStyle(
              color: selected
                  ? widget.accentColor
                  : Colors.white54,
              fontSize: 10,
              fontWeight: selected
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // OPÇÃO
  // ============================================================

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<
      bool
    >
    onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.025,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: value
              ? widget.accentColor.withValues(
                  alpha: 0.20,
                )
              : Colors.white.withValues(
                  alpha: 0.05,
                ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              color: value
                  ? widget.accentColor
                  : Colors.white30,
              size: 17,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: widget.accentColor,
            activeTrackColor: widget.accentColor.withValues(
              alpha: 0.25,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AÇÕES
  // ============================================================

  Widget _buildActions() {
    return Row(
      children: [
        // ======================================================
        // LIMPAR
        // ======================================================
        Expanded(
          child: OutlinedButton(
            onPressed: _state.hasActiveFilters
                ? _clearFilters
                : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(
                0,
                46,
              ),
              foregroundColor: Colors.white60,
              side: BorderSide(
                color: Colors.white.withValues(
                  alpha: 0.08,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  13,
                ),
              ),
            ),
            child: const Text(
              'LIMPAR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        // ======================================================
        // APLICAR
        // ======================================================
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(
                0,
                46,
              ),
              elevation: 0,
              backgroundColor: widget.accentColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  13,
                ),
              ),
            ),
            child: const Text(
              'APLICAR FILTROS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LIMPAR
  // ============================================================

  void _clearFilters() {
    setState(
      () {
        _state = const MatchFilterState.initial();
      },
    );
  }

  // ============================================================
  // APLICAR
  // ============================================================

  void _applyFilters() {
    Navigator.of(
      context,
    ).pop(
      _state,
    );
  }
}
