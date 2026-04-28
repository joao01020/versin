import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class ChatInitializer {
  static Timer? _metronomeTimer;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static void run({
    required Function(bool) onLoadingStatusChanged,
    required Function() onStartWelcomeFlow,
    required bool mounted,
  }) {
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        onLoadingStatusChanged(false);
        onStartWelcomeFlow();
      }
    });
  }

  // Função para emitir o som do metrônomo
  static void _playMetronomeClick() {
    // Caminho ajustado para a localização informada na lib
    _audioPlayer.play(
      AssetSource('sounds/click.wav'), 
      mode: PlayerMode.lowLatency
    );
  }

  static void welcomeFlow({
    required List<Map<String, dynamic>> messages, 
    required Function(String, {Widget? customWidget}) addMessage, 
    required Function(bool) setAiTyping,
    required Function() scrollToBottom,
    required bool mounted,
    required Function(int, double) onProgressUpdate,
    required Function(String) onStructureConfirmed,
    required Color activeColor,
  }) {
    if (messages.isNotEmpty) return;

    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;

      final List<String> estruturaTemp = [];
      final List<String> opcoes = ["Intro", "Verso", "Pré-Refrão", "Refrão", "Ponte", "Outro"];
      int bpm = 120;
      bool isMetronomeOn = false;

      addMessage(
        "Salve! Sou o Versin. 🎤 Vamos preparar o estúdio. Arraste o BPM para ajustar e ative o metrônomo ao lado para ouvir o tempo:",
        customWidget: StatefulBuilder(
          builder: (context, setLocalState) {
            
            void toggleMetronomeLogic() {
              _metronomeTimer?.cancel();
              if (isMetronomeOn) {
                final int interval = (60000 / bpm).round();
                _metronomeTimer = Timer.periodic(
                  Duration(milliseconds: interval),
                  (timer) => _playMetronomeClick(),
                );
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    GestureDetector(
                      onVerticalDragUpdate: (details) {
                        setLocalState(() {
                          bpm = (bpm - details.delta.dy.toInt()).clamp(60, 220);
                          if (isMetronomeOn) toggleMetronomeLogic();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: activeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: activeColor.withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "$bpm",
                              style: TextStyle(
                                color: activeColor,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const Text("BPM", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      // ÍCONE CORRIGIDO AQUI:
                      icon: Icon(
                        isMetronomeOn ? Icons.timer : Icons.play_circle_outline_rounded,
                        color: isMetronomeOn ? activeColor : Colors.white30,
                        size: 40,
                      ),
                      onPressed: () {
                        setLocalState(() {
                          isMetronomeOn = !isMetronomeOn;
                          toggleMetronomeLogic();
                        });
                      },
                    ),
                    if (isMetronomeOn)
                      Text("LIVE", style: TextStyle(color: activeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),

                const SizedBox(height: 25),

                const Text("Monte a estrutura da sua track:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: opcoes.map((label) => ActionChip(
                    label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    backgroundColor: const Color(0xFF1A1A1A),
                    shape: StadiumBorder(side: BorderSide(color: activeColor.withOpacity(0.2))),
                    onPressed: () => setLocalState(() => estruturaTemp.add(label)),
                  )).toList(),
                ),

                if (estruturaTemp.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Sequência: ${estruturaTemp.join(' > ')}",
                      style: TextStyle(color: activeColor, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setLocalState(() => estruturaTemp.clear()),
                        child: const Text("Limpar", style: TextStyle(color: Colors.white38)),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          _metronomeTimer?.cancel();
                          onStructureConfirmed("BPM: $bpm | Estrutura: ${estruturaTemp.join(' > ')}");
                        },
                        child: const Text("INICIAR SESSÃO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      );
      
      onProgressUpdate(1, 1.0);
      scrollToBottom();
    });
  }
}