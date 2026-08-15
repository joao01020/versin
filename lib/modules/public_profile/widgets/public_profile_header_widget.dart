import 'package:flutter/material.dart';

import '../models/public_profile_model.dart';
import 'public_profile_avatar_widget.dart';

// ============================================================
// PUBLIC PROFILE HEADER WIDGET
// ============================================================
//
// Cabeçalho principal do perfil público.
//
// Responsabilidades:
//
// - avatar;
// - nome público;
// - username;
// - status ONLINE / OFFLINE;
// - permitir alterar visibilidade quando for o dono;
// - botão editar quando for o dono;
// - botão conectar quando for outro usuário.
//
// Este widget NÃO:
//
// - navega diretamente;
// - acessa Supabase;
// - altera perfil diretamente;
// - registra conexão.
//
// Tudo é recebido por callback.
//
// ============================================================

class PublicProfileHeaderWidget
    extends
        StatelessWidget {
  // ============================================================
  // PERFIL
  // ============================================================

  final PublicProfileModel profile;

  // ============================================================
  // OWNER
  // ============================================================

  final bool isOwner;

  // ============================================================
  // STATUS
  // ============================================================

  final bool isUpdatingOnlineStatus;

  // ============================================================
  // CALLBACKS
  // ============================================================

  final VoidCallback? onAvatarTap;

  final VoidCallback? onEdit;

  final VoidCallback? onConnect;

  final VoidCallback? onToggleOnline;

  // ============================================================
  // COR
  // ============================================================

  final Color accentColor;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const PublicProfileHeaderWidget({
    super.key,
    required this.profile,
    required this.isOwner,
    this.isUpdatingOnlineStatus = false,
    this.onAvatarTap,
    this.onEdit,
    this.onConnect,
    this.onToggleOnline,
    this.accentColor = const Color(
      0xFFE100FF,
    ),
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        20,
      ),

      decoration: BoxDecoration(
        color:
            const Color(
              0xFF17132D,
            ).withValues(
              alpha: 0.92,
            ),

        borderRadius: BorderRadius.circular(
          22,
        ),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.07,
          ),
        ),
      ),

      child: Column(
        children: [
          // ====================================================
          // AVATAR
          // ====================================================
          PublicProfileAvatarWidget(
            avatarUrl: profile.avatarUrl,

            displayName: profile.resolvedDisplayName,

            size: 92,

            showOnlineIndicator: true,

            isOnline: profile.isOnline,

            onTap: onAvatarTap,

            accentColor: accentColor,
          ),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // NOME
          // ====================================================
          Text(
            profile.resolvedDisplayName,

            textAlign: TextAlign.center,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 20,

              fontWeight: FontWeight.bold,
            ),
          ),

          // ====================================================
          // USERNAME
          // ====================================================
          if (profile.usernameLabel.isNotEmpty) ...[
            const SizedBox(
              height: 4,
            ),

            Text(
              profile.usernameLabel,

              style: const TextStyle(
                color: Colors.white38,

                fontSize: 11,
              ),
            ),
          ],

          // ====================================================
          // STATUS
          // ====================================================
          const SizedBox(
            height: 10,
          ),

          _buildStatus(),

          // ====================================================
          // DICA PARA O DONO
          // ====================================================
          if (isOwner) ...[
            const SizedBox(
              height: 7,
            ),

            Text(
              profile.isOnline
                  ? 'Clique para ficar offline'
                  : 'Clique para ficar online',

              style: const TextStyle(
                color: Colors.white24,

                fontSize: 9,
              ),
            ),
          ],

          // ====================================================
          // AÇÃO
          // ====================================================
          const SizedBox(
            height: 18,
          ),

          _buildAction(),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatus() {
    final online = profile.isOnline;

    final canToggle =
        isOwner &&
        onToggleOnline !=
            null &&
        !isUpdatingOnlineStatus;

    // ==========================================================
    // CONTEÚDO
    // ==========================================================

    final content = AnimatedContainer(
      duration: const Duration(
        milliseconds: 180,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 10,

        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: online
            ? Colors.greenAccent.withValues(
                alpha: 0.08,
              )
            : Colors.white.withValues(
                alpha: 0.04,
              ),

        borderRadius: BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: online
              ? Colors.greenAccent.withValues(
                  alpha: 0.20,
                )
              : Colors.white.withValues(
                  alpha: 0.08,
                ),
        ),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          // ====================================================
          // LOADING
          // ====================================================
          if (isUpdatingOnlineStatus)
            SizedBox(
              width: 9,

              height: 9,

              child: CircularProgressIndicator(
                strokeWidth: 1.5,

                color: online
                    ? Colors.greenAccent
                    : Colors.white54,
              ),
            )
          else
            Container(
              width: 7,

              height: 7,

              decoration: BoxDecoration(
                color: online
                    ? Colors.greenAccent
                    : Colors.white24,

                shape: BoxShape.circle,
              ),
            ),

          const SizedBox(
            width: 6,
          ),

          // ====================================================
          // TEXTO
          // ====================================================
          Text(
            isUpdatingOnlineStatus
                ? 'ATUALIZANDO...'
                : online
                ? 'ONLINE'
                : 'OFFLINE',

            style: TextStyle(
              color: online
                  ? Colors.greenAccent
                  : Colors.white38,

              fontSize: 8,

              fontWeight: FontWeight.bold,

              letterSpacing: 0.7,
            ),
          ),

          // ====================================================
          // INDICADOR DE CLIQUE
          // ====================================================
          if (isOwner &&
              !isUpdatingOnlineStatus) ...[
            const SizedBox(
              width: 5,
            ),

            Icon(
              online
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,

              size: 11,

              color: online
                  ? Colors.greenAccent.withValues(
                      alpha: 0.65,
                    )
                  : Colors.white24,
            ),
          ],
        ],
      ),
    );

    // ==========================================================
    // OUTRO USUÁRIO
    // ==========================================================

    if (!isOwner) {
      return content;
    }

    // ==========================================================
    // DONO
    // ==========================================================

    return Tooltip(
      message: online
          ? 'Deixar perfil offline'
          : 'Deixar perfil online',

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: canToggle
              ? onToggleOnline
              : null,

          borderRadius: BorderRadius.circular(
            20,
          ),

          child: content,
        ),
      ),
    );
  }

  // ============================================================
  // AÇÃO PRINCIPAL
  // ============================================================

  Widget _buildAction() {
    // ==========================================================
    // OWNER
    // ==========================================================

    if (isOwner) {
      return SizedBox(
        width: double.infinity,

        height: 42,

        child: OutlinedButton.icon(
          onPressed: onEdit,

          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor,

            side: BorderSide(
              color: accentColor.withValues(
                alpha: 0.30,
              ),
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
          ),

          icon: const Icon(
            Icons.edit_outlined,

            size: 16,
          ),

          label: const Text(
            'EDITAR PERFIL',

            style: TextStyle(
              fontSize: 10,

              fontWeight: FontWeight.bold,

              letterSpacing: 0.6,
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // OUTRO USUÁRIO
    // ==========================================================

    return SizedBox(
      width: double.infinity,

      height: 42,

      child: ElevatedButton.icon(
        onPressed: onConnect,

        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,

          foregroundColor: Colors.black,

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
        ),

        icon: const Icon(
          Icons.person_add_alt_1_rounded,

          size: 17,
        ),

        label: const Text(
          'CONECTAR',

          style: TextStyle(
            fontSize: 10,

            fontWeight: FontWeight.bold,

            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
