import 'package:dio/dio.dart';
import 'package:noray4/core/network/api_client.dart';
import 'package:noray4/core/network/api_endpoints.dart';

class MensajeOut {
  final String id;
  final String salaId;
  final String riderId;
  final String displayName;
  final String type; // text | image | coords | file | system
  final String? content;
  final String? mediaUrl;
  final String? mediaThumbUrl;
  final bool edited;
  final bool deleted;
  final String createdAt;

  const MensajeOut({
    required this.id,
    required this.salaId,
    required this.riderId,
    required this.displayName,
    required this.type,
    this.content,
    this.mediaUrl,
    this.mediaThumbUrl,
    this.edited = false,
    this.deleted = false,
    required this.createdAt,
  });

  factory MensajeOut.fromJson(Map<String, dynamic> json) => MensajeOut(
        id: json['_id'] as String,
        salaId: json['sala_id'] as String,
        riderId: json['rider_id'] as String,
        displayName: json['display_name'] as String,
        type: json['type'] as String,
        content: json['content'] as String?,
        mediaUrl: json['media_url'] as String?,
        mediaThumbUrl: json['media_thumb_url'] as String?,
        edited: json['edited'] as bool? ?? false,
        deleted: json['deleted'] as bool? ?? false,
        createdAt: json['created_at'] as String,
      );
}

class PaginatedMensajes {
  final List<MensajeOut> items;
  final int total;
  final bool hasMore;

  const PaginatedMensajes({
    required this.items,
    required this.total,
    required this.hasMore,
  });

  factory PaginatedMensajes.fromJson(Map<String, dynamic> json) =>
      PaginatedMensajes(
        items: (json['items'] as List)
            .map((e) => MensajeOut.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        hasMore: json['has_more'] as bool,
      );
}

class ChatService {
  final _dio = ApiClient.instance.dio;

  /// Mensajes paginados de la sala en orden cronológico.
  Future<PaginatedMensajes> getMensajes(
    String salaId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final res = await _dio.get(
      ApiEndpoints.chatMensajes(salaId),
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return PaginatedMensajes.fromJson(res.data as Map<String, dynamic>);
  }

  /// Envía un mensaje de texto.
  Future<MensajeOut> sendText(String salaId, String content,
      {String? replyTo}) async {
    final res = await _dio.post(
      ApiEndpoints.chatMensajes(salaId),
      data: {
        'type': 'text',
        'content': content,
        'reply_to': ?replyTo,
      },
    );
    return MensajeOut.fromJson(res.data as Map<String, dynamic>);
  }

  /// Edita el contenido de un mensaje propio (solo type=text).
  Future<MensajeOut> editMensaje(
      String salaId, String msgId, String content) async {
    final res = await _dio.put(
      ApiEndpoints.chatMensaje(salaId, msgId),
      data: {'content': content},
    );
    return MensajeOut.fromJson(res.data as Map<String, dynamic>);
  }

  /// Soft-delete de un mensaje.
  Future<void> deleteMensaje(String salaId, String msgId) async {
    await _dio.delete(ApiEndpoints.chatMensaje(salaId, msgId));
  }

  /// Confirma la entrega del mensaje (idempotente).
  Future<void> ackMensaje(String salaId, String msgId) async {
    await _dio.post(ApiEndpoints.chatMensajeAck(salaId, msgId));
  }

  /// Sube una imagen. Retorna {media_url, thumb_url, public_id}.
  Future<Map<String, String>> uploadMedia(
      String salaId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post(
      ApiEndpoints.chatUpload(salaId),
      data: formData,
    );
    return {
      'media_url': res.data['media_url'] as String,
      'thumb_url': res.data['thumb_url'] as String,
      'public_id': res.data['public_id'] as String,
    };
  }
}
