# Sala Activa — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Conectar la sala activa al backend real — mapa con GPS en vivo, chat por WebSocket, y PTT con señalización al servidor.

**Architecture:** Riverpod StateNotifier (sin cambio de patrón). Se extiende `SalaNotifier` con `WebSocketManager` y `LocationService`.

**Base URL REST:** `https://web-production-66456.up.railway.app`  
**WebSocket URL:** `wss://web-production-66456.up.railway.app/ws/{salaId}?token=<jwt>`

**Dependencies a agregar:**
```bash
flutter pub add web_socket_channel
flutter pub add geolocator
```

**Alcance de este sprint (Sprint 1):**
- Módulo 1: WebSocketManager — conexión, tipado, backoff
- Módulo 2: Mapa tiempo real — GPS propio + posiciones de todos los riders
- Módulo 3: Chat tiempo real — WebSocket + fallback polling
- Módulo 4: PTT señalización — start/stop backend + timer 30s + visual real

**Fuera de alcance (Sprint 2):** Audio WebRTC real (flutter_webrtc).

---

## Módulo 1 — WebSocket Manager

### Task 1: Agregar dependencias

**Layer:** Setup

**Files:**
- Modify: `pubspec.yaml`

**Implementation:**
```yaml
# En la sección dependencies, agregar después de google_sign_in:
  web_socket_channel: ^3.0.1
  geolocator: ^13.0.2
```

**Permisos Android** — agregar en `android/app/src/main/AndroidManifest.xml` antes de `<application`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

**Permisos iOS** — agregar en `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Noray4 usa tu ubicación para compartirla con tu tripulación.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Noray4 usa tu ubicación en segundo plano durante una salida activa.</string>
```

**Verification:**
```bash
flutter pub get
flutter analyze
# Expected: No issues found!
```

**Commit:**
```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "feat(sala): add web_socket_channel and geolocator dependencies"
```

---

### Task 2: WsEvent — modelos tipados de eventos WebSocket

**Layer:** Data

**Files:**
- Create: `lib/features/sala/models/ws_events.dart`

**Context:** El backend envía envelopes JSON con la forma:
```json
{ "topic": "noray4/{sala_id}/ubicacion", "payload": { ... } }
```
Los topics posibles son: `/ubicacion`, `/chat`, `/voz`, `/presencia`, `/eventos`.

**Implementation:**
```dart
import 'package:noray4/features/sala/services/chat_service.dart';

// ─── Sealed base ─────────────────────────────────────────────────────────────

sealed class WsEvent {}

// ─── Ubicación ────────────────────────────────────────────────────────────────

class UbicacionEvent extends WsEvent {
  final String riderId;
  final double lat;
  final double lng;
  final double? heading;
  final double? speed;
  final DateTime timestamp;

  UbicacionEvent({
    required this.riderId,
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
    required this.timestamp,
  });

  factory UbicacionEvent.fromPayload(Map<String, dynamic> p) => UbicacionEvent(
        riderId: p['rider_id'] as String,
        lat: (p['lat'] as num).toDouble(),
        lng: (p['lng'] as num).toDouble(),
        heading: (p['heading'] as num?)?.toDouble(),
        speed: (p['speed'] as num?)?.toDouble(),
        timestamp: DateTime.tryParse(p['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}

// ─── Chat ─────────────────────────────────────────────────────────────────────

class ChatEvent extends WsEvent {
  final MensajeOut mensaje;
  ChatEvent(this.mensaje);

  factory ChatEvent.fromPayload(Map<String, dynamic> p) =>
      ChatEvent(MensajeOut.fromJson(p));
}

// ─── Voz / PTT ───────────────────────────────────────────────────────────────

class VozEvent extends WsEvent {
  final String type; // ptt_start | ptt_stop | force_release | webrtc_signal
  final String canalId;
  final String? speakerId;
  final String? speakerName;
  final Map<String, dynamic>? rawPayload;

  VozEvent({
    required this.type,
    required this.canalId,
    this.speakerId,
    this.speakerName,
    this.rawPayload,
  });

  factory VozEvent.fromPayload(Map<String, dynamic> p) => VozEvent(
        type: p['type'] as String? ?? '',
        canalId: p['canal_id'] as String? ?? 'general',
        speakerId: p['speaker_id'] as String?,
        speakerName: p['speaker_name'] as String?,
        rawPayload: p,
      );
}

// ─── Presencia ────────────────────────────────────────────────────────────────

class PresenciaEvent extends WsEvent {
  final String riderId;
  final String displayName;
  final String status; // online | offline

  PresenciaEvent({
    required this.riderId,
    required this.displayName,
    required this.status,
  });

  factory PresenciaEvent.fromPayload(Map<String, dynamic> p) => PresenciaEvent(
        riderId: p['rider_id'] as String? ?? '',
        displayName: p['display_name'] as String? ?? '',
        status: p['status'] as String? ?? 'offline',
      );
}

// ─── Evento genérico ──────────────────────────────────────────────────────────

class GenericEvent extends WsEvent {
  final String topic;
  final Map<String, dynamic> payload;
  GenericEvent(this.topic, this.payload);
}

// ─── Parser de envelope ───────────────────────────────────────────────────────

WsEvent? parseWsEnvelope(Map<String, dynamic> envelope) {
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
git commit -m "feat(sala): add typed WebSocket event models"
```

---

### Task 3: WebSocketManager — conexión con backoff exponencial

**Layer:** Data / Service

**Files:**
- Create: `lib/features/sala/services/websocket_manager.dart`

**Context:**
- Token JWT en `FlutterSecureStorage` con key `'auth_token'`
- URL: `wss://web-production-66456.up.railway.app/ws/{salaId}?token=<jwt>`
- Backoff: 1s, 2s, 4s, 8s, 16s, tope 30s
- Riders sin señal >30s se marcan offline (manejado en SalaNotifier, no aquí)

**Implementation:**
```dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:noray4/features/sala/models/ws_events.dart';

enum WsStatus { disconnected, connecting, connected, error }

class WebSocketManager {
  final String salaId;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _disposed = false;
  int _retryCount = 0;

  final _eventController = StreamController<WsEvent>.broadcast();
  final _statusController = StreamController<WsStatus>.broadcast();

  Stream<WsEvent> get events => _eventController.stream;
  Stream<WsStatus> get status => _statusController.stream;

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _baseWsUrl = 'wss://web-production-66456.up.railway.app';

  WebSocketManager({required this.salaId});

  Future<void> connect() async {
    if (_disposed) return;
    _statusController.add(WsStatus.connecting);

    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      _statusController.add(WsStatus.error);
      return;
    }

    final uri = Uri.parse('$_baseWsUrl/ws/$salaId?token=$token');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _retryCount = 0;
      _statusController.add(WsStatus.connected);

      _sub = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _onDisconnected(),
        onDone: _onDisconnected,
        cancelOnError: true,
      );
    } catch (_) {
      _onDisconnected();
    }
  }

  void _onMessage(dynamic raw) {
    if (_disposed) return;
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = parseWsEnvelope(map);
      if (event != null) _eventController.add(event);
    } catch (_) {
      // malformed frame — ignorar
    }
  }

  void _onDisconnected() {
    if (_disposed) return;
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _statusController.add(WsStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    final delay = Duration(seconds: min(30, pow(2, _retryCount).toInt()));
    _retryCount++;
    _reconnectTimer = Timer(delay, connect);
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _eventController.close();
    _statusController.close();
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
git commit -m "feat(sala): add WebSocketManager with exponential backoff reconnection"
```

---

## Módulo 2 — Mapa Tiempo Real

### Task 4: RiderPosition + extender SalaState

**Layer:** Domain / Model

**Files:**
- Modify: `lib/features/sala/models/sala_models.dart`

**Context:** Agregar `RiderPosition` (posición en vivo de un rider) y extender `SalaState` con los campos de tiempo real. No eliminar nada existente.

**Implementation — agregar al final de `sala_models.dart` y extender `SalaState`:**

```dart
// ─── Agregar esta clase nueva ─────────────────────────────────────────────────

class RiderPosition {
  final String riderId;
  final double lat;
  final double lng;
  final double? heading;
  final double? speed;
  final DateTime updatedAt;

  const RiderPosition({
    required this.riderId,
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
    required this.updatedAt,
  });

  factory RiderPosition.fromJson(String riderId, Map<String, dynamic> json) =>
      RiderPosition(
        riderId: riderId,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
        speed: (json['speed'] as num?)?.toDouble(),
        updatedAt: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );

  bool get isStale =>
      DateTime.now().difference(updatedAt).inSeconds > 30;
}
```

**SalaState — reemplazar la clase completa** (conservando todos los campos existentes + los nuevos):

```dart
class SalaState {
  final String salaId;
  final String nombre;
  final SalaTab activeTab;
  final List<SalaMessage> messages;
  final List<SalaRider> riders;
  final String tiempo;
  final String distancia;
  final bool isPttActive;
  final bool isVoiceActive;
  final bool isLoading;
  final String? error;
  // ── Tiempo real (nuevos) ────────────────────────────────────────────────────
  final Map<String, RiderPosition> lastPositions; // riderId → position
  final String? activeSpeakerId;
  final String? activeSpeakerName;
  final bool wsConnected;
  final bool gpsActive;

  const SalaState({
    required this.salaId,
    this.nombre = '',
    this.activeTab = SalaTab.mapa,
    this.messages = const [],
    this.riders = const [],
    this.tiempo = '0h 00m',
    this.distancia = '0 km',
    this.isPttActive = false,
    this.isVoiceActive = true,
    this.isLoading = false,
    this.error,
    this.lastPositions = const {},
    this.activeSpeakerId,
    this.activeSpeakerName,
    this.wsConnected = false,
    this.gpsActive = false,
  });

  SalaState copyWith({
    String? nombre,
    SalaTab? activeTab,
    List<SalaMessage>? messages,
    List<SalaRider>? riders,
    bool? isPttActive,
    bool? isVoiceActive,
    String? tiempo,
    String? distancia,
    bool? isLoading,
    String? error,
    Map<String, RiderPosition>? lastPositions,
    String? activeSpeakerId,
    bool clearActiveSpeaker = false,
    String? activeSpeakerName,
    bool? wsConnected,
    bool? gpsActive,
  }) =>
      SalaState(
        salaId: salaId,
        nombre: nombre ?? this.nombre,
        activeTab: activeTab ?? this.activeTab,
        messages: messages ?? this.messages,
        riders: riders ?? this.riders,
        tiempo: tiempo ?? this.tiempo,
        distancia: distancia ?? this.distancia,
        isPttActive: isPttActive ?? this.isPttActive,
        isVoiceActive: isVoiceActive ?? this.isVoiceActive,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        lastPositions: lastPositions ?? this.lastPositions,
        activeSpeakerId: clearActiveSpeaker ? null : (activeSpeakerId ?? this.activeSpeakerId),
        activeSpeakerName: clearActiveSpeaker ? null : (activeSpeakerName ?? this.activeSpeakerName),
        wsConnected: wsConnected ?? this.wsConnected,
        gpsActive: gpsActive ?? this.gpsActive,
      );
}
```

**Verification:**
```bash
flutter analyze lib/features/sala/models/sala_models.dart
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/sala/models/sala_models.dart
git commit -m "feat(sala): add RiderPosition model and real-time fields to SalaState"
```

---

### Task 5: LocationService — GPS propio + publicación al backend

**Layer:** Data / Service

**Files:**
- Create: `lib/features/sala/services/location_service.dart`

**Context:**
- Publica propia posición cada 3s via `POST /api/v1/location/salas/{salaId}/update`
- El backend retorna `last_positions` de todos los riders — esto es la fuente principal del mapa
- Geolocator requiere permiso; si se deniega, publica sin coordenadas propias
- `onPositionsUpdated` es el callback al SalaNotifier

**Implementation:**
```dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import 'package:noray4/core/network/api_client.dart';
import 'package:noray4/core/network/api_endpoints.dart';
import 'package:noray4/features/sala/models/sala_models.dart';

class LocationService {
  final String salaId;
  final void Function(Map<String, RiderPosition> positions) onPositionsUpdated;
  final void Function(bool active) onGpsStatusChanged;

  final Dio _dio = ApiClient.instance.dio;
  Timer? _timer;
  Position? _lastPosition;
  bool _permissionGranted = false;

  LocationService({
    required this.salaId,
    required this.onPositionsUpdated,
    required this.onGpsStatusChanged,
  });

  Future<void> start() async {
    _permissionGranted = await _requestPermission();
    onGpsStatusChanged(_permissionGranted);

    // Publicar inmediatamente al entrar, luego cada 3s
    await _publishAndFetch();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _publishAndFetch());
  }

  Future<bool> _requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> _publishAndFetch() async {
    try {
      final data = <String, dynamic>{};

      if (_permissionGranted) {
        try {
          _lastPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5, // solo si se movió >5m
            ),
          );
          data['lat'] = _lastPosition!.latitude;
          data['lng'] = _lastPosition!.longitude;
          if (_lastPosition!.heading >= 0) {
            data['heading'] = _lastPosition!.heading;
          }
          if (_lastPosition!.speed >= 0) {
            data['speed'] = _lastPosition!.speed;
          }
        } catch (_) {
          // GPS timeout — publicar con última posición conocida si existe
          if (_lastPosition != null) {
            data['lat'] = _lastPosition!.latitude;
            data['lng'] = _lastPosition!.longitude;
          }
        }
      }

      // Si no hay coordenadas, enviar igual para recibir last_positions
      if (data.isEmpty) data['lat'] = 0.0; // backend lo ignora pero retorna positions

      final res = await _dio.post(
        ApiEndpoints.locationUpdate(salaId),
        data: data,
      );

      final raw = res.data as Map<String, dynamic>;
      final rawPositions = raw['last_positions'] as Map<String, dynamic>? ?? {};

      final positions = rawPositions.map((riderId, posJson) => MapEntry(
            riderId,
            RiderPosition.fromJson(
                riderId, posJson as Map<String, dynamic>),
          ));

      onPositionsUpdated(positions);
    } catch (_) {
      // Network error — no interrumpir el timer
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
```

**Verification:**
```bash
flutter analyze lib/features/sala/services/location_service.dart
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/sala/services/location_service.dart
git commit -m "feat(sala): add LocationService with GPS polling and last_positions merge"
```

---

### Task 6: VoiceService — PTT al backend + timer auto-release

**Layer:** Data / Service

**Files:**
- Create: `lib/features/sala/services/voice_service.dart`

**Context:**
- `POST /api/v1/voice/{salaId}/ptt` con body `{action: start|stop, canal_id}`
- Timer de 30s: si el usuario no suelta, el servicio hace auto-stop
- Respuesta: `PTTState {canal_id, speaker_id, speaker_name, is_speaking}`

**Implementation:**
```dart
import 'dart:async';

import 'package:dio/dio.dart';

import 'package:noray4/core/network/api_client.dart';
import 'package:noray4/core/network/api_endpoints.dart';

class PttState {
  final String canalId;
  final String? speakerId;
  final String? speakerName;
  final bool isSpeaking;

  const PttState({
    required this.canalId,
    this.speakerId,
    this.speakerName,
    required this.isSpeaking,
  });

  factory PttState.fromJson(Map<String, dynamic> json) => PttState(
        canalId: json['canal_id'] as String? ?? 'general',
        speakerId: json['speaker_id'] as String?,
        speakerName: json['speaker_name'] as String?,
        isSpeaking: json['is_speaking'] as bool? ?? false,
      );
}

class VoiceService {
  final String salaId;
  final String myRiderId;
  final void Function(PttState state) onPttStateChanged;

  final Dio _dio = ApiClient.instance.dio;
  Timer? _autoReleaseTimer;
  bool _isSpeaking = false;

  static const _autoReleaseDuration = Duration(seconds: 30);
  static const _defaultCanal = 'general';

  VoiceService({
    required this.salaId,
    required this.myRiderId,
    required this.onPttStateChanged,
  });

  Future<void> startPtt({String canalId = _defaultCanal}) async {
    if (_isSpeaking) return;
    try {
      final res = await _dio.post(
        ApiEndpoints.voicePtt(salaId),
        data: {'action': 'start', 'canal_id': canalId},
      );
      final pttState = PttState.fromJson(res.data as Map<String, dynamic>);
      if (pttState.speakerId == myRiderId) {
        _isSpeaking = true;
        // Auto-release en 30s
        _autoReleaseTimer = Timer(_autoReleaseDuration, () => stopPtt(canalId: canalId));
        onPttStateChanged(pttState);
      } else {
        // Otro rider tiene el turno — notificar con su estado
        onPttStateChanged(pttState);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Canal ocupado — parsear quien habla
        final data = e.response?.data as Map<String, dynamic>?;
        // El 409 retorna {detail: "..."}, no PTTState — ignorar silenciosamente
      }
    }
  }

  Future<void> stopPtt({String canalId = _defaultCanal}) async {
    if (!_isSpeaking) return;
    _autoReleaseTimer?.cancel();
    _isSpeaking = false;
    try {
      final res = await _dio.post(
        ApiEndpoints.voicePtt(salaId),
        data: {'action': 'stop', 'canal_id': canalId},
      );
      final pttState = PttState.fromJson(res.data as Map<String, dynamic>);
      onPttStateChanged(pttState);
    } catch (_) {
      // Fallo silencioso — estado local ya reseteado
    }
  }

  void dispose() {
    _autoReleaseTimer?.cancel();
    if (_isSpeaking) {
      stopPtt(); // best-effort cleanup
    }
  }
}
```

**Verification:**
```bash
flutter analyze lib/features/sala/services/voice_service.dart
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/sala/services/voice_service.dart
git commit -m "feat(sala): add VoiceService with PTT signaling and 30s auto-release"
```

---

### Task 7: Extender SalaNotifier — conectar todos los servicios

**Layer:** Presentation / State

**Files:**
- Modify: `lib/features/sala/providers/sala_provider.dart`

**Context:** Reemplazar el `SalaNotifier` completo. Mantiene la misma interfaz pública. Añade:
- `WebSocketManager` → consume eventos → actualiza state
- `LocationService` → publica GPS + actualiza `lastPositions`
- `VoiceService` → PTT al backend

**Implementation:**
```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/features/sala/models/sala_models.dart';
import 'package:noray4/features/sala/models/ws_events.dart';
import 'package:noray4/features/sala/services/chat_service.dart';
import 'package:noray4/features/sala/services/location_service.dart';
import 'package:noray4/features/sala/services/salas_service.dart';
import 'package:noray4/features/sala/services/voice_service.dart';
import 'package:noray4/features/sala/services/websocket_manager.dart';

class SalaNotifier extends StateNotifier<SalaState> {
  final String _salaId;
  final String _myRiderId;

  final _salasService = SalasService();
  final _chatService = ChatService();

  late final WebSocketManager _ws;
  late final LocationService _location;
  late final VoiceService _voice;

  StreamSubscription<WsEvent>? _wsSub;
  StreamSubscription<WsStatus>? _wsStatusSub;

  SalaNotifier(this._salaId, this._myRiderId)
      : super(SalaState(salaId: _salaId, isLoading: true)) {
    _ws = WebSocketManager(salaId: _salaId);
    _location = LocationService(
      salaId: _salaId,
      onPositionsUpdated: _handlePositions,
      onGpsStatusChanged: (active) =>
          state = state.copyWith(gpsActive: active),
    );
    _voice = VoiceService(
      salaId: _salaId,
      myRiderId: _myRiderId,
      onPttStateChanged: _handlePttState,
    );
    _init();
  }

  // ── Inicialización ────────────────────────────────────────────────────────

  Future<void> _init() async {
    try {
      final results = await Future.wait([
        _salasService.getSala(_salaId),
        _chatService.getMensajes(_salaId, limit: 50),
      ]);

      final sala = results[0] as SalaOut;
      final paginado = results[1] as PaginatedMensajes;

      final riders = sala.miembros
          .map((m) => SalaRider.fromMiembro({
                'rider_id': m.riderId,
                'display_name': m.displayName,
                'role': m.role,
              }))
          .toList();

      final messages = paginado.items
          .where((m) => !m.deleted && m.content != null)
          .map((m) => SalaMessage.fromApi({
                '_id': m.id,
                'rider_id': m.riderId,
                'display_name': m.displayName,
                'content': m.content,
                'created_at': m.createdAt,
                'media_url': m.mediaUrl,
              }, _myRiderId))
          .toList();

      state = state.copyWith(
        nombre: sala.name,
        riders: riders,
        messages: messages,
        tiempo: _calcTiempo(sala.createdAt),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }

    // Iniciar servicios en tiempo real
    _connectWebSocket();
    _location.start();
  }

  // ── WebSocket ─────────────────────────────────────────────────────────────

  void _connectWebSocket() {
    _wsStatusSub = _ws.status.listen((status) {
      state = state.copyWith(wsConnected: status == WsStatus.connected);
    });

    _wsSub = _ws.events.listen(_handleWsEvent);
    _ws.connect();
  }

  void _handleWsEvent(WsEvent event) {
    switch (event) {
      case UbicacionEvent():
        final updated = Map<String, RiderPosition>.from(state.lastPositions);
        updated[event.riderId] = RiderPosition(
          riderId: event.riderId,
          lat: event.lat,
          lng: event.lng,
          heading: event.heading,
          speed: event.speed,
          updatedAt: event.timestamp,
        );
        state = state.copyWith(lastPositions: updated);

      case ChatEvent():
        final msg = event.mensaje;
        if (msg.deleted) return;
        // Deduplicar por ID (el optimista podría ya estar)
        final exists = state.messages.any((m) => m.id == msg.id);
        if (!exists) {
          final newMessage = SalaMessage.fromApi({
            '_id': msg.id,
            'rider_id': msg.riderId,
            'display_name': msg.displayName,
            'content': msg.content,
            'created_at': msg.createdAt,
            'media_url': msg.mediaUrl,
          }, _myRiderId);
          state = state.copyWith(
              messages: [...state.messages, newMessage]);
        }
        // ACK automático
        _chatService.ackMensaje(_salaId, msg.id).ignore();

      case VozEvent():
        if (event.type == 'ptt_start') {
          state = state.copyWith(
            activeSpeakerId: event.speakerId,
            activeSpeakerName: event.speakerName,
            isVoiceActive: true,
          );
        } else if (event.type == 'ptt_stop' ||
            event.type == 'force_release') {
          state = state.copyWith(clearActiveSpeaker: true);
        }

      case PresenciaEvent():
        // Actualizar lista de riders online/offline
        // (visual feedback — no modifica la lista estructural)
        break;

      case GenericEvent():
        break;
    }
  }

  // ── Location ──────────────────────────────────────────────────────────────

  void _handlePositions(Map<String, RiderPosition> positions) {
    // Fusionar con lo que ya teníamos (WS puede tener datos más frescos)
    final merged = Map<String, RiderPosition>.from(state.lastPositions);
    positions.forEach((riderId, pos) {
      final existing = merged[riderId];
      if (existing == null ||
          pos.updatedAt.isAfter(existing.updatedAt)) {
        merged[riderId] = pos;
      }
    });
    state = state.copyWith(lastPositions: merged);
  }

  // ── PTT ───────────────────────────────────────────────────────────────────

  void _handlePttState(PttState pttState) {
    final isMe = pttState.speakerId == _myRiderId;
    state = state.copyWith(
      isPttActive: isMe && pttState.isSpeaking,
      activeSpeakerId: pttState.isSpeaking ? pttState.speakerId : null,
      activeSpeakerName: pttState.isSpeaking ? pttState.speakerName : null,
      clearActiveSpeaker: !pttState.isSpeaking,
    );
  }

  // ── Acciones públicas ─────────────────────────────────────────────────────

  Future<void> refresh() => _init();

  void switchTab(SalaTab tab) => state = state.copyWith(activeTab: tab);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final optimistic = SalaMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'Tú',
      riderId: _myRiderId,
      text: text.trim(),
      time: _formatTime(DateTime.now()),
      isOutgoing: true,
    );
    state = state.copyWith(messages: [...state.messages, optimistic]);
    try {
      await _chatService.sendText(_salaId, text.trim());
    } catch (_) {
      // Mantener mensaje optimista sin rollback
    }
  }

  Future<void> startPtt() => _voice.startPtt();
  Future<void> stopPtt() => _voice.stopPtt();

  // Legacy compat (llamado desde VozTab / MapTab como void callbacks)
  void setPtt(bool active) {
    if (active) {
      startPtt();
    } else {
      stopPtt();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _calcTiempo(String createdAtIso) {
    try {
      final start = DateTime.parse(createdAtIso);
      final diff = DateTime.now().difference(start);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    } catch (_) {
      return '0h 00m';
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsStatusSub?.cancel();
    _ws.dispose();
    _location.stop();
    _voice.dispose();
    super.dispose();
  }
}

final salaProvider =
    StateNotifierProvider.family<SalaNotifier, SalaState, String>(
  (ref, salaId) {
    final myRiderId = ref.watch(authProvider).user?.id ?? '';
    return SalaNotifier(salaId, myRiderId);
  },
);
```

**Verification:**
```bash
flutter analyze lib/features/sala/providers/sala_provider.dart
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/sala/providers/sala_provider.dart
git commit -m "feat(sala): wire WebSocketManager + LocationService + VoiceService into SalaNotifier"
```

---

### Task 8: MapTab — markers reales con heading + controles de cámara

**Layer:** Presentation / Widget

**Files:**
- Modify: `lib/features/sala/widgets/map_tab.dart`

**Context:**
- Reemplazar los `_mockPositions` por `state.lastPositions`
- Marker propio: borde blanco, fondo oscuro inverso
- Marker otros: initials del rider
- Heading: rotar marker con `Transform.rotate`
- Botón "centrar en mí" → mueve cámara a posición propia
- Botón "ver todos" → fit bounds de todas las posiciones
- `MapController` ya existe — añadir `fitCamera`

**Implementation — reemplazar `map_tab.dart` completo:**

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/sala/models/sala_models.dart';
import 'package:noray4/features/sala/providers/sala_provider.dart';

const _darkTileFilter = ColorFilter.matrix(<double>[
  -1, 0, 0, 0, 255,
   0,-1, 0, 0, 255,
   0, 0,-1, 0, 255,
   0, 0, 0, 1,   0,
]);

// ─── MapTab ───────────────────────────────────────────────────────────────────

class MapTab extends ConsumerStatefulWidget {
  final SalaState sala;
  final VoidCallback onPttPressed;
  final VoidCallback onPttReleased;

  const MapTab({
    super.key,
    required this.sala,
    required this.onPttPressed,
    required this.onPttReleased,
  });

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _voiceAnim;
  final _mapController = MapController();
  static const _defaultCenter = LatLng(19.4326, -99.1332);

  @override
  void initState() {
    super.initState();
    _voiceAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _voiceAnim.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Cámara ────────────────────────────────────────────────────────────────

  void _centerOnMe() {
    final myRiderId = ref.read(authProvider).user?.id ?? '';
    final myPos = widget.sala.lastPositions[myRiderId];
    if (myPos != null) {
      _mapController.move(LatLng(myPos.lat, myPos.lng), 15);
    } else {
      _mapController.move(_defaultCenter, 13);
    }
  }

  void _fitAll() {
    final positions = widget.sala.lastPositions.values;
    if (positions.isEmpty) {
      _mapController.move(_defaultCenter, 13);
      return;
    }
    if (positions.length == 1) {
      final p = positions.first;
      _mapController.move(LatLng(p.lat, p.lng), 14);
      return;
    }
    final bounds = LatLngBounds.fromPoints(
      positions.map((p) => LatLng(p.lat, p.lng)).toList(),
    );
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
  }

  void _zoomIn() => _mapController.move(
      _mapController.camera.center, _mapController.camera.zoom + 1);
  void _zoomOut() => _mapController.move(
      _mapController.camera.center, _mapController.camera.zoom - 1);

  // ── Markers ───────────────────────────────────────────────────────────────

  List<Marker> _buildMarkers() {
    final myRiderId = ref.read(authProvider).user?.id ?? '';
    final riders = widget.sala.riders;

    // riderId → initials lookup
    final initialsMap = {
      for (final r in riders) r.riderId ?? '': r.initials,
    };

    return widget.sala.lastPositions.entries
        .where((e) => !e.value.isStale) // ocultar riders sin señal >30s
        .map((entry) {
          final riderId = entry.key;
          final pos = entry.value;
          final isSelf = riderId == myRiderId;
          final initials = isSelf ? 'YO' : (initialsMap[riderId] ?? '?');

          return Marker(
            point: LatLng(pos.lat, pos.lng),
            width: 44,
            height: 44,
            child: _RiderMarker(
              initials: initials,
              isSelf: isSelf,
              heading: pos.heading,
            ),
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();

    return Stack(
      children: [
        // ── Mapa OSM dark ────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.noray4.app',
              tileBuilder: (context, tile, _) => ColorFiltered(
                colorFilter: _darkTileFilter,
                child: tile,
              ),
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // ── GPS off banner ───────────────────────────────────────────────────
        if (!widget.sala.gpsActive)
          Positioned(
            top: 12,
            left: Noray4Spacing.s6,
            right: 80,
            child: _GpsOffBanner(),
          ),

        // ── Controles ────────────────────────────────────────────────────────
        Positioned(
          top: 16,
          right: 16,
          child: _MapControls(
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onCenterMe: _centerOnMe,
            onFitAll: _fitAll,
          ),
        ),

        // ── Panel inferior ───────────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomPanel(
            sala: widget.sala,
            voiceAnim: _voiceAnim,
            onPttPressed: widget.onPttPressed,
            onPttReleased: widget.onPttReleased,
          ),
        ),
      ],
    );
  }
}

// ─── Rider Marker con heading ─────────────────────────────────────────────────

class _RiderMarker extends StatelessWidget {
  final String initials;
  final bool isSelf;
  final double? heading;

  const _RiderMarker({
    required this.initials,
    required this.isSelf,
    this.heading,
  });

  @override
  Widget build(BuildContext context) {
    final marker = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelf
            ? Noray4Colors.darkPrimary
            : Noray4Colors.darkSurfaceContainerHighest,
        border: Border.all(
          color: isSelf
              ? Colors.white
              : Noray4Colors.darkOutlineVariant,
          width: isSelf ? 2 : 0.5,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: Noray4TextStyles.bodySmall.copyWith(
            color: isSelf
                ? const Color(0xFF131312)
                : Noray4Colors.darkPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );

    if (heading != null && heading! >= 0) {
      return Transform.rotate(
        angle: heading! * math.pi / 180,
        child: marker,
      );
    }
    return marker;
  }
}

// ─── GPS off banner ───────────────────────────────────────────────────────────

class _GpsOffBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerLow.withValues(alpha: 0.9),
        borderRadius: Noray4Radius.secondary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.location_off,
              size: 16, color: Noray4Colors.darkOnSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            'GPS no disponible',
            style: Noray4TextStyles.bodySmall.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Controles del mapa ───────────────────────────────────────────────────────

class _MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenterMe;
  final VoidCallback onFitAll;

  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenterMe,
    required this.onFitAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MapBtn(icon: Symbols.add, onTap: onZoomIn),
        const SizedBox(height: 8),
        _MapBtn(icon: Symbols.remove, onTap: onZoomOut),
        const SizedBox(height: 8),
        _MapBtn(icon: Symbols.near_me, onTap: onCenterMe),
        const SizedBox(height: 8),
        _MapBtn(icon: Symbols.fit_screen, onTap: onFitAll),
      ],
    );
  }
}

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xCC2A2A29),
          borderRadius: Noray4Radius.secondary,
          border: Border.all(
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Icon(icon, size: 22, color: Noray4Colors.darkOnSurface),
      ),
    );
  }
}

// ─── Bottom Panel ─────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final SalaState sala;
  final AnimationController voiceAnim;
  final VoidCallback onPttPressed;
  final VoidCallback onPttReleased;

  const _BottomPanel({
    required this.sala,
    required this.voiceAnim,
    required this.onPttPressed,
    required this.onPttReleased,
  });

  @override
  Widget build(BuildContext context) {
    final activeRiders = sala.lastPositions.values
        .where((p) => !p.isStale)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Noray4Spacing.s6, 0, Noray4Spacing.s6, Noray4Spacing.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                  child: _MetricCard(label: 'TIEMPO', value: sala.tiempo)),
              const SizedBox(width: Noray4Spacing.s4),
              Expanded(
                  child: _MetricCard(label: 'DIST.', value: sala.distancia)),
              const SizedBox(width: Noray4Spacing.s4),
              Expanded(
                  child: _MetricCard(
                      label: 'ONLINE',
                      value: '$activeRiders riders')),
            ],
          ),
          const SizedBox(height: Noray4Spacing.s4),
          _RidersRow(sala: sala, voiceAnim: voiceAnim),
          const SizedBox(height: Noray4Spacing.s4),
          _PttButton(
            isActive: sala.isPttActive,
            activeSpeakerName: sala.activeSpeakerName,
            myRiderIsSpeaking: sala.isPttActive,
            onPressed: onPttPressed,
            onReleased: onPttReleased,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Noray4Spacing.s4),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: Noray4Radius.primary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Noray4TextStyles.label.copyWith(
                color: Noray4Colors.darkOnSurfaceVariant,
                fontSize: 9,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: Noray4TextStyles.headlineM.copyWith(
                color: Noray4Colors.darkPrimary,
                fontSize: 18,
              )),
        ],
      ),
    );
  }
}

class _RidersRow extends StatelessWidget {
  final SalaState sala;
  final AnimationController voiceAnim;
  const _RidersRow({required this.sala, required this.voiceAnim});

  @override
  Widget build(BuildContext context) {
    final isSomeoneActive = sala.activeSpeakerId != null;
    return Container(
      padding: const EdgeInsets.all(Noray4Spacing.s4),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: Noray4Radius.primary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Stacked avatars
          SizedBox(
            height: 40,
            child: Stack(
              children: [
                for (int i = 0; i < sala.riders.length.clamp(0, 4); i++)
                  Positioned(
                    left: i * 28.0,
                    child: _Avatar(initials: sala.riders[i].initials),
                  ),
              ],
            ),
          ),
          // Voz status
          Row(
            children: [
              AnimatedBuilder(
                animation: voiceAnim,
                builder: (context, _) => Icon(
                  Symbols.graphic_eq,
                  fill: 1,
                  size: 22,
                  color: Noray4Colors.darkOnSurfaceVariant.withValues(
                    alpha: isSomeoneActive
                        ? 0.4 + voiceAnim.value * 0.6
                        : 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isSomeoneActive
                    ? '${sala.activeSpeakerName ?? "Rider"} habla...'
                    : 'Canal listo',
                style: Noray4TextStyles.body.copyWith(
                  color: Noray4Colors.darkOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(
            color: Noray4Colors.darkSurfaceContainerLow, width: 2),
      ),
      child: Center(
        child: Text(initials,
            style: Noray4TextStyles.bodySmall.copyWith(
              color: Noray4Colors.darkPrimary,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

class _PttButton extends StatelessWidget {
  final bool isActive;
  final bool myRiderIsSpeaking;
  final String? activeSpeakerName;
  final VoidCallback onPressed;
  final VoidCallback onReleased;

  const _PttButton({
    required this.isActive,
    required this.myRiderIsSpeaking,
    this.activeSpeakerName,
    required this.onPressed,
    required this.onReleased,
  });

  @override
  Widget build(BuildContext context) {
    final label = myRiderIsSpeaking
        ? 'Hablando...'
        : (activeSpeakerName != null
            ? '${activeSpeakerName!.split(' ').first} habla'
            : 'Hablar');

    return GestureDetector(
      onTapDown: (_) => onPressed(),
      onTapUp: (_) => onReleased(),
      onTapCancel: onReleased,
      child: AnimatedScale(
        scale: isActive ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Noray4Colors.darkPrimary,
            borderRadius: Noray4Radius.primary,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.mic,
                  fill: isActive ? 1 : 0,
                  size: 24,
                  color: const Color(0xFF1A1C1C)),
              const SizedBox(width: 12),
              Text(label,
                  style: Noray4TextStyles.headlineM.copyWith(
                    color: const Color(0xFF1A1C1C),
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Verification:**
```bash
flutter analyze lib/features/sala/widgets/map_tab.dart
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/sala/widgets/map_tab.dart
git commit -m "feat(sala): replace mock map markers with real GPS positions and heading"
```

---

## Módulo 3 — Chat Tiempo Real

### Task 9: Actualizar VozTab con PTT real

**Layer:** Presentation / Widget

**Files:**
- Modify: `lib/features/sala/widgets/voz_tab.dart`

**Context:** VozTab ya tiene la UI. Solo conectar los callbacks al `SalaNotifier` real y mostrar `activeSpeakerId` desde el state. Los callbacks `onPttPressed/Released` ahora llaman a métodos async del notifier vía `SalaNotifier.setPtt()`.

**Changes — modificar `_VoiceStatusBar` para mostrar hablante real y `_RiderVoiceRow` para usar `activeSpeakerId`:**

En el `build()` de `_VozTabState`, reemplazar la lista de riders con datos reales:

```dart
// En VozTab.build(), reemplazar el itemBuilder del ListView:
itemBuilder: (context, i) {
  final sala = widget.sala;
  if (i == 0) {
    return _RiderVoiceRow(
      initials: 'YO',
      isSpeaking: sala.isPttActive,
      isYou: true,
    );
  }
  final idx = i - 1;
  if (idx < sala.riders.length) {
    final rider = sala.riders[idx];
    final isSpeaking =
        rider.riderId != null &&
        rider.riderId == sala.activeSpeakerId;
    return _RiderVoiceRow(
      initials: rider.initials,
      displayName: rider.displayName ?? rider.initials,
      isSpeaking: isSpeaking,
    );
  }
  return const SizedBox.shrink();
},
// itemCount: sala.riders.length + 1 (quitar el +2 hardcoded)
```

En `_VoiceStatusBar`, agregar nombre del hablante si hay uno activo:
```dart
// En el Row de _VoiceStatusBar, reemplazar el Text:
Text(
  sala.activeSpeakerName != null
      ? '${sala.activeSpeakerName} habla...'
      : (isActive ? 'Canal de voz activo' : 'Canal listo'),
  style: Noray4TextStyles.body.copyWith(
    color: Noray4Colors.darkOnSurfaceVariant,
  ),
),
```

**Agregar `displayName` a `_RiderVoiceRow`:**
```dart
class _RiderVoiceRow extends StatelessWidget {
  final String initials;
  final String? displayName;  // nuevo
  final bool isSpeaking;
  final bool isYou;
  const _RiderVoiceRow({
    required this.initials,
    this.displayName,
    required this.isSpeaking,
    this.isYou = false,
  });
  // En el Text del nombre:
  child: Text(
    isYou ? 'Tú' : (displayName ?? initials),
    ...
  ),
```

**Verification:**
```bash
flutter analyze lib/features/sala/widgets/voz_tab.dart
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/sala/widgets/voz_tab.dart
git commit -m "feat(sala): connect VozTab to real PTT state from WebSocket"
```

---

## Verificación Final

### Task 10: Verificación completa del módulo

**Layer:** Integration

**Files:** Ninguno nuevo — solo verificar.

**Verification:**
```bash
# 1. Análisis estático completo
flutter analyze
# Expected: No issues found!

# 2. Tests
flutter test
# Expected: All tests passed!

# 3. Build check
flutter build apk --debug
# Expected: Built build/app/outputs/flutter-apk/app-debug.apk
```

**Checklist funcional (requiere servidor activo):**
```
□ Al entrar a sala: WebSocket se conecta (log en console: WsStatus.connected)
□ Al mover el dispositivo: markers se actualizan en mapa
□ Al enviar mensaje: aparece en otro dispositivo sin refresh
□ Al presionar PTT: otro rider ve "X habla..." en VozTab y MapTab
□ Al soltar PTT: estado vuelve a "Canal listo"
□ PTT auto-release: si se mantiene >30s, se libera automáticamente
□ GPS off: banner "GPS no disponible" aparece en mapa
□ Botón "centrar en mí": cámara va a posición propia
□ Botón "ver todos": cámara hace fit de todos los markers
```

**Commit:**
```bash
git add .
git commit -m "feat(sala): sala activa con mapa real, chat WebSocket y PTT — Sprint 1 completo"
```

---

## Resumen de archivos

### Nuevos
| Archivo | Propósito |
|---|---|
| `lib/features/sala/models/ws_events.dart` | Eventos tipados del WebSocket |
| `lib/features/sala/services/websocket_manager.dart` | Conexión WS con backoff |
| `lib/features/sala/services/location_service.dart` | GPS + POST /update + last_positions |
| `lib/features/sala/services/voice_service.dart` | PTT signaling + 30s timer |

### Modificados
| Archivo | Cambio |
|---|---|
| `pubspec.yaml` | + web_socket_channel, + geolocator |
| `lib/features/sala/models/sala_models.dart` | + RiderPosition + campos RT en SalaState |
| `lib/features/sala/providers/sala_provider.dart` | Integración completa de 3 servicios |
| `lib/features/sala/widgets/map_tab.dart` | Markers reales, heading, botones cámara |
| `lib/features/sala/widgets/voz_tab.dart` | PTT visual desde WebSocket state |

### No tocados (intencional)
| Archivo | Razón |
|---|---|
| `sala_screen.dart` | Interfaz pública de SalaNotifier no cambió |
| `chat_service.dart` | Ya implementado, solo se usa desde SalaNotifier |
| `salas_service.dart` | No requiere cambios |

---

## Sprint 2 (fuera de alcance ahora)

- Audio WebRTC real: `flutter_webrtc` + `record` package
- POIs del backend en mapa: `GET /api/v1/location/pois`
- Compartir coordenada desde mapa al chat (mensaje tipo `coords`)
- Upload de imagen desde chat
- Modo background GPS: `geolocator` background service
