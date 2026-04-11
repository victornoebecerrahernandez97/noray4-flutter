import 'package:noray4/features/amarres/services/amarres_service.dart';
import 'package:noray4/features/home/models/home_models.dart';
import 'package:noray4/features/sala/services/salas_service.dart';

class HomeService {
  final _salas = SalasService();
  final _amarres = AmarresService();

  Future<HomeData> load() async {
    final results = await Future.wait([
      _salas.listSalas(limit: 10),
      _amarres.getFeed(limit: 5),
    ]);

    final salas = results[0] as List<SalaOut>;
    final feedRaw = results[1] as List<Map<String, dynamic>>;

    // norayActivo — primera sala activa
    final salaActiva = salas.isNotEmpty ? salas.first : null;
    final norayActivo = salaActiva != null
        ? NorayActivo(
            id: salaActiva.id,
            nombre: salaActiva.name,
            km: 0, // km real desde ms_location en Sprint 2
            tiempo: _calcTiempo(salaActiva.createdAt),
          )
        : null;

    // salas restantes → próximas salidas en el dashboard
    final proximasSalas =
        salaActiva != null ? salas.skip(1).toList() : salas;
    final proximosAmarres = proximasSalas.map((s) {
      final fecha = DateTime.tryParse(s.createdAt) ?? DateTime.now();
      const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return ProximoAmarre(
        id: s.id,
        nombre: s.name,
        dia: fecha.day,
        diaSemana: dias[fecha.weekday - 1],
        puntoReunion: s.description ?? 'Ver detalles en la sala',
      );
    }).toList();

    // feed de amarres públicos → rutas de comunidad
    final rutas = feedRaw.map((json) {
      final hace = _calcHace(json['created_at'] as String? ?? '');
      final ridersDisplay = (json['riders_display'] as List?) ?? [];
      String autor = '@rider';
      if (ridersDisplay.isNotEmpty) {
        final first = ridersDisplay.first as Map<String, dynamic>;
        final name = first['display_name'] as String? ?? '';
        if (name.isNotEmpty) {
          autor = '@${name.toLowerCase().replaceAll(' ', '_')}';
        }
      }
      return RutaComunidad(
        id: json['_id'] as String,
        nombre: json['title'] as String,
        autor: autor,
        km: ((json['km_total'] as num?) ?? 0).round(),
        hace: hace,
      );
    }).toList();

    return HomeData(
      norayActivo: norayActivo,
      proximosAmarres: proximosAmarres,
      rutas: rutas,
    );
  }

  String _calcTiempo(String createdAtIso) {
    try {
      final start = DateTime.parse(createdAtIso);
      final diff = DateTime.now().difference(start);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}h';
    } catch (_) {
      return '00:00h';
    }
  }

  String _calcHace(String createdAtIso) {
    try {
      final dt = DateTime.parse(createdAtIso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'hace ${diff.inHours}h';
      if (diff.inDays == 1) return 'ayer';
      return 'hace ${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}

class HomeData {
  final NorayActivo? norayActivo;
  final List<ProximoAmarre> proximosAmarres;
  final List<RutaComunidad> rutas;

  const HomeData({
    this.norayActivo,
    this.proximosAmarres = const [],
    this.rutas = const [],
  });
}
