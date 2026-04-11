class Amarre {
  final String id;
  final String nombre;
  final DateTime fecha;
  final int km;
  final String duracion;
  final List<String> participantes;
  final String zona;
  final String? salaId;
  final List<String> tags;
  final String privacy;

  const Amarre({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.km,
    required this.duracion,
    this.participantes = const [],
    required this.zona,
    this.salaId,
    this.tags = const [],
    this.privacy = 'private',
  });

  factory Amarre.fromJson(Map<String, dynamic> json) {
    final duracionMin = json['duracion_min'] as int? ?? 0;
    final h = duracionMin ~/ 60;
    final m = duracionMin % 60;
    final duracionStr =
        h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';

    final ridersDisplay = (json['riders_display'] as List?) ?? [];
    final participantes = ridersDisplay
        .map((e) => (e as Map<String, dynamic>)['display_name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    final tags = (json['tags'] as List?)?.cast<String>() ?? [];

    return Amarre(
      id: json['_id'] as String,
      nombre: json['title'] as String,
      fecha: DateTime.parse(json['created_at'] as String),
      km: ((json['km_total'] as num?) ?? 0).round(),
      duracion: duracionStr,
      participantes: participantes,
      zona: tags.isNotEmpty ? tags.first : '',
      salaId: json['sala_id'] as String?,
      tags: tags,
      privacy: json['privacy'] as String? ?? 'private',
    );
  }

  String get fechaFormateada {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }
}

class AmarresState {
  final List<Amarre> amarres;
  final int totalKm;
  final bool isLoading;
  final String? error;

  const AmarresState({
    this.amarres = const [],
    this.totalKm = 0,
    this.isLoading = false,
    this.error,
  });

  AmarresState copyWith({
    List<Amarre>? amarres,
    int? totalKm,
    bool? isLoading,
    String? error,
  }) =>
      AmarresState(
        amarres: amarres ?? this.amarres,
        totalKm: totalKm ?? this.totalKm,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
