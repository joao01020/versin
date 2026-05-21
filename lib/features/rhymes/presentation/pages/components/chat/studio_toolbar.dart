import 'package:flutter/material.dart';

class StudioToolbar extends StatelessWidget {
  final bool configuracaoFinalizada;
  final int currentBpm;
  final String selectedVibe;
  final String selectedTechnique;
  final Color activeColor;
  final VoidCallback onShowStructure;
  final Function(String title, List<String> options, Function(String) onSelect) onShowMenu;
  final Function(int) onBpmChanged;
  final Function(String) onTechniqueChanged;
  final Function(String) onVibeChanged;

  const StudioToolbar({
    super.key,
    required this.configuracaoFinalizada,
    required this.currentBpm,
    required this.selectedVibe,
    required this.selectedTechnique,
    required this.activeColor,
    required this.onShowStructure,
    required this.onShowMenu,
    required this.onBpmChanged,
    required this.onTechniqueChanged,
    required this.onVibeChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!configuracaoFinalizada) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            icon: Icons.speed,
            label: "$currentBpm BPM",
            onTap: () => onShowMenu("Ajustar BPM", ["80", "90", "100", "120", "140", "160"], (val) {
              onBpmChanged(int.parse(val));
            }),
          ),
          const SizedBox(width: 12),
          _buildItem(
            icon: Icons.account_tree_outlined,
            label: "Estrutura",
            onTap: onShowStructure,
          ),
          const SizedBox(width: 12),
          _buildItem(
            icon: Icons.mic_external_on_outlined,
            label: selectedTechnique,
            onTap: () => onShowMenu("Performance Vocal", ["Melódico", "Agressivo", "Flow Rápido", "Sussurrado", "Falsete"], onTechniqueChanged),
          ),
          const SizedBox(width: 12),
          _buildItem(
            icon: Icons.auto_awesome,
            label: selectedVibe,
            onTap: () => onShowMenu("Alterar Vibe", ["Calmo", "Energético", "Agressivo", "Triste", "Melancólico"], onVibeChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white30),
        ],
      ),
    );
  }
}