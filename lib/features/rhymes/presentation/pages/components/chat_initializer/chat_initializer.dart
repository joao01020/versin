import 'dart:async';
import 'package:flutter/material.dart';
import 'package:versin/features/rhymes/presentation/widgets/structure_builder/structure_draggable_list.dart';

class ChatInitializer {
  static void run({
    required Function(bool) onLoadingStatusChanged,
    required Function() onStartWelcomeFlow,
    required bool mounted,
  }) {
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        onLoadingStatusChanged(false);
        onStartWelcomeFlow();
      }
    });
  }

  static void welcomeFlow({
    required List<Map<String, dynamic>> messages, 
    required Function(String, {Widget? customWidget}) addMessage, 
    required Function(bool) setAiTyping,
    required Function() scrollToBottom,
    required List<String> userRhymes, 
    required bool mounted,
    required Function(int, double) onProgressUpdate,
    // NOVO: Passamos o callback para salvar o peso da palavra no banco real
    required Function(String) onWordSelected, 
    // NOVO: Lista real vinda do banco (Ranking Global + Tendências)
    required List<Map<String, dynamic>> globalTrendingWords,
  }) {
    if (messages.isNotEmpty) return;

    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      addMessage("Salve! Sou o Versin... 🎤");
      scrollToBottom();

      Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setAiTyping(false);
        
        // Identifica a palavra com maior score real para o ícone de foguinho 🔥
        final String topWord = globalTrendingWords.isNotEmpty 
            ? globalTrendingWords.first['word'] 
            : "";

        addMessage(
          "Selecione até 3 palavras. '${topWord}' é a mais quente do momento! 🔥",
          customWidget: RhymeSelector(
            rhymesWithScores: globalTrendingWords,
            topWord: topWord,
            onWordClick: onWordSelected, // Contagem começa aqui!
            onChanged: (count) {
              double progress = (count / 3).clamp(0.0, 1.0);
              onProgressUpdate(1, progress);
            },
            onSelectionComplete: (selected) {
              onProgressUpdate(1, 1.0); 
              addMessage("Rimas selecionadas! Quer buscar rimas perfeitas ou por sonoridade com base nelas?");
              scrollToBottom();
              
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (!mounted) return;
                onProgressUpdate(2, 0.0);
              });
            },
          ),
        );
        scrollToBottom();
      });
    });
  }

  static void startStructureStep({
    required Function(String, {Widget? customWidget}) addMessage,
    required Function(int, double) onProgressUpdate,
    required Function() scrollToBottom,
    required Color activeColor,
  }) {
    onProgressUpdate(4, 0.0);
    
    addMessage(
      "Quarto ponto: Estrutura. Arraste para organizar ou use o '+' para novos blocos.",
      customWidget: StructureDraggableList(
        initialStructure: const ["Intro", "Verso 1", "Refrão", "Verso 2", "Refrão", "Ponte", "Final"],
        activeColor: activeColor,
        onStructureChanged: (newStructure) {
          onProgressUpdate(4, 1.0);
          Future.delayed(const Duration(seconds: 1), () => onProgressUpdate(5, 0.1));
        },
      ),
    );
    scrollToBottom();
  }
}

class RhymeSelector extends StatefulWidget {
  final List<Map<String, dynamic>> rhymesWithScores;
  final String topWord;
  final Function(List<String>) onSelectionComplete;
  final Function(String) onWordClick; // Callback real
  final Function(int)? onChanged;

  const RhymeSelector({
    super.key, 
    required this.rhymesWithScores, 
    required this.topWord,
    required this.onSelectionComplete,
    required this.onWordClick,
    this.onChanged,
  });

  @override
  State<RhymeSelector> createState() => _RhymeSelectorState();
}

class _RhymeSelectorState extends State<RhymeSelector> {
  final List<String> _selectedRhymes = [];

  void _toggleRhyme(String word) {
    setState(() {
      if (_selectedRhymes.contains(word)) {
        _selectedRhymes.remove(word);
      } else {
        if (_selectedRhymes.length < 3) {
          _selectedRhymes.add(word);
          // AQUI: A contagem real começa. A IA registra o uso para aumentar o ranking global.
          widget.onWordClick(word); 
        }
      }
    });

    widget.onChanged?.call(_selectedRhymes.length);

    if (_selectedRhymes.length == 3) {
      widget.onSelectionComplete(_selectedRhymes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: widget.rhymesWithScores.map((data) {
          final word = data['word'] as String;
          final isSelected = _selectedRhymes.contains(word);
          final isTop = word == widget.topWord;

          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(word, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
                if (isTop) ...[
                  const SizedBox(width: 4),
                  const Text("🔥", style: TextStyle(fontSize: 14)),
                ]
              ],
            ),
            selected: isSelected,
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFFBB86FC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isTop ? Colors.orange : Colors.transparent, width: isTop ? 2 : 0),
            ),
            onSelected: (_) => _toggleRhyme(word),
          );
        }).toList(),
      ),
    );
  }
}