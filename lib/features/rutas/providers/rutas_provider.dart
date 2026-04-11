import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noray4/features/rutas/models/rutas_models.dart';
import 'package:noray4/features/rutas/services/rutas_service.dart';

class RutasNotifier extends StateNotifier<RutasState> {
  final _service = RutasService();

  RutasNotifier() : super(const RutasState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final rutas = await _service.getFeed();
      state = state.copyWith(rutas: rutas, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  void setFiltro(RutaFiltro filtro) =>
      state = state.copyWith(filtroActivo: filtro);

  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleFavorita(String id) {
    // Favorito local — persistencia via PUT /amarres/{id} en Sprint 2
    state = state.copyWith(
      rutas: state.rutas.map((r) {
        if (r.id == id) return r.copyWith(isFavorita: !r.isFavorita);
        return r;
      }).toList(),
    );
  }
}

final rutasProvider = StateNotifierProvider<RutasNotifier, RutasState>(
  (_) => RutasNotifier(),
);
