import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

/// Gestiona captura de micrófono y reproducción de audio PCM en tiempo real.
///
/// Flujo emisor:
///   startRecording(onFrame) → graba PCM → onFrame recibe frames base64
///
/// Flujo receptor:
///   feedFrame(bytes) → alimenta el player de streaming
///
/// Formato: PCM 16-bit signed, 16 kHz, mono (sin codec)
class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  bool _recorderInited = false;
  bool _playerInited = false;
  bool _isRecording = false;
  bool _playerStreaming = false;

  StreamController<Uint8List>? _recorderStreamCtrl;
  StreamSubscription<Uint8List>? _recorderSub;

  /// Inicializa recorder y player. Llamar una vez al entrar a la sala.
  Future<void> init() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return;

    await _recorder.openRecorder();
    _recorderInited = true;

    await _player.openPlayer();
    _playerInited = true;

    // Arrancar player en modo streaming — queda listo para recibir frames de peers
    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
      bufferSize: 8192,
      interleaved: true,
    );
    _playerStreaming = true;
  }

  /// Inicia captura de micrófono.
  /// [onFrame] recibe el frame JSON listo para enviar por WS.
  /// No-op si ya está grabando o el recorder no fue inicializado.
  Future<void> startRecording({
    required String canalId,
    required void Function(Map<String, dynamic> frame) onFrame,
  }) async {
    if (_isRecording || !_recorderInited) return;

    _recorderStreamCtrl = StreamController<Uint8List>();
    _recorderSub = _recorderStreamCtrl!.stream.listen((chunk) {
      if (chunk.isNotEmpty) {
        onFrame({
          'type': 'audio',
          'canal_id': canalId,
          'data': base64Encode(chunk),
        });
      }
    });

    await _recorder.startRecorder(
      toStream: _recorderStreamCtrl!.sink,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );
    _isRecording = true;
  }

  /// Detiene la captura de micrófono.
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    await _recorder.stopRecorder();
    await _recorderSub?.cancel();
    _recorderSub = null;
    await _recorderStreamCtrl?.close();
    _recorderStreamCtrl = null;
  }

  /// Alimenta el player con bytes PCM recibidos de un peer.
  /// Los bytes deben ser PCM 16-bit 16kHz mono.
  Future<void> feedFrame(Uint8List pcmBytes) async {
    if (!_playerStreaming || pcmBytes.isEmpty) return;
    try {
      await _player.feedUint8FromStream(pcmBytes);
    } catch (_) {
      // Player puede estar en transición — ignorar
    }
  }

  /// Libera todos los recursos. Llamar al salir de la sala.
  Future<void> dispose() async {
    await stopRecording();
    if (_playerStreaming) {
      await _player.stopPlayer();
      _playerStreaming = false;
    }
    if (_playerInited) {
      await _player.closePlayer();
      _playerInited = false;
    }
    if (_recorderInited) {
      await _recorder.closeRecorder();
      _recorderInited = false;
    }
  }
}
