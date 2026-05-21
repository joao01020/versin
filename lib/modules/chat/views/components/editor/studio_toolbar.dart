import 'package:flutter/material.dart';

class StudioToolbar extends StatelessWidget {
  final bool isConfigFinished;
  final String projectName;
  final int currentBpm;
  final String selectedVibe;
  final String selectedTechnique;
  final Color activeColor;
  
  final VoidCallback onEditName;
  final VoidCallback onShowStructure;
  final Function(String, List<String>, Function(String)) onShowMenu;
  final ValueChanged<int> onBpmChanged;
  final ValueChanged<String> onTechniqueChanged;
  final ValueChanged<String> onVibeChanged;

  const StudioToolbar({
    super.key,
    required this.isConfigFinished,
    required this.projectName,
    required this.currentBpm,
    required this.selectedVibe,
    required this.selectedTechnique,
    required this.activeColor,
    required this.onEditName,
    required this.onShowStructure,
    required this.onShowMenu,
    required this.onBpmChanged,
    required this.onTechniqueChanged,
    required this.onVibeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF15122C).withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 1. NOME DO PROJETO
            _buildToolbarButton(
              icon: Icons.edit_note,
              label: projectName,
              onTap: onEditName,
            ),
            _buildDivider(),

            // 2. ALTERAR BPM VIA DRAG VERTICAL
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) {
                if (details.delta.dy < -0.4) {
                  final novoBpm = (currentBpm + 1).clamp(40, 250);
                  onBpmChanged(novoBpm);
                } else if (details.delta.dy > 0.4) {
                  final novoBpm = (currentBpm - 1).clamp(40, 250);
                  onBpmChanged(novoBpm);
                }
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.speed, size: 16, color: activeColor),
                      const SizedBox(width: 6),
                      Text(
                        "$currentBpm BPM",
                        style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 2),
                      // CORREÇÃO: Ícone correto de setas verticais nativo do SDK
                      const Icon(Icons.unfold_more, size: 14, color: Colors.white30),
                    ],
                  ),
                ),
              ),
            ),
            _buildDivider(),

            // 3. ESTRUTURA
            _buildToolbarButton(
              icon: Icons.account_tree_outlined,
              label: "Estrutura",
              onTap: onShowStructure,
              hasArrow: true,
            ),
            _buildDivider(),

            // 4. ALTERAR FLOW / TÉCNICA
            PopupMenuButton<String>(
              initialValue: selectedTechnique,
              tooltip: "Alterar Técnica",
              color: const Color(0xFF15122C), // CORREÇÃO: Propriedade corrigida para 'color'
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: onTechniqueChanged,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.music_note_outlined, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      selectedTechnique,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white30),
                  ],
                ),
              ),
              itemBuilder: (context) => ["Melódico", "Flow Rápido", "Speedflow", "Plugg", "Aggressive"].map((tech) {
                return PopupMenuItem<String>(
                  value: tech,
                  child: Text(tech, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
            _buildDivider(),

            // 5. ALTERAR VIBE
            PopupMenuButton<String>(
              initialValue: selectedVibe,
              tooltip: "Alterar Vibe",
              color: const Color(0xFF15122C), // CORREÇÃO: Propriedade corrigida para 'color'
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: onVibeChanged,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    // CORREÇÃO: Nome do ícone corrigido para a versão válida do Material Icons
                    const Icon(Icons.auto_awesome_outlined, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      selectedVibe,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white30),
                  ],
                ),
              ),
              itemBuilder: (context) => ["Calmo", "Dark", "Melancólico", "Enérgico", "Psychedelic"].map((vibe) {
                return PopupMenuItem<String>(
                  value: vibe,
                  child: Text(vibe, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES REUTILIZÁVEIS ---

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool hasArrow = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            if (hasArrow) ...[
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white30),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 14,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white10,
    );
  }
}