enum RutaFiltro { todas, cercanas, populares, recientes }

enum RutaDificultad { facil, moderada, exigente }

class Ruta {
  final String id;
  final String nombre;
  final String autor;
  final int km;
  final String duracion;
  final String zona;
  final RutaDificultad dificultad;
  final int participantes;
  final bool isFavorita;

  const Ruta({
    required this.id,
    required this.nombre,
    required this.autor,
    required this.km,
    required this.duracion,
    required this.zona,
    required this.dificultad,
    this.participantes = 0,
    this.isFavorita = false,
  });

  factory Ruta.fromJson(Map<String, dynamic> json) {
    final kmTotal = ((json['km_total'] as num?) ?? 0).round();
    final durMin = json['duracion_min'] as int? ?? 0;
    final h = durMin ~/ 60;
    final m = durMin % 60;
    final durStr = h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';

    final tags = (json['tags'] as List?)?.cast<String>() ?? [];
    final ridersDisplay = (json['riders_display'] as List?) ?? [];

    final RutaDificultad dificultad;
    if (kmTotal < 100) {
      dificultad = RutaDificultad.facil;
    } else if (kmTotal < 300) {
      dificultad = RutaDificultad.moderada;
    } else {
      dificultad = RutaDificultad.exigente;
    }

    String autor = '@rider';
    if (ridersDisplay.isNotEmpty) {
      final first = ridersDisplay.first as Map<String, dynamic>;
      final name = first['display_name'] as String? ?? '';
      if (name.isNotEmpty) {
        autor = '@${name.toLowerCase().replaceAll(' ', '_')}';
      }
    }

    return Ruta(
      id: json['_id'] as String,
      nombre: json['title'] as String,
      autor: autor,
      km: kmTotal,
      duracion: durStr,
      zona: tags.isNotEmpty ? tags.first : '',
      dificultad: dificultad,
      participantes: ridersDisplay.length,
    );
  }

  Ruta copyWith({bool? isFavorita}) => Ruta(
        id: id,
        nombre: nombre,
        autor: autor,
        km: km,
        duracion: duracion,
        zona: zona,
        dificultad: dificultad,
        participantes: participantes,
        isFavorita: isFavorita ?? this.isFavorita,
      );

  String get dificultadLabel {
    switch (dificultad) {
      case RutaDificultad.facil:
        return 'Fácil';
      case RutaDificultad.moderada:
        return 'Moderada';
      case RutaDificultad.exigente:
        return 'Exigente';
    }
  }
}

class RutasState {
  final List<Ruta> rutas;
  final RutaFiltro filtroActivo;
  final String query;
  final bool isLoading;
  final String? error;

  const RutasState({
    this.rutas = const [],
    this.filtroActivo = RutaFiltro.todas,
    this.query = '',
    this.isLoading = false,
    this.error,
  });

  List<Ruta> get rutasFiltradas {
    var lista = rutas;
    if (query.isNotEmpty) {
      lista = lista
          .where((r) =>
              r.nombre.toLowerCase().contains(query.toLowerCase()) ||
              r.zona.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    switch (filtroActivo) {
      case RutaFiltro.todas:
        return lista;
      case RutaFiltro.cercanas:
        return lista.where((r) => r.km < 150).toList();
      case RutaFiltro.populares:
        return lista.where((r) => r.participantes > 5).toList();
      case RutaFiltro.recientes:
        return lista.take(3).toList();
    }
  }

  RutasState copyWith({
    List<Ruta>? rutas,
    RutaFiltro? filtroActivo,
    String? query,
    bool? isLoading,
    String? error,
  }) =>
      RutasState(
        rutas: rutas ?? this.rutas,
        filtroActivo: filtroActivo ?? this.filtroActivo,
        query: query ?? this.query,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
