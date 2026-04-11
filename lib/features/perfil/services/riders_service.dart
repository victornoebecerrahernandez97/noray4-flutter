import 'package:noray4/core/network/api_client.dart';
import 'package:noray4/core/network/api_endpoints.dart';

class RiderOut {
  final String id;
  final String userId;
  final String displayName;
  final String? city;
  final String? bio;
  final String? vehicleType;
  final String? vehicleModel;
  final int? vehicleYear;
  final int? vehicleKm;
  final String? avatarUrl;
  final List<String> followers;
  final List<String> following;

  const RiderOut({
    required this.id,
    required this.userId,
    required this.displayName,
    this.city,
    this.bio,
    this.vehicleType,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleKm,
    this.avatarUrl,
    this.followers = const [],
    this.following = const [],
  });

  factory RiderOut.fromJson(Map<String, dynamic> json) => RiderOut(
        id: json['_id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        city: json['city'] as String?,
        bio: json['bio'] as String?,
        vehicleType: json['vehicle_type'] as String?,
        vehicleModel: json['vehicle_model'] as String?,
        vehicleYear: json['vehicle_year'] as int?,
        vehicleKm: json['vehicle_km'] as int?,
        avatarUrl: json['avatar_url'] as String?,
        followers: (json['followers'] as List?)?.cast<String>() ?? [],
        following: (json['following'] as List?)?.cast<String>() ?? [],
      );

  bool get hasMoto => vehicleModel != null;
}

class RiderStats {
  final int amarres;
  final int kmTotales;
  final int grupos;

  const RiderStats(
      {required this.amarres,
      required this.kmTotales,
      required this.grupos});

  factory RiderStats.fromJson(Map<String, dynamic> json) => RiderStats(
        amarres: json['amarres'] as int? ?? 0,
        kmTotales: json['km_totales'] as int? ?? 0,
        grupos: json['grupos'] as int? ?? 0,
      );
}

class RidersService {
  final _dio = ApiClient.instance.dio;

  /// Obtiene el perfil completo del rider autenticado.
  Future<RiderOut> getMyRider() async {
    final res = await _dio.get(ApiEndpoints.riderMe);
    return RiderOut.fromJson(res.data as Map<String, dynamic>);
  }

  /// Actualiza campos del perfil (todos opcionales).
  Future<RiderOut> updateRider({
    String? displayName,
    String? city,
    String? bio,
    String? avatarUrl,
  }) async {
    final res = await _dio.put(ApiEndpoints.riderMe, data: {
      'display_name': ?displayName,
      'city': ?city,
      'bio': ?bio,
      'avatar_url': ?avatarUrl,
    });
    return RiderOut.fromJson(res.data as Map<String, dynamic>);
  }

  /// Registra o actualiza la moto del rider.
  Future<RiderOut> updateMoto({
    required String modelo,
    required int anio,
    required int km,
  }) async {
    final res = await _dio.post(ApiEndpoints.riderMoto, data: {
      'modelo': modelo,
      'año': anio,
      'km': km,
    });
    return RiderOut.fromJson(res.data as Map<String, dynamic>);
  }

  /// Perfil público de cualquier rider por ID.
  Future<RiderOut> getRider(String riderId) async {
    final res = await _dio.get(ApiEndpoints.rider(riderId));
    return RiderOut.fromJson(res.data as Map<String, dynamic>);
  }

  /// Estadísticas del rider (amarres, km, grupos).
  Future<RiderStats> getStats(String riderId) async {
    final res = await _dio.get(ApiEndpoints.riderStats(riderId));
    return RiderStats.fromJson(res.data as Map<String, dynamic>);
  }

  /// Seguir a un rider.
  Future<RiderOut> follow(String riderId) async {
    final res = await _dio.post(ApiEndpoints.riderFollow(riderId));
    return RiderOut.fromJson(res.data as Map<String, dynamic>);
  }

  /// Dejar de seguir a un rider.
  Future<RiderOut> unfollow(String riderId) async {
    final res = await _dio.delete(ApiEndpoints.riderFollow(riderId));
    return RiderOut.fromJson(res.data as Map<String, dynamic>);
  }
}
