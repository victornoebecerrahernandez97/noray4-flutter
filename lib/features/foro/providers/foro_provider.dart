import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noray4/features/foro/models/foro_models.dart';

class ForoNotifier extends StateNotifier<ForoState> {
  ForoNotifier() : super(const ForoState()) {
    _loadMockData();
  }

  void _loadMockData() {
    state = ForoState(posts: const [
      ForoPost(
        id: '1',
        autor: '@noe',
        titulo: '¿Qué aceite usan para la CB500X en temporada de calor?',
        preview:
            'Estoy pensando en cambiar a 10W-40 sintético para el verano. ¿Alguien ha notado diferencia?',
        hace: 'hace 2h',
        respuestas: 14,
        tags: ['mecánica', 'CB500X'],
      ),
      ForoPost(
        id: '2',
        autor: '@rider_mx',
        titulo: 'Reporte de ruta: Querétaro → Xilitla — condiciones actuales',
        preview:
            'Acabo de regresar. El tramo entre Jalpan y Xilitla tiene derrumbes menores pero es pasable. Llevan agua.',
        hace: 'hace 5h',
        respuestas: 27,
        tags: ['reporte', 'Sierra Gorda'],
      ),
      ForoPost(
        id: '3',
        autor: '@moto_cdmx',
        titulo: 'Organización amarre Domingo Huasteca — confirmados',
        preview:
            'Ya somos 8 confirmados. Salida desde Gasolinera 5 de Mayo a las 06:30. Noray activo desde las 06:00.',
        hace: 'ayer',
        respuestas: 9,
        tags: ['amarre', 'Huasteca'],
      ),
      ForoPost(
        id: '4',
        autor: '@chihuahua_trail',
        titulo: 'Temporada Barrancas: rutas que ya están secas',
        preview:
            'Con las últimas lluvias cerraron dos accesos, pero la ruta principal ya está seca y en buen estado.',
        hace: 'hace 2 días',
        respuestas: 5,
        tags: ['reporte', 'Chihuahua'],
      ),
      ForoPost(
        id: '5',
        autor: '@surf_rider',
        titulo: 'Tips para manejar con lluvia en carretera costera',
        preview:
            'Después de resbalarme dos veces quiero compartir lo que aprendí: neumáticos, velocidad y visión.',
        hace: 'hace 3 días',
        respuestas: 31,
        tags: ['seguridad', 'tips'],
      ),
    ]);
  }
}

final foroProvider = StateNotifierProvider<ForoNotifier, ForoState>(
  (_) => ForoNotifier(),
);
