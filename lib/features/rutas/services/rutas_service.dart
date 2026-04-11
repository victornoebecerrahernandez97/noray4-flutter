import 'package:noray4/features/amarres/services/amarres_service.dart';
import 'package:noray4/features/rutas/models/rutas_models.dart';

class RutasService {
  final _amarresService = AmarresService();

  Future<List<Ruta>> getFeed({int skip = 0, int limit = 20}) async {
    final raw = await _amarresService.getFeed(skip: skip, limit: limit);
    return raw.map(Ruta.fromJson).toList();
  }
}
