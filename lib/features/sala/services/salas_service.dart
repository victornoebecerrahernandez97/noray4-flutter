import 'package:dio/dio.dart';
import 'package:noray4/core/network/api_client.dart';
import 'package:noray4/core/network/api_endpoints.dart';
import 'package:noray4/features/sala/models/sala_models.dart';

class MiembroOut {
  final String riderId;
  final String displayName;
  final String role; // admin | rider | guest
  final String joinedAt;

  const MiembroOut({
    required this.riderId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  factory MiembroOut.fromJson(Map<String, dynamic> json) => MiembroOut(
        riderId: json['rider_id'] as String,
        displayName: json['display_name'] as String,
        role: json['role'] as String,
        joinedAt: json['joined_at'] as String,
      );
}

class SalaOut {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String status; // active | closed
  final bool isPrivate;
  final List<MiembroOut> miembros;
  final List<SalaFoto> fotos;
  final String? qrToken;
  final String? inviteLink;
  final String createdAt;
  final String? closedAt;

  const SalaOut({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.status,
    required this.isPrivate,
    this.miembros = const [],
    this.fotos = const [],
    this.qrToken,
    this.inviteLink,
    required this.createdAt,
    this.closedAt,
  });

  factory SalaOut.fromJson(Map<String, dynamic> json) => SalaOut(
        id: json['_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        ownerId: json['owner_id'] as String,
        status: json['status'] as String,
        isPrivate: json['is_private'] as bool,
        miembros: (json['miembros'] as List?)
                ?.map((e) => MiembroOut.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        fotos: (json['fotos'] as List?)
                ?.map((e) => SalaFoto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        qrToken: json['qr_token'] as String?,
        inviteLink: json['invite_link'] as String?,
        createdAt: json['created_at'] as String,
        closedAt: json['closed_at'] as String?,
      );

  bool get isActive => status == 'active';
}

class SalasService {
  final _dio = ApiClient.instance.dio;

  Future<List<SalaOut>> listSalas({int skip = 0, int limit = 20}) async {
    final res = await _dio.get(
      ApiEndpoints.salas,
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return (res.data as List)
        .map((e) => SalaOut.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SalaOut> createSala({
    required String name,
    String? description,
    bool isPrivate = false,
  }) async {
    final res = await _dio.post(ApiEndpoints.salas, data: {
      'name': name,
      'description': ?description,
      'is_private': isPrivate,
    });
    return SalaOut.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SalaOut> getSala(String salaId) async {
    final res = await _dio.get(ApiEndpoints.sala(salaId));
    return SalaOut.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SalaOut> updateSala(
    String salaId, {
    String? name,
    String? description,
    bool? isPrivate,
  }) async {
    final res = await _dio.put(ApiEndpoints.sala(salaId), data: {
      'name': ?name,
      'description': ?description,
      'is_private': ?isPrivate,
    });
    return SalaOut.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SalaOut> joinSala(String salaId, {String? qrToken}) async {
    final res = await _dio.post(
      ApiEndpoints.salaJoin(salaId),
      data: qrToken != null ? {'qr_token': qrToken} : null,
    );
    return SalaOut.fromJson(res.data as Map<String, dynamic>);
  }

  /// Cierra la sala. Solo el admin puede.
  /// Retorna {sala: SalaOut, amarre: Map} del servidor.
  Future<Map<String, dynamic>> closeSala(String salaId) async {
    final res = await _dio.post(ApiEndpoints.salaClose(salaId));
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, String>> getSalaQr(String salaId) async {
    final res = await _dio.get(ApiEndpoints.salaQr(salaId));
    return {
      'qr_token': res.data['qr_token'] as String,
      'invite_link': res.data['invite_link'] as String,
    };
  }

  Future<List<MiembroOut>> getMiembros(String salaId) async {
    final res = await _dio.get(ApiEndpoints.salaMiembros(salaId));
    return (res.data as List)
        .map((e) => MiembroOut.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Sube una foto a la sala (evidencia). Retorna la sala actualizada con fotos.
  Future<SalaOut> uploadSalaFoto(
    String salaId,
    String filePath, {
    String? caption,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    });
    final res = await _dio.post(
      ApiEndpoints.salaFotos(salaId),
      data: formData,
    );
    return SalaOut.fromJson(res.data as Map<String, dynamic>);
  }
}
