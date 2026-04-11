import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noray4/features/amarres/models/amarres_models.dart';
import 'package:noray4/features/amarres/services/amarres_service.dart';

class AmarresNotifier extends StateNotifier<AmarresState> {
  final _service = AmarresService();

  AmarresNotifier() : super(const AmarresState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final amarres = await _service.getMyAmarres();
      final totalKm = amarres.fold(0, (sum, a) => sum + a.km);
      state = AmarresState(amarres: amarres, totalKm: totalKm);
    } catch (e) {
      state = AmarresState(error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  // Clonación local — persistencia via API en Sprint 2
  void addAmarre(Amarre amarre) {
    final updated = [amarre, ...state.amarres];
    state = state.copyWith(
      amarres: updated,
      totalKm: updated.fold<int>(0, (sum, a) => sum + a.km),
    );
  }
}

final amarresProvider = StateNotifierProvider<AmarresNotifier, AmarresState>(
  (_) => AmarresNotifier(),
);
