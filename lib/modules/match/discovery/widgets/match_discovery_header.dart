import 'package:flutter/material.dart';

// ============================================================
// MATCH DISCOVERY HEADER
// ============================================================
//
// Header principal da área de descoberta.
//
// Responsável somente por UI.
//
// Ações:
//
// - pesquisar;
// - perfil público;
// - meus projetos;
// - filtros.
//
// NÃO:
//
// - navega diretamente;
// - acessa controllers;
// - altera filtro;
// - abre pesquisa.
//
// ============================================================

class MatchDiscoveryHeader
    extends
        StatelessWidget {
  // ============================================================
  // MODE
  // ============================================================

  final bool isTeamExpansionMode;

  // ============================================================
  // SEARCH
  // ============================================================

  final bool isSearchPanelOpen;

  // ============================================================
  // PROFILE
  // ============================================================

  final bool hasPublicProfile;

  // ============================================================
  // FILTER
  // ============================================================

  final bool hasActiveFilters;

  final int activeFilterCount;

  // ============================================================
  // STYLE
  // ============================================================

  final Color accentColor;

  // ============================================================
  // CALLBACKS
  // ============================================================

  final VoidCallback onSearch;

  final VoidCallback onPublicProfile;

  final VoidCallback onProjects;

  final VoidCallback onFilters;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const MatchDiscoveryHeader({
    super.key,
    required this.isTeamExpansionMode,
    required this.isSearchPanelOpen,
    required this.hasPublicProfile,
    required this.hasActiveFilters,
    required this.activeFilterCount,
    required this.accentColor,
    required this.onSearch,
    required this.onPublicProfile,
    required this.onProjects,
    required this.onFilters,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        // ======================================================
        // TITLE
        // ======================================================
        Expanded(
          child: Text(
            isTeamExpansionMode
                ? 'Procurar membro'
                : 'Novas Conexões',

            style: const TextStyle(
              color: Colors.white,

              fontSize: 26,

              fontWeight: FontWeight.w800,

              letterSpacing: -0.45,
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ======================================================
        // ACTIONS
        // ======================================================
        Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            // ==================================================
            // SEARCH
            // ==================================================
            _HeaderActionButton(
              tooltip: isSearchPanelOpen
                  ? 'Fechar pesquisa'
                  : 'Pesquisar usuário',

              icon: isSearchPanelOpen
                  ? Icons.close_rounded
                  : Icons.search_rounded,

              active: isSearchPanelOpen,

              accentColor: accentColor,

              onTap: onSearch,
            ),

            const SizedBox(
              width: 6,
            ),

            // ==================================================
            // PUBLIC PROFILE
            // ==================================================
            _HeaderActionButton(
              tooltip: 'Meu perfil público',

              icon: Icons.account_circle_outlined,

              active: hasPublicProfile,

              accentColor: accentColor,

              onTap: onPublicProfile,
            ),

            const SizedBox(
              width: 6,
            ),

            // ==================================================
            // PROJECTS
            // ==================================================
            _HeaderActionButton(
              tooltip: 'Meus projetos',

              icon: Icons.folder_open_outlined,

              active: false,

              accentColor: accentColor,

              onTap: onProjects,
            ),

            const SizedBox(
              width: 6,
            ),

            // ==================================================
            // FILTERS
            // ==================================================
            Stack(
              clipBehavior: Clip.none,

              children: [
                _HeaderActionButton(
                  tooltip: 'Filtros',

                  icon: Icons.tune_rounded,

                  active: hasActiveFilters,

                  accentColor: accentColor,

                  onTap: onFilters,
                ),

                // ==============================================
                // BADGE
                // ==============================================
                if (hasActiveFilters &&
                    activeFilterCount >
                        0)
                  Positioned(
                    top: -4,

                    right: -4,

                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 17,

                        minHeight: 17,
                      ),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),

                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: accentColor,

                        borderRadius: BorderRadius.circular(
                          100,
                        ),

                        border: Border.all(
                          color: const Color(
                            0xFF0D0B1F,
                          ),

                          width: 2,
                        ),
                      ),

                      child: Text(
                        '$activeFilterCount',

                        style: const TextStyle(
                          color: Colors.black,

                          fontSize: 8,

                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// HEADER ACTION
// ============================================================

class _HeaderActionButton
    extends
        StatelessWidget {
  final String tooltip;

  final IconData icon;

  final bool active;

  final Color accentColor;

  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Tooltip(
      message: tooltip,

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: onTap,

          borderRadius: BorderRadius.circular(
            14,
          ),

          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 160,
            ),

            width: 42,

            height: 42,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: active
                  ? accentColor.withValues(
                      alpha: 0.10,
                    )
                  : Colors.white.withValues(
                      alpha: 0.035,
                    ),

              borderRadius: BorderRadius.circular(
                14,
              ),

              border: Border.all(
                color: active
                    ? accentColor.withValues(
                        alpha: 0.30,
                      )
                    : Colors.white.withValues(
                        alpha: 0.06,
                      ),
              ),
            ),

            child: Icon(
              icon,

              size: 21,

              color: active
                  ? accentColor
                  : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}
