import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noray4/features/perfil/models/perfil_models.dart';
import 'package:noray4/features/perfil/services/riders_service.dart';

class PerfilNotifier extends StateNotifier<PerfilState> {
  final _riders = RidersService();

  PerfilNotifier() : super(const PerfilState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final rider = await _riders.getMyRider();
      final stats = await _riders.getStats(rider.id);
      state = PerfilState(
        nombre: rider.displayName,
        ubicacion: rider.city ?? '',
        moto: rider.hasMoto
            ? MotoInfo(
                nombre: rider.vehicleModel!,
                tipo: rider.vehicleType ?? '',
                kmAcumulados: rider.vehicleKm ?? 0,
              )
            : null,
        stats: [
          PerfilStat(valor: '${stats.amarres}', label: 'registros'),
          PerfilStat(valor: _formatKm(stats.kmTotales), label: 'km'),
          PerfilStat(valor: '${stats.grupos}', label: 'grupos'),
        ],
        isLoading: false,
      );
    } catch (_) {
      // Sin conexión o perfil aún no creado — estado vacío
      state = const PerfilState(isLoading: false);
    }
  }

  /// Fuerza recarga del perfil desde la API.
  Future<void> refresh() => _load();

  /// Actualiza el perfil en la API y refleja el cambio en el estado.
  Future<void> updatePerfil({
    required String displayName,
    required String city,
    required String bio,
  }) async {
    try {
      final rider = await _riders.updateRider(
        displayName: displayName,
        city: city,
        bio: bio,
      );
      state = state.copyWith(
        nombre: rider.displayName,
        ubicacion: rider.city ?? '',
      );
    } catch (_) {
      // Ignorar — el estado local ya refleja el cambio optimista si se aplica
    }
  }

  /// Registra o actualiza la moto.
  Future<void> updateMoto({
    required String modelo,
    required int anio,
    required int km,
  }) async {
    final rider = await _riders.updateMoto(modelo: modelo, anio: anio, km: km);
    if (rider.hasMoto) {
      state = state.copyWith(
        moto: MotoInfo(
          nombre: rider.vehicleModel!,
          tipo: rider.vehicleType ?? '',
          kmAcumulados: rider.vehicleKm ?? 0,
        ),
      );
    }
  }

  String _formatKm(int km) {
    if (km >= 1000) return '${(km / 1000).toStringAsFixed(1)}k';
    return '$km';
  }
}

final perfilProvider = StateNotifierProvider<PerfilNotifier, PerfilState>(
  (_) => PerfilNotifier(),
);
