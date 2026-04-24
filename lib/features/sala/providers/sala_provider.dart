import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/features/amarres/models/amarres_models.dart';
import 'package:noray4/features/sala/models/sala_models.dart';
import 'package:noray4/features/sala/models/ws_events.dart';
import 'package:noray4/features/sala/services/audio_service.dart';
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
  late final AudioService _audio;

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
    _audio = AudioService();
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
          .where((m) => !m.deleted)
          .map((m) => SalaMessage.fromApi({
                '_id': m.id,
                'rider_id': m.riderId,
                'display_name': m.displayName,
                'content': m.content,
                'created_at': m.createdAt,
                'type': m.type,
                'media_url': m.mediaUrl,
                'media_thumb_url': m.mediaThumbUrl,
                'edited': m.edited,
                'deleted': m.deleted,
              }, _myRiderId))
          .toList();

      // Todos los miembros empiezan como online (se ajusta por presencia WS)
      final onlineRiderIds =
          sala.miembros.map((m) => m.riderId).toSet();

      state = state.copyWith(
        nombre: sala.name,
        ownerId: sala.ownerId,
        riders: riders,
        messages: messages,
        fotos: sala.fotos,
        tiempo: _calcTiempo(sala.createdAt),
        onlineRiderIds: onlineRiderIds,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }

    _connectWebSocket();
    _location.start();
    _audio.init().ignore();
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
        final exists = state.messages.any((m) => m.id == msg.id);
        if (!exists) {
          final newMessage = SalaMessage.fromApi({
            '_id': msg.id,
            'rider_id': msg.riderId,
            'display_name': msg.displayName,
            'content': msg.content,
            'created_at': msg.createdAt,
            'type': msg.type,
            'media_url': msg.mediaUrl,
            'media_thumb_url': msg.mediaThumbUrl,
            'edited': msg.edited,
            'deleted': msg.deleted,
          }, _myRiderId);
          state = state.copyWith(
              messages: [...state.messages, newMessage]);
        }
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
        final updated = Set<String>.from(state.onlineRiderIds);
        if (event.status == 'online') {
          updated.add(event.riderId);
        } else {
          updated.remove(event.riderId);
        }
        state = state.copyWith(onlineRiderIds: updated);

      case AudioEvent():
        if (event.riderId != _myRiderId && event.data.isNotEmpty) {
          _audio.feedFrame(base64Decode(event.data));
        }

      case GenericEvent():
        break;
    }
  }

  // ── Location ──────────────────────────────────────────────────────────────

  void _handlePositions(Map<String, RiderPosition> positions) {
    final merged = Map<String, RiderPosition>.from(state.lastPositions);
    positions.forEach((riderId, pos) {
      final existing = merged[riderId];
      if (existing == null || pos.updatedAt.isAfter(existing.updatedAt)) {
        merged[riderId] = pos;
      }
    });
    state = state.copyWith(lastPositions: merged);
  }

  // ── PTT ───────────────────────────────────────────────────────────────────

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

  // ── Acciones públicas ─────────────────────────────────────────────────────

  Future<void> refresh() => _init();

  void switchTab(SalaTab tab) => state = state.copyWith(activeTab: tab);

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 4000) return;
    final optimistic = SalaMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'Tú',
      riderId: _myRiderId,
      text: trimmed,
      time: _formatTime(DateTime.now()),
      isOutgoing: true,
    );
    state = state.copyWith(messages: [...state.messages, optimistic]);
    try {
      await _chatService.sendText(_salaId, trimmed);
    } catch (_) {
      // Mensaje optimista permanece visible
    }
  }

  Future<void> sendImage(String filePath) async {
    try {
      final media = await _chatService.uploadMedia(_salaId, filePath);
      final mediaUrl = media['media_url']!;
      final thumbUrl = media['thumb_url']!;
      final optimistic = SalaMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'Tú',
        riderId: _myRiderId,
        text: '',
        time: _formatTime(DateTime.now()),
        isOutgoing: true,
        type: 'image',
        mediaUrl: mediaUrl,
        mediaThumbUrl: thumbUrl,
      );
      state = state.copyWith(messages: [...state.messages, optimistic]);
      await _chatService.sendImageMessage(_salaId, mediaUrl, thumbUrl);
    } catch (_) {}
  }

  Future<void> deleteMessage(String msgId) async {
    // Soft-delete local inmediato
    final updated = state.messages
        .where((m) => m.id != msgId)
        .toList();
    state = state.copyWith(messages: updated);
    try {
      await _chatService.deleteMensaje(_salaId, msgId);
    } catch (_) {}
  }

  Future<void> editMessage(String msgId, String newContent) async {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty || trimmed.length > 4000) return;
    final updated = state.messages.map((m) {
      if (m.id == msgId) return m.copyWith(text: trimmed, edited: true);
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
    try {
      await _chatService.editMensaje(_salaId, msgId, trimmed);
    } catch (_) {}
  }

  Future<void> uploadSalaFoto(String filePath) async {
    try {
      final sala = await _salasService.uploadSalaFoto(_salaId, filePath);
      state = state.copyWith(fotos: sala.fotos);
    } catch (_) {}
  }

  /// Cierra la sala en backend y retorna el Amarre creado.
  Future<Amarre?> closeSalaAndGetAmarre() async {
    try {
      final data = await _salasService.closeSala(_salaId);
      final amarreJson = data['amarre'] as Map<String, dynamic>?;
      if (amarreJson != null) {
        return Amarre.fromJson(amarreJson);
      }
    } catch (_) {}
    return null;
  }

  Future<void> startPtt() => _voice.startPtt();
  Future<void> stopPtt() => _voice.stopPtt();

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
    _audio.dispose().ignore();
    super.dispose();
  }
}

final salaProvider =
    StateNotifierProvider.family<SalaNotifier, SalaState, String>(
  (ref, salaId) {
    final myRiderId = ref.watch(authProvider).user?.riderId ?? '';
    return SalaNotifier(salaId, myRiderId);
  },
);
