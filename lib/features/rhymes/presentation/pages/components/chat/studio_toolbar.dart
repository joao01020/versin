import 'package:flutter/material.dart';

class StudioToolbar extends StatefulWidget {
  final bool configuracaoFinalizada;
  final String projectName;
  final int currentBpm;
  final String selectedVibe;
  final String selectedTechnique;
  final Color activeColor;
  final VoidCallback onShowStructure;
  final Function(String title, List<String> options, Function(String) onSelect) onShowMenu;
  final Function(int) onBpmChanged;
  final Function(String) onTechniqueChanged;
  final Function(String) onVibeChanged;
  final VoidCallback onEditName;

  const StudioToolbar({
    super.key,
    required this.configuracaoFinalizada,
    required this.projectName,
    required this.currentBpm,
    required this.selectedVibe,
    required this.selectedTechnique,
    required this.activeColor,
    required this.onShowStructure,
    required this.onShowMenu,
    required this.onBpmChanged,
    required this.onTechniqueChanged,
    required this.onVibeChanged,
    required this.onEditName,
  });

  @override
  State<StudioToolbar> createState() => _StudioToolbarState();
}

class _StudioToolbarState extends State<StudioToolbar> {
  double _dragAccumulator = 0.0;

  @override
  Widget build(BuildContext context) {
    if (!widget.configuracaoFinalizada) return const SizedBox.shrink();

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
            icon: Icons.edit_note_rounded,
            label: widget.projectName.toUpperCase(),
            onTap: widget.onEditName,
          ),
          const SizedBox(width: 12),
          
          // BPM COM GESTURE DETECTOR PARA ARRASTE (Substituindo a lista da imagem Captura de imagem_20260512_225907.png)
          GestureDetector(
            onVerticalDragUpdate: (details) {
              // Acumula o movimento. Negativo para cima (aumentar), Positivo para baixo (diminuir)
              _dragAccumulator -= details.primaryDelta!;
              
              // Sensibilidade: a cada 5 pixels de arraste, muda 1 BPM
              if (_dragAccumulator.abs() >= 5) {
                int delta = _dragAccumulator > 0 ? 1 : -1;
                int newBpm = (widget.currentBpm + delta).clamp(40, 250);
                widget.onBpmChanged(newBpm);
                _dragAccumulator = 0;
              }
            },
            child: _buildItem(
              icon: Icons.speed,
              label: "${widget.currentBpm} BPM",
              onTap: () {}, // Tap desativado para priorizar o arraste
              isDrag: true,
            ),
          ),
          
          const SizedBox(width: 12),
          _buildItem(
            icon: Icons.account_tree_outlined,
            label: "Estrutura",
            onTap: widget.onShowStructure,
          ),
          const SizedBox(width: 12),
          _buildItem(
            icon: Icons.mic_external_on_outlined,
            label: widget.selectedTechnique,
            onTap: () => widget.onShowMenu("Performance Vocal", ["Melódico", "Agressivo", "Flow Rápido", "Sussurrado", "Falsete"], widget.onTechniqueChanged),
          ),
          const SizedBox(width: 12),
          _buildItem(
            icon: Icons.auto_awesome,
            label: widget.selectedVibe,
            onTap: () => widget.onShowMenu("Alterar Vibe", ["Calmo", "Energético", "Agressivo", "Triste", "Melancólico"], widget.onVibeChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    bool isDrag = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isDrag ? widget.activeColor : Colors.white54),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            color: isDrag ? widget.activeColor : Colors.white70, 
            fontSize: 11,
            fontWeight: isDrag ? FontWeight.bold : FontWeight.normal,
          )),
          Icon(
            isDrag ? Icons.unfold_more : Icons.keyboard_arrow_down, 
            size: 14, 
            color: isDrag ? widget.activeColor.withOpacity(0.5) : Colors.white30
          ),
        ],
      ),
    );
  }
}