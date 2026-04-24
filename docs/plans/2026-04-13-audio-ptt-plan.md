# Audio PTT — WebSocket Relay Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Implementar captura de micrófono → relay WS → reproducción en peers usando flutter_sound, con PTT como gate de envío.

**Architecture:** Servicio de infraestructura sobre el stack Riverpod existente. Sin nueva capa domain — la lógica PTT ya existe en VoiceService/SalaNotifier.

**Dependencies:**
```bash
flutter pub add flutter_sound
flutter pub add permission_handler  # ya instalado — verificar que esté
```

**Contrato WS (backend ya implementado):**
- Emisor envía: `{"type":"audio","canal_id":"general","data":"<base64 PCM>"}`
- Peers reciben: `{"type":"audio","rider_id":"...","display_name":"...","data":"<base64 PCM>"}`
- Backend solo retransmite si el rider es el speaker activo en ptt_store (ya verificado)

**Formato de audio:** PCM 16-bit, 16 kHz, mono — sin codec, máxima compatibilidad

---

## Task 1: Añadir flutter_sound a pubspec.yaml

**Layer:** Configuración

**Files:**
- Modify: `pubspec.yaml`

**Implementation:**

Añadir bajo `dependencies:` (después de `permission_handler`):
```yaml
  flutter_sound: ^9.15.10
```

**Verification:**
```bash
cd /c/Users/becerra/Documents/startup/noray4/noray4_flutter
flutter pub get
# Expected: Resolving dependencies... (sin errores)
```

**Commit:**
```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flutter_sound for PTT audio relay"
```

---

## Task 2: Permisos de micrófono — Android e iOS

**Layer:** Configuración de plataforma

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml` — añadir permiso RECORD_AUDIO si no existe
- Modify: `ios/Runner/Info.plist` — añadir NSMicrophoneUsageDescription si no existe

**Implementation:**

En `AndroidManifest.xml`, dentro de `<manifest>` antes de `<application>`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

En `ios/Runner/Info.plist`, dentro de `<dict>`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Noray4 necesita acceso al micrófono para comunicación por voz en salidas.</string>
```

**Verification:**
```bash
flutter analyze
# Expected: No issues found!
```

**Commit:**
```bash
git add android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "chore(permisos): add microphone permission for audio PTT"
```

---

## Task 3: AudioEvent — nuevo WsEvent + parser actualizado

**Layer:** Data (models)

**Files:**
- Modify: `lib/features/sala/models/ws_events.dart`

**Implementation:**

Añadir `AudioEvent` después de `PresenciaEvent` (antes de `GenericEvent`):
```dart
// ─── Audio relay ─────────────────────────────────────────────────────────────

class AudioEvent extends WsEvent {
  final String riderId;
  final String displayName;
  final String canalId;
  final String data; // base64 PCM 16-bit 16kHz mono

  AudioEvent({
    required this.riderId,
    required this.displayName,
    required this.canalId,
    required this.data,
  });

  factory AudioEvent.fromJson(Map<String, dynamic> json) => AudioEvent(
        riderId: json['rider_id'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        canalId: json['canal_id'] as String? ?? 'general',
        data: json['data'] as String? ?? '',
      );
}
```

Actualizar `parseWsEnvelope` — añadir detección de frames de audio **antes** del switch por topic (los frames de audio llegan sin topic wrapper):
```dart
WsEvent? parseWsEnvelope(Map<String, dynamic> envelope) {
  // Audio frames arrive directly without MQTT topic wrapper
  if (envelope['type'] == 'audio') {
    try {
      return AudioEvent.fromJson(envelope);
    } catch (_) {
      return null;
    }
  }

  final topic = envelope['topic'] as String? ?? '';
  final payload = envelope['payload'] as Map<String, dynamic>? ?? {};

  try {
    if (topic.endsWith('/ubicacion')) {
      return UbicacionEvent.fromPayload(payload);
    }
    if (topic.endsWith('/chat')) {
      return ChatEvent.fromPayload(payload);
    }
    if (topic.endsWith('/voz')) {
      return VozEvent.fromPayload(payload);
    }
    if (topic.endsWith('/presencia')) {
      return PresenciaEvent.fromPayload(payload);
    }
    return GenericEvent(topic, payload);
  } catch (_) {
    return null;
  }
}
```

**Verification:**
```bash
flutter analyze lib/features/sala/models/ws_events.dart
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/sala/models/ws_events.dart
git commit -m "feat(sala): add AudioEvent and audio frame parsing to WS envelope"
```

---

## Task 4: WebSocketManager.send() — método de envío upstream

**Layer:** Data (services)

**Files:**
- Modify: `lib/features/sala/services/websocket_manager.dart`

**Implementation:**

Añadir el método `send` en la clase `WebSocketManager`, después de `_scheduleReconnect`:
```dart
/// Envía un frame JSON upstream por el canal WS activo.
/// No-op si el canal está cerrado o el manager fue disposed.
void send(Map<String, dynamic> frame) {
  if (_disposed || _channel == null) return;
  try {
    _channel!.sink.add(jsonEncode(frame));
  } catch (_) {
    // Canal cerrado entre la comprobación y el envío — ignorar
  }
}
```

**Verification:**
```bash
flutter analyze lib/features/sala/services/websocket_manager.dart
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/sala/services/websocket_manager.dart
git commit -m "feat(sala): add send() method to WebSocketManager for upstream frames"
```

---

## Task 5: AudioService — captura + reproducción PCM

**Layer:** Data (services)

**Files:**
- Create: `lib/features/sala/services/audio_service.dart`

**Implementation:**

```dart
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

  StreamController<Food>? _recorderStreamCtrl;
  StreamSubscription<Food>? _recorderSub;

  /// Inicializa recorder y player. Llamar una vez al entrar a la sala.
  Future<void> init() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return;

    await _recorder.openRecorder();
    _recorderInited = true;

    await _player.openPlayer();
    _playerInited = true;

    // Arrancar player en modo streaming inmediatamente — queda listo para recibir frames
    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );
    _playerStreaming = true;
  }

  /// Inicia captura de micrófono. [onFrame] recibe el frame JSON listo para enviar por WS.
  /// No-op si ya está grabando o el recorder no fue inicializado.
  Future<void> startRecording({
    required String canalId,
    required void Function(Map<String, dynamic> frame) onFrame,
  }) async {
    if (_isRecording || !_recorderInited) return;

    _recorderStreamCtrl = StreamController<Food>();
    _recorderSub = _recorderStreamCtrl!.stream.listen((food) {
      if (food is FoodData && food.data != null && food.data!.isNotEmpty) {
        onFrame({
          'type': 'audio',
          'canal_id': canalId,
          'data': base64Encode(food.data!),
        });
      }
    });

    await _recorder.startRecorder(
      toStream: _recorderStreamCtrl!.sink,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
      bufferSize: 8192, // ~250ms a 16kHz/16bit/mono
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
  /// Los bytes deben ser PCM 16-bit 16kHz mono (igual que lo que se grabó).
  Future<void> feedFrame(Uint8List pcmBytes) async {
    if (!_playerStreaming || pcmBytes.isEmpty) return;
    try {
      await _player.feedFromStream(pcmBytes);
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
```

**Verification:**
```bash
flutter analyze lib/features/sala/services/audio_service.dart
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/sala/services/audio_service.dart
git commit -m "feat(sala): add AudioService with flutter_sound streaming capture and playback"
```

---

## Task 6: SalaNotifier — wiring AudioService con PTT y AudioEvent

**Layer:** Presentation (state)

**Files:**
- Modify: `lib/features/sala/providers/sala_provider.dart`

**Implementation:**

Añadir import al inicio del archivo:
```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:noray4/features/sala/services/audio_service.dart';
```

Añadir campo `_audio` en `SalaNotifier` (junto a los otros late final):
```dart
late final AudioService _audio;
```

En el constructor de `SalaNotifier`, inicializar `_audio` junto con los otros servicios:
```dart
_audio = AudioService();
```

En `_init()`, después de `_location.start()`:
```dart
_audio.init().ignore(); // init async — no bloquea el arranque de la sala
```

Actualizar `_handlePttState` para arrancar/detener grabación según si soy el speaker:
```dart
void _handlePttState(PttState pttState) {
  final isMe = pttState.speakerId == _myRiderId;
  final wasSpeaking = state.isPttActive;

  state = state.copyWith(
    isPttActive: isMe && pttState.isSpeaking,
    activeSpeakerId: pttState.isSpeaking ? pttState.speakerId : null,
    activeSpeakerName: pttState.isSpeaking ? pttState.speakerName : null,
    clearActiveSpeaker: !pttState.isSpeaking,
  );

  if (isMe && pttState.isSpeaking && !wasSpeaking) {
    _audio.startRecording(
      canalId: 'general',
      onFrame: _ws.send,
    );
  } else if (isMe && !pttState.isSpeaking && wasSpeaking) {
    _audio.stopRecording();
  }
}
```

Añadir case `AudioEvent` en `_handleWsEvent` (dentro del switch, después de `PresenciaEvent`):
```dart
case AudioEvent():
  if (event.riderId != _myRiderId && event.data.isNotEmpty) {
    _audio.feedFrame(base64Decode(event.data));
  }
```

Actualizar `dispose()` — añadir `_audio.dispose()` antes de `super.dispose()`:
```dart
@override
void dispose() {
  _wsSub?.cancel();
  _wsStatusSub?.cancel();
  _ws.dispose();
  _location.stop();
  _voice.dispose();
  _audio.dispose().ignore();
  super.dispose();
}
```

**Verification:**
```bash
flutter analyze lib/features/sala/providers/sala_provider.dart
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/sala/providers/sala_provider.dart
git commit -m "feat(sala): wire AudioService into SalaNotifier — PTT gates mic capture, peers receive frames"
```

---

## Verification final end-to-end

```bash
flutter analyze
# Expected: No issues found!

flutter build apk --debug
# Expected: Build completado sin errores
```

**Test manual (dos dispositivos o emulador + físico):**
1. Ambos riders entran a la misma sala
2. Rider A mantiene PTT → el botón muestra estado activo
3. Rider B debe escuchar audio de Rider A
4. Rider A suelta PTT → audio se detiene
5. Rider B intenta PTT con Rider A activo → 409 ignorado (comportamiento existente)

---

## Notas de ajuste post-MVP

| Parámetro | Valor actual | Ajuste posible |
|-----------|-------------|----------------|
| Sample rate | 16 kHz | 8 kHz (menor ancho de banda) |
| Buffer size | 8192 bytes (~250ms) | 4096 (~125ms) para menor latencia |
| Codec | PCM raw | Opus (menor datos, requiere plugin nativo) |
| Canal | `general` hardcoded | Usar canal dinámico de `VoiceService` |
