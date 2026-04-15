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

// ─── Evento genérico ──────────────────────────────────────────────────────────

class GenericEvent extends WsEvent {
  final String topic;
  final Map<String, dynamic> payload;
  GenericEvent(this.topic, this.payload);
}

// ─── Parser de envelope ───────────────────────────────────────────────────────

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
