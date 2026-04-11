class PerfilStat {
  final String valor;
  final String label;
  const PerfilStat({required this.valor, required this.label});
}

class MotoInfo {
  final String nombre;
  final String tipo;
  final int kmAcumulados;
  const MotoInfo({
    required this.nombre,
    required this.tipo,
    required this.kmAcumulados,
  });
}

class PerfilState {
  final String nombre;
  final String ubicacion;
  final List<PerfilStat> stats;
  final MotoInfo? moto;
  final bool isLoading;

  const PerfilState({
    this.nombre = '',
    this.ubicacion = '',
    this.stats = const [],
    this.moto,
    this.isLoading = false,
  });

  PerfilState copyWith({
    String? nombre,
    String? ubicacion,
    List<PerfilStat>? stats,
    MotoInfo? moto,
    bool? isLoading,
  }) =>
      PerfilState(
        nombre: nombre ?? this.nombre,
        ubicacion: ubicacion ?? this.ubicacion,
        stats: stats ?? this.stats,
        moto: moto ?? this.moto,
        isLoading: isLoading ?? this.isLoading,
      );
}
