import 'dart:async';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import 'package:noray4/core/network/api_client.dart';
import 'package:noray4/core/network/api_endpoints.dart';
import 'package:noray4/features/sala/models/sala_models.dart';

class LocationService {
  final String salaId;
  final void Function(Map<String, RiderPosition> positions) onPositionsUpdated;
  final void Function(bool active) onGpsStatusChanged;

  final Dio _dio = ApiClient.instance.dio;
  Timer? _timer;
  Position? _lastPosition;
  bool _permissionGranted = false;

  LocationService({
    required this.salaId,
    required this.onPositionsUpdated,
    required this.onGpsStatusChanged,
  });

  Future<void> start() async {
    _permissionGranted = await _requestPermission();
    onGpsStatusChanged(_permissionGranted);

    // Publicar inmediatamente al entrar, luego cada 3s
    await _publishAndFetch();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _publishAndFetch());
  }

  Future<bool> _requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> _publishAndFetch() async {
    try {
      final data = <String, dynamic>{};

      if (_permissionGranted) {
        try {
          _lastPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          );
          data['lat'] = _lastPosition!.latitude;
          data['lng'] = _lastPosition!.longitude;
          if (_lastPosition!.heading >= 0) {
            data['heading'] = _lastPosition!.heading;
          }
          if (_lastPosition!.speed >= 0) {
            data['speed'] = _lastPosition!.speed;
          }
        } catch (_) {
          if (_lastPosition != null) {
            data['lat'] = _lastPosition!.latitude;
            data['lng'] = _lastPosition!.longitude;
          }
        }
      }

      if (data.isEmpty) data['lat'] = 0.0;

      final res = await _dio.post(
        ApiEndpoints.locationUpdate(salaId),
        data: data,
      );

      final raw = res.data as Map<String, dynamic>;
      final rawPositions = raw['last_positions'] as Map<String, dynamic>? ?? {};

      final positions = rawPositions.map((riderId, posJson) => MapEntry(
            riderId,
            RiderPosition.fromJson(
                riderId, posJson as Map<String, dynamic>),
          ));

      onPositionsUpdated(positions);
    } catch (_) {
      // Network error — no interrumpir el timer
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
