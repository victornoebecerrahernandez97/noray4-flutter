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
        break;

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
