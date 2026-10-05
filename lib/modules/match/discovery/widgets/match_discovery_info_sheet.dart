import 'package:flutter/material.dart';

// ============================================================
// MATCH DISCOVERY INFO SHEET
// ============================================================
//
// Explica os três modos de descoberta:
//
// - Compatíveis;
// - Próximos;
// - Agora.
//
// É somente UI. Não altera estado do Match.
// ============================================================

class MatchDiscoveryInfoSheet {
  const MatchDiscoveryInfoSheet._();

  static Future<void> show({
    required BuildContext context,
    required Color accentColor,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _DiscoveryInfoContent(accentColor: accentColor);
      },
    );
  }
}

class _DiscoveryInfoContent extends StatelessWidget {
  final Color accentColor;

  const _DiscoveryInfoContent({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12101F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 10),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Formas de conectar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      SizedBox(height: 3),

                      Text(
                        'Cada modo muda a prioridade dos perfis exibidos.',
                        style: TextStyle(color: Colors.white38, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _InfoModeCard(
              accentColor: accentColor,
              icon: Icons.auto_awesome_rounded,
              title: 'Compatíveis',
              description:
                  'Prioriza profissionais que combinam com o seu perfil. '
                  'O Versin considera as áreas em que você atua e os tipos '
                  'de profissionais que você selecionou em "Quem você procura".',
            ),

            const SizedBox(height: 9),

            _InfoModeCard(
              accentColor: accentColor,
              icon: Icons.near_me_rounded,
              title: 'Próximos',
              description:
                  'Prioriza profissionais próximos da sua localização. '
                  'Esse modo usa localização somente depois da sua confirmação '
                  'e conforme as permissões do dispositivo.',
            ),

            const SizedBox(height: 9),

            _InfoModeCard(
              accentColor: accentColor,
              icon: Icons.bolt_rounded,
              title: 'Agora',
              description:
                  'Prioriza profissionais que estão realmente online e '
                  'disponíveis neste momento. É indicado quando você quer '
                  'encontrar alguém para conversar ou colaborar agora.',
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'ENTENDI',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoModeCard extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String title;
  final String description;

  const _InfoModeCard({
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.075),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 17),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
