import 'package:noray4/core/network/api_client.dart';
import 'package:noray4/core/network/api_endpoints.dart';
import 'package:noray4/features/amarres/models/amarres_models.dart';

class AmarresService {
  final _dio = ApiClient.instance.dio;

  /// Mis amarres paginados desde la API.
  Future<List<Amarre>> getMyAmarres({int skip = 0, int limit = 20}) async {
    final res = await _dio.get(
      ApiEndpoints.amaresMios,
      queryParameters: {'skip': skip, 'limit': limit},
    );
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? [];
    return items
        .map((e) => Amarre.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Feed público de amarres (para la pantalla Rutas).
  /// Soporta respuesta lista directa o paginada.
  Future<List<Map<String, dynamic>>> getFeed({
    int skip = 0,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      ApiEndpoints.amaresFeed,
      queryParameters: {'skip': skip, 'limit': limit},
    );
    final raw = res.data;
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    final data = raw as Map<String, dynamic>;
    return ((data['items'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  /// Detalle completo de un amarre por ID.
  Future<Amarre> getAmarre(String id) async {
    final res = await _dio.get(ApiEndpoints.amarre(id));
    return Amarre.fromJson(res.data as Map<String, dynamic>);
  }
}
