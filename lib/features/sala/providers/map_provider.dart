import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/features/sala/models/sala_models.dart';
import 'package:noray4/features/sala/providers/sala_provider.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class MapRiderPosition {
  final String riderId;
  final String initials;
  final LatLng position;
  final LatLng? previousPosition;
  final double? heading;
  final double? speed; // m/s
  final DateTime timestamp;
  final bool isMe;
  final bool isOnline; // false if sin señal >30s

  const MapRiderPosition({
    required this.riderId,
    required this.initials,
    required this.position,
    this.previousPosition,
    this.heading,
    this.speed,
    required this.timestamp,
    required this.isMe,
    required this.isOnline,
  });
}

// ─── State ────────────────────────────────────────────────────────────────────

class MapState {
  final Map<String, MapRiderPosition> riders;
  final List<LatLng> routePolyline;
  final LatLng? destination;
  final bool autoFollow;
  final LatLng? myPosition;
  final double? currentSpeed; // km/h
  final double distanceTraveled; // km acumulados

  const MapState({
    this.riders = const {},
    this.routePolyline = const [],
    this.destination,
    this.autoFollow = true,
    this.myPosition,
    this.currentSpeed,
    this.distanceTraveled = 0.0,
  });

  MapState copyWith({
    Map<String, MapRiderPosition>? riders,
    List<LatLng>? routePolyline,
    LatLng? destination,
    bool clearDestination = false,
    bool? autoFollow,
    LatLng? myPosition,
    double? currentSpeed,
    bool clearSpeed = false,
    double? distanceTraveled,
  }) =>
      MapState(
        riders: riders ?? this.riders,
        routePolyline: routePolyline ?? this.routePolyline,
        destination:
            clearDestination ? null : (destination ?? this.destination),
        autoFollow: autoFollow ?? this.autoFollow,
        myPosition: myPosition ?? this.myPosition,
        currentSpeed:
            clearSpeed ? null : (currentSpeed ?? this.currentSpeed),
        distanceTraveled: distanceTraveled ?? this.distanceTraveled,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class MapNotifier extends StateNotifier<MapState> {
  final String _salaId;
  final String _myRiderId;
  final Ref _ref;
  final _dio = Dio();
  static const _distCalc = Distance();
  LatLng? _lastRoutePoint;

  MapNotifier(this._salaId, this._myRiderId, this._ref)
      : super(const MapState()) {
    _ref.listen(
      salaProvider(_salaId).select((s) => s.lastPositions),
      (_, next) => _syncPositions(next),
    );
    _ref.listen(
      salaProvider(_salaId).select((s) => s.riders),
      (_, next) => _syncRiderNames(next),
    );
  }

  // ── Sync rider positions ──────────────────────────────────────────────────

  void _syncPositions(Map<String, RiderPosition> raw) {
    final updated = Map<String, MapRiderPosition>.from(state.riders);

    for (final e in raw.entries) {
      final riderId = e.key;
      final r = e.value;
      final prev = updated[riderId];
      final newPos = LatLng(r.lat, r.lng);
      final isMe = riderId == _myRiderId;

      updated[riderId] = MapRiderPosition(
        riderId: riderId,
        initials: prev?.initials ??
            riderId.substring(0, min(2, riderId.length)).toUpperCase(),
        position: newPos,
        previousPosition: prev?.position,
        heading: r.heading,
        speed: r.speed,
        timestamp: r.updatedAt,
        isMe: isMe,
        isOnline: !r.isStale,
      );

      if (isMe) _updateMyStats(prev?.position, newPos, r.speed);
    }

    final myPos = updated[_myRiderId]?.position;
    state = state.copyWith(riders: updated, myPosition: myPos);
    _maybeFetchRoute();
  }

  // ── Sync display names ────────────────────────────────────────────────────

  void _syncRiderNames(List<SalaRider> salaRiders) {
    if (state.riders.isEmpty) return;
    final nameMap = {
      for (final r in salaRiders)
        if (r.riderId != null) r.riderId!: r.initials,
    };
    final updated = {
      for (final e in state.riders.entries)
        e.key: MapRiderPosition(
          riderId: e.value.riderId,
          initials: nameMap[e.key] ?? e.value.initials,
          position: e.value.position,
          previousPosition: e.value.previousPosition,
          heading: e.value.heading,
          speed: e.value.speed,
          timestamp: e.value.timestamp,
          isMe: e.value.isMe,
          isOnline: e.value.isOnline,
        ),
    };
    state = state.copyWith(riders: updated);
  }

  // ── My stats ──────────────────────────────────────────────────────────────

  void _updateMyStats(LatLng? prev, LatLng curr, double? speedMs) {
    double newDist = state.distanceTraveled;
    if (prev != null) {
      final distM = _distCalc.as(LengthUnit.Meter, prev, curr);
      if (distM > 5) newDist += distM / 1000.0;
    }
    final kmh =
        (speedMs != null && speedMs >= 0) ? speedMs * 3.6 : null;
    state = state.copyWith(
      distanceTraveled: newDist,
      currentSpeed: kmh,
      clearSpeed: kmh == null,
    );
  }

  // ── OSRM route ────────────────────────────────────────────────────────────

  void _maybeFetchRoute() {
    final my = state.myPosition;
    if (my == null) return;
    if (_lastRoutePoint == null ||
        _distCalc.as(LengthUnit.Meter, _lastRoutePoint!, my) > 100) {
      _lastRoutePoint = my;
      fetchRoute();
    }
  }

  Future<void> fetchRoute() async {
    final online = state.riders.values.where((r) => r.isOnline).toList();
    if (online.length < 2) {
      state = state.copyWith(routePolyline: const []);
      return;
    }
    final coords = online
        .map((r) => '${r.position.longitude},${r.position.latitude}')
        .join(';');
    final url = 'https://router.project-osrm.org/route/v1/driving/$coords'
        '?overview=full&geometries=geojson';
    try {
      final res = await _dio.get<Map<String, dynamic>>(url);
      final routes = res.data?['routes'] as List?;
      if (routes == null || routes.isEmpty) return;
      final coordList =
          (routes[0] as Map<String, dynamic>)['geometry']['coordinates']
              as List;
      final polyline = coordList
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();
      state = state.copyWith(routePolyline: polyline);
    } catch (_) {
      // OSRM unavailable — no crash, keep existing route
    }
  }

  // ── Public actions ────────────────────────────────────────────────────────

  void setDestination(LatLng dest) {
    state = state.copyWith(destination: dest);
    fetchRoute();
  }

  void clearDestination() => state = state.copyWith(clearDestination: true);

  void toggleAutoFollow() =>
      state = state.copyWith(autoFollow: !state.autoFollow);

  void disableAutoFollow() {
    if (state.autoFollow) state = state.copyWith(autoFollow: false);
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final mapProvider =
    StateNotifierProvider.family<MapNotifier, MapState, String>(
  (ref, salaId) {
    final myRiderId = ref.watch(authProvider).user?.id ?? '';
    return MapNotifier(salaId, myRiderId, ref);
  },
);
