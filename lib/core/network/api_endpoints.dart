abstract final class ApiEndpoints {
  // ── Auth ─────────────────────────────────────────────────────────────────
  static const register = '/api/v1/auth/register';
  static const login = '/api/v1/auth/login';
  static const logout = '/api/v1/auth/logout';
  static const me = '/api/v1/auth/me';
  static const guestToken = '/api/v1/auth/guest-token';

  // ── Riders ───────────────────────────────────────────────────────────────
  static const riderMe = '/api/v1/riders/me';
  static const riderMoto = '/api/v1/riders/me/moto';
  static String rider(String id) => '/api/v1/riders/$id';
  static String riderStats(String id) => '/api/v1/riders/$id/stats';
  static String riderFollow(String id) => '/api/v1/riders/$id/follow';

  // ── Salas ────────────────────────────────────────────────────────────────
  static const salas = '/api/v1/salas';
  static String sala(String id) => '/api/v1/salas/$id';
  static String salaJoin(String id) => '/api/v1/salas/$id/join';
  static String salaClose(String id) => '/api/v1/salas/$id/close';
  static String salaQr(String id) => '/api/v1/salas/$id/qr';
  static String salaMiembros(String id) => '/api/v1/salas/$id/miembros';

  // ── Chat ─────────────────────────────────────────────────────────────────
  static String chatMensajes(String salaId) =>
      '/api/v1/chat/$salaId/mensajes';
  static String chatMensaje(String salaId, String msgId) =>
      '/api/v1/chat/$salaId/mensajes/$msgId';
  static String chatMensajeAck(String salaId, String msgId) =>
      '/api/v1/chat/$salaId/mensajes/$msgId/ack';
  static String chatUpload(String salaId) => '/api/v1/chat/$salaId/upload';

  // ── Realtime ─────────────────────────────────────────────────────────────
  static String realtimeUbicacion(String salaId) =>
      '/api/v1/realtime/$salaId/ubicacion';
  static String realtimeEvento(String salaId) =>
      '/api/v1/realtime/$salaId/evento';
  static String realtimeStatus(String salaId) =>
      '/api/v1/realtime/$salaId/status';

  // ── Location ─────────────────────────────────────────────────────────────
  static const pois = '/api/v1/location/pois';
  static String poi(String id) => '/api/v1/location/pois/$id';
  static String poiLike(String id) => '/api/v1/location/pois/$id/like';
  static String locationUpdate(String salaId) =>
      '/api/v1/location/salas/$salaId/update';
  static String locationTracks(String salaId) =>
      '/api/v1/location/salas/$salaId/tracks';
  static String locationExport(String salaId) =>
      '/api/v1/location/salas/$salaId/export';

  // ── Voice ────────────────────────────────────────────────────────────────
  static String voiceCanales(String salaId) =>
      '/api/v1/voice/$salaId/canales';
  static String voicePtt(String salaId) => '/api/v1/voice/$salaId/ptt';
  static String voiceStatus(String salaId) => '/api/v1/voice/$salaId/status';
  static String voiceSignal(String salaId) => '/api/v1/voice/$salaId/signal';

  // ── Amarres ──────────────────────────────────────────────────────────────
  static const amarres = '/api/v1/amarres';
  static const amaresMios = '/api/v1/amarres/me';
  static const amaresFeed = '/api/v1/amarres/feed';
  static String amarre(String id) => '/api/v1/amarres/$id';
  static String amarresSala(String salaId) => '/api/v1/amarres/sala/$salaId';
  static String amarreFotos(String id) => '/api/v1/amarres/$id/fotos';
  static String amarreFoto(String id, String publicId) =>
      '/api/v1/amarres/$id/fotos/$publicId';
  static String amarreLike(String id) => '/api/v1/amarres/$id/like';
  static String amarreClone(String id) => '/api/v1/amarres/$id/clone';

  // ── Groups ───────────────────────────────────────────────────────────────
  static const groups = '/api/v1/groups';
  static const groupsSearch = '/api/v1/groups/search';
  static const groupsMe = '/api/v1/groups/me';
  static String group(String id) => '/api/v1/groups/$id';
  static String groupJoin(String id) => '/api/v1/groups/$id/join';
  static String groupLeave(String id) => '/api/v1/groups/$id/leave';
  static String groupMembers(String id) => '/api/v1/groups/$id/members';
  static String groupMemberRole(String id, String riderId) =>
      '/api/v1/groups/$id/members/$riderId/role';
  static String groupKick(String id, String riderId) =>
      '/api/v1/groups/$id/members/$riderId';
}
