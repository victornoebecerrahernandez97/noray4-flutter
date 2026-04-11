import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noray4/features/home/models/home_models.dart';
import 'package:noray4/features/home/services/home_service.dart';

class HomeNotifier extends StateNotifier<HomeState> {
  final _service = HomeService();

  HomeNotifier() : super(const HomeState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.load();
      state = HomeState(
        norayActivo: data.norayActivo,
        proximosAmarres: data.proximosAmarres,
        rutas: data.rutas,
        isLoading: false,
      );
    } catch (_) {
      state = const HomeState(isLoading: false);
    }
  }

  Future<void> refresh() => _load();

  void toggleFavorita(String rutaId) {
    state = state.copyWith(
      rutas: state.rutas.map((r) {
        if (r.id == rutaId) return r.copyWith(isFavorita: !r.isFavorita);
        return r;
      }).toList(),
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
  (_) => HomeNotifier(),
);
