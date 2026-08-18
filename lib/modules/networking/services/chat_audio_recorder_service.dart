import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

// ============================================================
// RECORDED CHAT AUDIO
// ============================================================
//
// Resultado final da gravação.
//
// Contém:
//
// - bytes WAV;
// - duração;
// - extensão;
// - MIME type.
//
// ============================================================

class RecordedChatAudio {
  final Uint8List bytes;

  final Duration duration;

  final String extension;

  final String mimeType;

  const RecordedChatAudio({
    required this.bytes,
    required this.duration,
    required this.extension,
    required this.mimeType,
  });

  // ==========================================================
  // DURAÇÃO
  // ==========================================================

  int get durationMs => duration.inMilliseconds;

  // ==========================================================
  // TAMANHO
  // ==========================================================

  int get sizeInBytes => bytes.lengthInBytes;

  // ==========================================================
  // ESTADO
  // ==========================================================

  bool get isEmpty => bytes.isEmpty;

  bool get isNotEmpty => bytes.isNotEmpty;
}

// ============================================================
// CHAT AUDIO RECORDER SERVICE
// ============================================================
//
// Responsável pela gravação de áudio do chat.
//
// Fluxo:
//
// ChatView
//    ↓
// ChatAudioRecorderService
//    ↓
// record
//    ↓
// PCM16
//    ↓
// WAV
//    ↓
// RecordedChatAudio
//
// Versão simples:
//
// - não pergunta fonte;
// - não usa AudioSourceDialog;
// - não usa AudioInputService;
// - não usa pactl;
// - não possui lógica específica de Linux.
//
// Ao chamar:
//
// await recorder.start();
//
// começa a gravação imediatamente.
//
// ============================================================

class ChatAudioRecorderService {
  // ==========================================================
  // CONFIGURAÇÃO
  // ==========================================================

  static const int sampleRate = 44100;

  static const int numChannels = 1;

  static const int bitsPerSample = 16;

  static const String fileExtension = 'wav';

  static const String mimeType = 'audio/wav';

  // ==========================================================
  // RECORDER
  // ==========================================================

  final AudioRecorder _recorder = AudioRecorder();

  // ==========================================================
  // STREAM
  // ==========================================================

  StreamSubscription<Uint8List>? _audioSubscription;

  // ==========================================================
  // BUFFER
  // ==========================================================

  final BytesBuilder _audioBuffer = BytesBuilder(copy: false);

  // ==========================================================
  // TIMER
  // ==========================================================

  final Stopwatch _stopwatch = Stopwatch();

  // ==========================================================
  // ESTADO
  // ==========================================================

  bool _isRecording = false;

  bool _isPaused = false;

  bool _disposed = false;

  // ==========================================================
  // GETTERS
  // ==========================================================

  bool get isRecording => _isRecording;

  bool get isPaused => _isPaused;

  bool get isActive => _isRecording || _isPaused;

  Duration get duration => _stopwatch.elapsed;

  // ==========================================================
  // PERMISSÃO
  // ==========================================================

  Future<bool> hasPermission() async {
    _ensureNotDisposed();

    try {
      return await _recorder.hasPermission();
    } catch (error, stackTrace) {
      debugPrint(
        '[CHAT AUDIO] '
        'Erro ao verificar permissão: '
        '$error',
      );

      debugPrint(
        '[CHAT AUDIO] '
        'StackTrace: '
        '$stackTrace',
      );

      return false;
    }
  }

  // ==========================================================
  // INICIAR GRAVAÇÃO
  // ==========================================================

  Future<bool> start() async {
    _ensureNotDisposed();

    // ========================================================
    // JÁ EXISTE GRAVAÇÃO
    // ========================================================

    if (_isRecording || _isPaused) {
      return false;
    }

    // ========================================================
    // PERMISSÃO
    // ========================================================

    final permission = await hasPermission();

    if (!permission) {
      debugPrint(
        '[CHAT AUDIO] '
        'Permissão do microfone negada.',
      );

      return false;
    }

    // ========================================================
    // RESET DA SESSÃO ANTERIOR
    // ========================================================

    await _resetSession();

    try {
      // ======================================================
      // CONFIGURAÇÃO
      // ======================================================

      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,

        sampleRate: sampleRate,

        numChannels: numChannels,

        echoCancel: true,

        noiseSuppress: true,

        autoGain: true,
      );

      // ======================================================
      // INICIAR STREAM
      // ======================================================

      final stream = await _recorder.startStream(config);

      // ======================================================
      // ESTADO
      // ======================================================

      _isRecording = true;

      _isPaused = false;

      _stopwatch
        ..reset()
        ..start();

      // ======================================================
      // RECEBER PCM
      // ======================================================

      _audioSubscription = stream.listen(
        (Uint8List chunk) {
          if (_disposed) {
            return;
          }

          if (!_isRecording) {
            return;
          }

          if (_isPaused) {
            return;
          }

          if (chunk.isEmpty) {
            return;
          }

          _audioBuffer.add(chunk);
        },

        onError: (Object error, StackTrace stackTrace) {
          debugPrint(
            '[CHAT AUDIO] '
            'Erro no stream: '
            '$error',
          );

          debugPrint(
            '[CHAT AUDIO] '
            'StackTrace: '
            '$stackTrace',
          );
        },
      );

      debugPrint(
        '[CHAT AUDIO] '
        'Gravação iniciada.',
      );

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '[CHAT AUDIO] '
        'Erro ao iniciar gravação: '
        '$error',
      );

      debugPrint(
        '[CHAT AUDIO] '
        'StackTrace: '
        '$stackTrace',
      );

      await _resetSession();

      return false;
    }
  }

  // ==========================================================
  // PAUSAR
  // ==========================================================

  Future<bool> pause() async {
    _ensureNotDisposed();

    if (!_isRecording || _isPaused) {
      return false;
    }

    try {
      await _recorder.pause();

      _stopwatch.stop();

      _isPaused = true;

      debugPrint(
        '[CHAT AUDIO] '
        'Gravação pausada.',
      );

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '[CHAT AUDIO] '
        'Erro ao pausar gravação: '
        '$error',
      );

      debugPrint(
        '[CHAT AUDIO] '
        'StackTrace: '
        '$stackTrace',
      );

      return false;
    }
  }

  // ==========================================================
  // CONTINUAR
  // ==========================================================

  Future<bool> resume() async {
    _ensureNotDisposed();

    if (!_isRecording || !_isPaused) {
      return false;
    }

    try {
      await _recorder.resume();

      _isPaused = false;

      _stopwatch.start();

      debugPrint(
        '[CHAT AUDIO] '
        'Gravação retomada.',
      );

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '[CHAT AUDIO] '
        'Erro ao continuar gravação: '
        '$error',
      );

      debugPrint(
        '[CHAT AUDIO] '
        'StackTrace: '
        '$stackTrace',
      );

      return false;
    }
  }

  // ==========================================================
  // FINALIZAR GRAVAÇÃO
  // ==========================================================

  Future<RecordedChatAudio?> stop() async {
    _ensureNotDisposed();

    if (!_isRecording) {
      return null;
    }

    // ========================================================
    // DURAÇÃO
    // ========================================================

    _stopwatch.stop();

    final recordedDuration = _stopwatch.elapsed;

    try {
      // ======================================================
      // PARAR RECORDER
      // ======================================================

      await _recorder.stop();

      // ======================================================
      // CANCELAR LISTENER
      // ======================================================

      await _audioSubscription?.cancel();

      _audioSubscription = null;

      // ======================================================
      // ESTADO
      // ======================================================

      _isRecording = false;

      _isPaused = false;

      // ======================================================
      // PCM
      // ======================================================

      final pcmBytes = _audioBuffer.takeBytes();

      if (pcmBytes.isEmpty) {
        debugPrint(
          '[CHAT AUDIO] '
          'Nenhum dado de áudio capturado.',
        );

        _stopwatch.reset();

        return null;
      }

      // ======================================================
      // CRIAR WAV
      // ======================================================

      final wavBytes = _createWavFile(pcmBytes);

      // ======================================================
      // RESULTADO
      // ======================================================

      final result = RecordedChatAudio(
        bytes: wavBytes,

        duration: recordedDuration,

        extension: fileExtension,

        mimeType: mimeType,
      );

      // ======================================================
      // LOG
      // ======================================================

      debugPrint(
        '[CHAT AUDIO] '
        'Gravação finalizada.',
      );

      debugPrint(
        '[CHAT AUDIO] '
        'Duração: '
        '${result.durationMs} ms.',
      );

      debugPrint(
        '[CHAT AUDIO] '
        'Tamanho: '
        '${result.sizeInBytes} bytes.',
      );

      // ======================================================
      // RESET TIMER
      // ======================================================

      _stopwatch.reset();

      return result;
    } catch (error, stackTrace) {
      debugPrint(
        '[CHAT AUDIO] '
        'Erro ao finalizar gravação: '
        '$error',
      );

      debugPrint(
        '[CHAT AUDIO] '
        'StackTrace: '
        '$stackTrace',
      );

      await _resetSession();

      return null;
    }
  }

  // ==========================================================
  // CANCELAR
  // ==========================================================

  Future<void> cancel() async {
    if (_disposed) {
      return;
    }

    if (!_isRecording && !_isPaused) {
      await _resetSession();

      return;
    }

    try {
      await _recorder.cancel();
    } catch (error) {
      debugPrint(
        '[CHAT AUDIO] '
        'Erro ao cancelar recorder: '
        '$error',
      );
    }

    await _resetSession();

    debugPrint(
      '[CHAT AUDIO] '
      'Gravação cancelada.',
    );
  }

  // ==========================================================
  // RESET SESSION
  // ==========================================================

  Future<void> _resetSession() async {
    // ========================================================
    // TIMER
    // ========================================================

    _stopwatch
      ..stop()
      ..reset();

    // ========================================================
    // ESTADO
    // ========================================================

    _isRecording = false;

    _isPaused = false;

    // ========================================================
    // STREAM
    // ========================================================

    await _audioSubscription?.cancel();

    _audioSubscription = null;

    // ========================================================
    // BUFFER
    // ========================================================

    _audioBuffer.takeBytes();
  }

  // ==========================================================
  // CRIAR ARQUIVO WAV
  // ==========================================================
  //
  // O package record entrega PCM16 pelo stream.
  //
  // Adicionamos manualmente o header WAV.
  //
  // Header:
  //
  // 0  - RIFF
  // 8  - WAVE
  // 12 - fmt
  // 36 - data
  //
  // ==========================================================

  Uint8List _createWavFile(Uint8List pcmBytes) {
    // ========================================================
    // TAMANHOS
    // ========================================================

    const int headerSize = 44;

    final int dataLength = pcmBytes.lengthInBytes;

    final int totalLength = headerSize + dataLength;

    // ========================================================
    // BUFFER FINAL
    // ========================================================

    final bytes = Uint8List(totalLength);

    final data = ByteData.view(bytes.buffer);

    // ========================================================
    // RIFF
    // ========================================================

    _writeAscii(bytes, 0, 'RIFF');

    data.setUint32(4, 36 + dataLength, Endian.little);

    // ========================================================
    // WAVE
    // ========================================================

    _writeAscii(bytes, 8, 'WAVE');

    // ========================================================
    // FMT
    // ========================================================

    _writeAscii(bytes, 12, 'fmt ');

    // ========================================================
    // FMT CHUNK SIZE
    // ========================================================

    data.setUint32(16, 16, Endian.little);

    // ========================================================
    // AUDIO FORMAT
    //
    // 1 = PCM
    // ========================================================

    data.setUint16(20, 1, Endian.little);

    // ========================================================
    // CANAIS
    // ========================================================

    data.setUint16(22, numChannels, Endian.little);

    // ========================================================
    // SAMPLE RATE
    // ========================================================

    data.setUint32(24, sampleRate, Endian.little);

    // ========================================================
    // BYTE RATE
    // ========================================================

    const int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;

    data.setUint32(28, byteRate, Endian.little);

    // ========================================================
    // BLOCK ALIGN
    // ========================================================

    const int blockAlign = numChannels * bitsPerSample ~/ 8;

    data.setUint16(32, blockAlign, Endian.little);

    // ========================================================
    // BITS PER SAMPLE
    // ========================================================

    data.setUint16(34, bitsPerSample, Endian.little);

    // ========================================================
    // DATA
    // ========================================================

    _writeAscii(bytes, 36, 'data');

    data.setUint32(40, dataLength, Endian.little);

    // ========================================================
    // PCM
    // ========================================================

    bytes.setRange(headerSize, totalLength, pcmBytes);

    return bytes;
  }

  // ==========================================================
  // ESCREVER ASCII NO HEADER
  // ==========================================================

  void _writeAscii(Uint8List bytes, int offset, String value) {
    for (int index = 0; index < value.length; index++) {
      bytes[offset + index] = value.codeUnitAt(index);
    }
  }

  // ==========================================================
  // VERIFICAR DISPOSE
  // ==========================================================

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('ChatAudioRecorderService já foi descartado.');
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    await cancel();

    _disposed = true;

    await _recorder.dispose();

    debugPrint(
      '[CHAT AUDIO] '
      'Recorder descartado.',
    );
  }
}
