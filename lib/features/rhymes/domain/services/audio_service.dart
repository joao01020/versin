import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final _audioPlayer = AudioPlayer();
  Timer? _metronomeTimer;

  void startMetronome(int bpm) {
    _metronomeTimer?.cancel();
    int interval = (60000 / bpm).round();
    
    _metronomeTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      _playClick();
    });
    _playClick();
  }

  void stopMetronome() {
    _metronomeTimer?.cancel();
  }

  Future<void> _playClick() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/click.wav'));
    } catch (e) {
      debugPrint("Erro ao tocar som: $e");
    }
  }

  void dispose() {
    _metronomeTimer?.cancel();
    _audioPlayer.dispose();
  }
}