import 'package:flutter/material.dart';

// ============================================================
// SETTINGS TILE
// ============================================================
//
// Componente reutilizável para as opções da página de ajustes.
//
// Responsabilidades:
// - Exibir ícone.
// - Exibir título.
// - Exibir subtítulo.
// - Exibir indicador de navegação.
// - Executar ação ao clicar.
//
// Não contém:
// - Regra de negócio.
// - Navegação específica.
// - Supabase.
// - Banco local.
// - Controllers.
//
// ============================================================

class SettingsTile
    extends
        StatelessWidget {
  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  final Color iconColor;

  final Color iconBackgroundColor;

  final Widget? trailing;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = const Color(
      0xFFE040FB,
    ),
    this.iconBackgroundColor = const Color(
      0x336A1B9A,
    ),
    this.trailing,
  });

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              // ==================================================
              // ÍCONE
              // ==================================================
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              // ==================================================
              // TEXTOS
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              // ==================================================
              // TRAILING
              // ==================================================
              trailing ??
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white24,
                    size: 15,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
