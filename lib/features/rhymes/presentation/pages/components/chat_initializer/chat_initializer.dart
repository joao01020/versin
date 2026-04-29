import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

class ChatInitializer {
  static Timer? _metronomeTimer;
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final _supabase = Supabase.instance.client;

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

  static void _playMetronomeClick() {
    _audioPlayer.play(
      AssetSource('sounds/click.wav'), 
      mode: PlayerMode.lowLatency
    ).catchError((e) => debugPrint("Erro ao tocar áudio: $e"));
  }

  static Future<void> _saveSessionToDatabase(int bpm, List<String> estrutura) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('lyrics_history').insert({
        'profile_id': user.id,
        'content': 'Sessão iniciada: Aguardando composição...',
        'hash_signature': DateTime.now().millisecondsSinceEpoch.toString(),
        'bpm': bpm,
        'structure': estrutura.join(' > '),
      });
      debugPrint("Configurações salvas no Supabase com sucesso!");
    } catch (e) {
      debugPrint("Erro ao salvar no banco: $e");
    }
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
        "Salve! Sou o Versin. 🎤 Vamos preparar o estúdio. Arraste o BPM para ajustar e monte a sequência abaixo:",
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
              mainAxisSize: MainAxisSize.min,
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
                            Text("$bpm", style: TextStyle(color: activeColor, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                            const Text("BPM", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: Icon(isMetronomeOn ? Icons.timer : Icons.play_circle_outline_rounded, color: isMetronomeOn ? activeColor : Colors.white30, size: 40),
                      onPressed: () {
                        setLocalState(() {
                          isMetronomeOn = !isMetronomeOn;
                          toggleMetronomeLogic();
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 25),
                const Text("Toque para adicionar à sequência:", style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: opcoes.map((label) => ActionChip(
                    label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    backgroundColor: const Color(0xFF1A1A1A),
                    shape: StadiumBorder(side: BorderSide(color: activeColor.withOpacity(0.2))),
                    onPressed: () {
                      setLocalState(() => estruturaTemp.add(label));
                      scrollToBottom();
                    },
                  )).toList(),
                ),

                if (estruturaTemp.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  Text(
                    "Sua Estrutura (Toque no 'X' para remover):", 
                    style: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 15),
                  
                  // Alterado de ReorderableListView para Wrap para evitar o erro das imagens
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(estruturaTemp.length, (i) {
                      return Container(
                        padding: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: activeColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              estruturaTemp[i],
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              icon: const Icon(Icons.close, color: Colors.white54, size: 14),
                              onPressed: () => setLocalState(() => estruturaTemp.removeAt(i)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => setLocalState(() => estruturaTemp.clear()),
                        child: const Text("Limpar tudo", style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onPressed: () async {
                          _metronomeTimer?.cancel();
                          await _saveSessionToDatabase(bpm, estruturaTemp);
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