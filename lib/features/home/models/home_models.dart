class NorayActivo {
  final String id;
  final String nombre;
  final double km;
  final String tiempo;
  final bool hasVoz;
  final bool hasGps;

  const NorayActivo({
    required this.id,
    required this.nombre,
    required this.km,
    required this.tiempo,
    this.hasVoz = true,
    this.hasGps = true,
  });
}

class ProximoAmarre {
  final String id;
  final String nombre;
  final int dia;
  final String diaSemana;
  final String puntoReunion;
  final String status;

  const ProximoAmarre({
    required this.id,
    required this.nombre,
    required this.dia,
    required this.diaSemana,
    required this.puntoReunion,
    this.status = 'Pronto',
  });
}

class RutaComunidad {
  final String id;
  final String nombre;
  final String autor;
  final int km;
  final String hace;
  final bool isFavorita;

  const RutaComunidad({
    required this.id,
    required this.nombre,
    required this.autor,
    required this.km,
    required this.hace,
    this.isFavorita = false,
  });

  RutaComunidad copyWith({bool? isFavorita}) => RutaComunidad(
        id: id,
        nombre: nombre,
        autor: autor,
        km: km,
        hace: hace,
        isFavorita: isFavorita ?? this.isFavorita,
      );
}

class HomeState {
  final NorayActivo? norayActivo;
  final List<ProximoAmarre> proximosAmarres;
  final List<RutaComunidad> rutas;
  final bool isLoading;

  const HomeState({
    this.norayActivo,
    this.proximosAmarres = const [],
    this.rutas = const [],
    this.isLoading = false,
  });

  HomeState copyWith({
    NorayActivo? norayActivo,
    List<ProximoAmarre>? proximosAmarres,
    List<RutaComunidad>? rutas,
    bool? isLoading,
  }) =>
      HomeState(
        norayActivo: norayActivo ?? this.norayActivo,
        proximosAmarres: proximosAmarres ?? this.proximosAmarres,
        rutas: rutas ?? this.rutas,
        isLoading: isLoading ?? this.isLoading,
      );
}
