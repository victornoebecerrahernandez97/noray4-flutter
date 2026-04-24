enum SalaTab { mapa, chat, voz, archivos }

// ─── SalaFoto ─────────────────────────────────────────────────────────────────

class SalaFoto {
  final String url;
  final String thumbUrl;
  final String publicId;
  final String riderId;
  final String? caption;
  final String takenAt;

  const SalaFoto({
    required this.url,
    required this.thumbUrl,
    required this.publicId,
    required this.riderId,
    this.caption,
    required this.takenAt,
  });

  factory SalaFoto.fromJson(Map<String, dynamic> json) => SalaFoto(
        url: json['url'] as String,
        thumbUrl: json['thumb_url'] as String,
        publicId: json['public_id'] as String,
        riderId: json['rider_id'] as String,
        caption: json['caption'] as String?,
        takenAt: json['taken_at'] as String,
      );
}

// ─── SalaMessage ──────────────────────────────────────────────────────────────

class SalaMessage {
  final String id;
  final String sender;
  final String riderId;
  final String text;
  final String time;
  final bool isOutgoing;
  final String type; // text | image
  final String? mediaUrl;
  final String? mediaThumbUrl;
  final bool edited;
  final bool deleted;

  const SalaMessage({
    required this.id,
    required this.sender,
    required this.riderId,
    required this.text,
    required this.time,
    required this.isOutgoing,
    this.type = 'text',
    this.mediaUrl,
    this.mediaThumbUrl,
    this.edited = false,
    this.deleted = false,
  });

  factory SalaMessage.fromApi(Map<String, dynamic> json, String myRiderId) {
    final riderId = json['rider_id'] as String;
    final createdAt = DateTime.parse(json['created_at'] as String);
    final time =
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    return SalaMessage(
      id: json['_id'] as String,
      sender: (json['display_name'] as String? ?? '').toUpperCase(),
      riderId: riderId,
      text: json['content'] as String? ?? '',
      time: time,
      isOutgoing: riderId == myRiderId,
      type: json['type'] as String? ?? 'text',
      mediaUrl: json['media_url'] as String?,
      mediaThumbUrl: json['media_thumb_url'] as String?,
      edited: json['edited'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  SalaMessage copyWith({String? text, bool? edited, bool? deleted}) =>
      SalaMessage(
        id: id,
        sender: sender,
        riderId: riderId,
        text: text ?? this.text,
        time: time,
        isOutgoing: isOutgoing,
        type: type,
        mediaUrl: mediaUrl,
        mediaThumbUrl: mediaThumbUrl,
        edited: edited ?? this.edited,
        deleted: deleted ?? this.deleted,
      );
}

// ─── SalaRider ────────────────────────────────────────────────────────────────

class SalaRider {
  final String initials;
  final String? riderId;
  final String? displayName;
  final String role;

  const SalaRider(
    this.initials, {
    this.riderId,
    this.displayName,
    this.role = 'rider',
  });

  factory SalaRider.fromMiembro(Map<String, dynamic> json) {
    final name = json['display_name'] as String? ?? '';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';
    return SalaRider(
      initials,
      riderId: json['rider_id'] as String?,
      displayName: name,
      role: json['role'] as String? ?? 'rider',
    );
  }
}

// ─── RiderPosition ────────────────────────────────────────────────────────────

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

// ─── SalaState ────────────────────────────────────────────────────────────────

class SalaState {
  final String salaId;
  final String nombre;
  final String ownerId;
  final SalaTab activeTab;
  final List<SalaMessage> messages;
  final List<SalaRider> riders;
  final List<SalaFoto> fotos;
  final String tiempo;
  final String distancia;
  final bool isPttActive;
  final bool isVoiceActive;
  final bool isLoading;
  final String? error;
  final Map<String, RiderPosition> lastPositions;
  final String? activeSpeakerId;
  final String? activeSpeakerName;
  final bool wsConnected;
  final bool gpsActive;
  final Set<String> onlineRiderIds;

  const SalaState({
    required this.salaId,
    this.nombre = '',
    this.ownerId = '',
    this.activeTab = SalaTab.mapa,
    this.messages = const [],
    this.riders = const [],
    this.fotos = const [],
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
    this.onlineRiderIds = const {},
  });

  SalaState copyWith({
    String? nombre,
    String? ownerId,
    SalaTab? activeTab,
    List<SalaMessage>? messages,
    List<SalaRider>? riders,
    List<SalaFoto>? fotos,
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
    Set<String>? onlineRiderIds,
  }) =>
      SalaState(
        salaId: salaId,
        nombre: nombre ?? this.nombre,
        ownerId: ownerId ?? this.ownerId,
        activeTab: activeTab ?? this.activeTab,
        messages: messages ?? this.messages,
        riders: riders ?? this.riders,
        fotos: fotos ?? this.fotos,
        tiempo: tiempo ?? this.tiempo,
        distancia: distancia ?? this.distancia,
        isPttActive: isPttActive ?? this.isPttActive,
        isVoiceActive: isVoiceActive ?? this.isVoiceActive,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        lastPositions: lastPositions ?? this.lastPositions,
        activeSpeakerId:
            clearActiveSpeaker ? null : (activeSpeakerId ?? this.activeSpeakerId),
        activeSpeakerName: clearActiveSpeaker
            ? null
            : (activeSpeakerName ?? this.activeSpeakerName),
        wsConnected: wsConnected ?? this.wsConnected,
        gpsActive: gpsActive ?? this.gpsActive,
        onlineRiderIds: onlineRiderIds ?? this.onlineRiderIds,
      );
}
