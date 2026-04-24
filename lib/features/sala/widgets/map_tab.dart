import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:remixicon/remixicon.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/sala/providers/map_provider.dart';
import 'package:noray4/features/sala/providers/sala_provider.dart';
import 'package:noray4/shared/widgets/rider_avatar.dart';

// ─── Public constants ────────────────────────────────────────────────────────

const kGreen = Color(0xFF34C759);
const kAccentRed = Color(0xFFFF3B30);

const kRiderColors = [
  Color(0xFF4A90E2),
  Color(0xFFF5A623),
  Color(0xFF7ED321),
  Color(0xFF9B59B6),
  Color(0xFFE74C3C),
  Color(0xFF1ABC9C),
];

Color riderColor(String riderId) {
  final hash = riderId.codeUnits.fold(0, (a, b) => a + b);
  return kRiderColors[hash % kRiderColors.length];
}

// ─── MapTabController ─────────────────────────────────────────────────────────

class MapTabController {
  void Function() centerOnMe = () {};
  void Function() fitAll = () {};
}

// ─── Internals ────────────────────────────────────────────────────────────────

const _kDefaultCenter = LatLng(19.4326, -99.1332);

class _RiderAnim {
  final AnimationController controller;
  LatLng from;
  LatLng to;

  _RiderAnim({required this.controller, required this.from, required this.to});

  LatLng get current => LatLng(
        from.latitude + (to.latitude - from.latitude) * controller.value,
        from.longitude + (to.longitude - from.longitude) * controller.value,
      );
}

// ─── MapTab ───────────────────────────────────────────────────────────────────

class MapTab extends ConsumerStatefulWidget {
  final String salaId;
  final MapTabController? controller;

  const MapTab({super.key, required this.salaId, this.controller});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> with TickerProviderStateMixin {
  final _mapController = MapController();
  final _riderAnims = <String, _RiderAnim>{};
  final _animatedPositions = ValueNotifier<Map<String, LatLng>>({});
  bool _mapReady = false;
  bool _firstPositionsReceived = false;
  double _currentZoom = 14.0;
  // Stores myPosition if it arrives before the map is ready for a one-time center.
  LatLng? _pendingCenter;

  ProviderSubscription<Map<String, MapRiderPosition>>? _ridersSub;
  ProviderSubscription<LatLng?>? _myPosSub;

  @override
  void initState() {
    super.initState();
    widget.controller?.centerOnMe = _centerOnMe;
    widget.controller?.fitAll = _fitAll;

    // If positions already in state when widget mounts, skip loader.
    _firstPositionsReceived =
        ref.read(mapProvider(widget.salaId)).riders.isNotEmpty;

    _ridersSub = ref.listenManual(
      mapProvider(widget.salaId).select((s) => s.riders),
      (prev, next) => _onRidersChanged(prev ?? {}, next),
      fireImmediately: true,
    );
    _myPosSub = ref.listenManual(
      mapProvider(widget.salaId).select((s) => s.myPosition),
      (prev, pos) {
        if (prev == null && pos != null) {
          // Primera posición propia: centrar sin activar autoFollow.
          if (_mapReady) {
            _mapController.move(pos, 14);
          } else {
            _pendingCenter = pos;
          }
        }
        _onMyPositionChanged(pos);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _ridersSub?.close();
    _myPosSub?.close();
    for (final a in _riderAnims.values) {
      a.controller.dispose();
    }
    _animatedPositions.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Rider animation ───────────────────────────────────────────────────────

  void _onRidersChanged(
    Map<String, MapRiderPosition> prev,
    Map<String, MapRiderPosition> next,
  ) {
    final newPos = Map<String, LatLng>.from(_animatedPositions.value);

    for (final entry in next.entries) {
      final id = entry.key;
      final rider = entry.value;

      if (!_riderAnims.containsKey(id)) {
        final ctrl = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        )..addListener(() {
            if (!mounted) return;
            final anim = _riderAnims[id];
            if (anim == null) return;
            final updated =
                Map<String, LatLng>.from(_animatedPositions.value);
            updated[id] = anim.current;
            _animatedPositions.value = updated;
          });
        _riderAnims[id] = _RiderAnim(
          controller: ctrl,
          from: rider.position,
          to: rider.position,
        );
        newPos[id] = rider.position;
      } else if (rider.previousPosition != null &&
          rider.previousPosition != rider.position) {
        final anim = _riderAnims[id]!;
        anim.from =
            _animatedPositions.value[id] ?? rider.previousPosition!;
        anim.to = rider.position;
        anim.controller.forward(from: 0);
      }
    }

    _riderAnims.keys
        .where((id) => !next.containsKey(id))
        .toList()
        .forEach((id) {
      _riderAnims[id]!.controller.dispose();
      _riderAnims.remove(id);
      newPos.remove(id);
    });

    if (mounted) _animatedPositions.value = newPos;

    if (!_firstPositionsReceived && next.isNotEmpty) {
      setState(() => _firstPositionsReceived = true);
    }

    // groupFollow activo: en updates de coordenadas solo centra el grupo,
    // NO cambia el zoom. El zoom solo cambia al presionar el botón.
    if (next.values.any((r) => r.isOnline)) {
      final groupFollow =
          ref.read(mapProvider(widget.salaId)).groupFollow;
      if (groupFollow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _panToGroupCenter();
        });
      }
    }
  }

  // ── Auto-follow ───────────────────────────────────────────────────────────

  void _onMyPositionChanged(LatLng? pos) {
    if (!_mapReady || pos == null) return;
    final s = ref.read(mapProvider(widget.salaId));
    if (!s.autoFollow) return;
    final targetZoom = _zoomForSpeed(s.currentSpeed);
    _mapController.move(pos, targetZoom ?? _mapController.camera.zoom);
  }

  // Speed-based zoom: only kicks in when autoFollow is active.
  // Below 30 km/h → no change. Higher speeds progressively zoom out.
  double? _zoomForSpeed(double? kmh) {
    if (kmh == null || kmh < 30) return null;
    if (kmh >= 120) return 13.0;
    if (kmh >= 80) return 14.0;
    return 15.0; // 30–80 km/h
  }

  double? _lastLoggedZoom;

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveStart &&
        event.source == MapEventSource.dragStart) {
      ref.read(mapProvider(widget.salaId).notifier).disableAutoFollow();
    }
    final zoom = _mapController.camera.zoom;
    if (zoom != _currentZoom) {
      setState(() => _currentZoom = zoom);
    }
    if (_lastLoggedZoom == null || (zoom - _lastLoggedZoom!).abs() >= 0.5) {
      _lastLoggedZoom = zoom;
      debugPrint('[MAP] zoom: ${zoom.toStringAsFixed(2)}');
    }
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  // Activa autoFollow (botón flecha). El cambio de estado ocurre siempre;
  // el movimiento de cámara solo si el mapa está listo.
  void _centerOnMe() {
    ref.read(mapProvider(widget.salaId).notifier).enableAutoFollow();
    if (!_mapReady) return;
    final pos = ref.read(mapProvider(widget.salaId)).myPosition;
    if (pos != null) _mapController.move(pos, 15);
  }

  // Activa groupFollow (botón grupo) + ajusta cámara manualmente.
  void _fitAll() {
    ref.read(mapProvider(widget.salaId).notifier).enableGroupFollow();
    _fitAllCamera();
  }

  // Pan-only: centra el grupo en cada update de coordenadas sin tocar el zoom.
  void _panToGroupCenter() {
    if (!_mapReady) return;
    final riders = ref
        .read(mapProvider(widget.salaId))
        .riders
        .values
        .where((r) => r.isOnline)
        .toList();
    if (riders.isEmpty) return;
    final lat = riders.map((r) => r.position.latitude).reduce((a, b) => a + b) /
        riders.length;
    final lng = riders.map((r) => r.position.longitude).reduce((a, b) => a + b) /
        riders.length;
    _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
  }

  // Ajusta cámara + zoom para encuadrar a todos — solo se llama al presionar botón.
  void _fitAllCamera() {
    if (!_mapReady) return;
    final riders = ref
        .read(mapProvider(widget.salaId))
        .riders
        .values
        .where((r) => r.isOnline)
        .toList();
    if (riders.isEmpty) {
      final my = ref.read(mapProvider(widget.salaId)).myPosition;
      if (my != null) _mapController.move(my, 14);
      return;
    }
    if (riders.length == 1) {
      _mapController.move(riders.first.position, 15);
      return;
    }
    final lats = riders.map((r) => r.position.latitude);
    final lngs = riders.map((r) => r.position.longitude);

    double minLat = lats.reduce(min);
    double maxLat = lats.reduce(max);
    double minLng = lngs.reduce(min);
    double maxLng = lngs.reduce(max);

    // Minimum bounding box ~0.008° (~900m) so riders close together
    // never push the zoom past the tile renderer's comfort zone.
    const minSpan = 0.008;
    if (maxLat - minLat < minSpan) {
      final mid = (maxLat + minLat) / 2;
      minLat = mid - minSpan / 2;
      maxLat = mid + minSpan / 2;
    }
    if (maxLng - minLng < minSpan) {
      final mid = (maxLng + minLng) / 2;
      minLng = mid - minSpan / 2;
      maxLng = mid + minSpan / 2;
    }

    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      ),
      padding: const EdgeInsets.all(80),
      maxZoom: 19.0,
    ));
  }

  // ── Markers ───────────────────────────────────────────────────────────────

  // Two discrete avatar sizes: full at zoom ≥ 15, compact below.
  double get _markerSize => _currentZoom >= 15 ? 52.0 : 38.0;

  /// At high zoom (≥17) when markers overlap, arrange overlapping groups in a
  /// ring centred on their geographic midpoint so no text is covered.
  Map<String, LatLng> _applyClusterLayout(
    Map<String, MapRiderPosition> riders,
    Map<String, LatLng> animPos,
  ) {
    if (!_mapReady || riders.length < 2 || _currentZoom < 17.0) return animPos;

    final markerPx = _markerSize;
    final zoom = _mapController.camera.zoom;
    final centerLatRad = _mapController.camera.center.latitude * pi / 180;
    final metersPerPx = 156543.03392 * cos(centerLatRad) / pow(2, zoom);
    final latPerPx = metersPerPx / 111111.0;
    final lngPerPx =
        metersPerPx / (111111.0 * max(cos(centerLatRad).abs(), 0.001));

    final ids = riders.keys.toList();

    // ── Union-Find ────────────────────────────────────────────────────────
    final parent = {for (final id in ids) id: id};
    String find(String x) =>
        parent[x] == x ? x : parent[x] = find(parent[x]!);

    for (int i = 0; i < ids.length; i++) {
      for (int j = i + 1; j < ids.length; j++) {
        final posA = animPos[ids[i]] ?? riders[ids[i]]!.position;
        final posB = animPos[ids[j]] ?? riders[ids[j]]!.position;
        final dlat = posB.latitude - posA.latitude;
        final dlng = posB.longitude - posA.longitude;
        final dxPx = dlng / lngPerPx;
        final dyPx = dlat / latPerPx;
        final distPx = sqrt(dxPx * dxPx + dyPx * dyPx);
        if (distPx < markerPx) {
          final ra = find(ids[i]);
          final rb = find(ids[j]);
          if (ra != rb) parent[ra] = rb;
        }
      }
    }

    // ── Group by cluster root ─────────────────────────────────────────────
    final clusters = <String, List<String>>{};
    for (final id in ids) {
      clusters.putIfAbsent(find(id), () => []).add(id);
    }

    final result = Map<String, LatLng>.from(animPos);

    // ── Arrange each overlapping cluster in a ring ─────────────────────────
    for (final clusterIds in clusters.values) {
      if (clusterIds.length < 2) continue;

      // Geographic centre of the original coordinates
      final positions =
          clusterIds.map((id) => animPos[id] ?? riders[id]!.position).toList();
      final centerLat =
          positions.map((p) => p.latitude).reduce((a, b) => a + b) /
              positions.length;
      final centerLng =
          positions.map((p) => p.longitude).reduce((a, b) => a + b) /
              positions.length;

      // Ring radius so adjacent marker edges don't overlap (+ 4px gap)
      final n = clusterIds.length;
      const gap = 4.0;
      final radiusPx = n == 2
          ? (markerPx + gap) / 2
          : (markerPx + gap) / (2 * sin(pi / n));

      for (int i = 0; i < n; i++) {
        // Start from top (−π/2) and spread clockwise
        final angle = (2 * pi * i / n) - pi / 2;
        result[clusterIds[i]] = LatLng(
          centerLat + (-cos(angle)) * radiusPx * latPerPx,
          centerLng + sin(angle) * radiusPx * lngPerPx,
        );
      }
    }

    return result;
  }

  List<Marker> _buildRiderMarkers(
    Map<String, MapRiderPosition> riders,
    Map<String, LatLng> animPos,
    bool isPttActive,
    String? activeSpeakerId,
  ) {
    final sz = _markerSize;
    final positions = _applyClusterLayout(riders, animPos);
    return riders.values.map((rider) {
      final pos = positions[rider.riderId] ?? animPos[rider.riderId] ?? rider.position;
      final isSpeaking = isPttActive && rider.isMe;
      return Marker(
        point: pos,
        width: sz,
        height: sz,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => _showRiderSheet(rider),
          child: _RiderMarkerWidget(
            rider: rider,
            isSpeaking: isSpeaking,
            size: sz,
          ),
        ),
      );
    }).toList();
  }

  Marker _buildDestinationMarker(LatLng dest) => Marker(
        point: dest,
        width: 40,
        height: 52,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () => _showDestinationSheet(dest),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: kGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(RemixIcons.flag_line,
                    size: 18, color: Colors.black),
              ),
              Container(width: 2, height: 16, color: kGreen),
            ],
          ),
        ),
      );

  void _showRiderSheet(MapRiderPosition rider) {
    final myPos = ref.read(mapProvider(widget.salaId)).myPosition;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RiderSheet(rider: rider, myPosition: myPos),
    );
  }

  void _showDestinationSheet(LatLng dest) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DestinationSheet(
        dest: dest,
        onClear: () {
          Navigator.of(context).pop();
          ref
              .read(mapProvider(widget.salaId).notifier)
              .clearDestination();
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider(widget.salaId));
    final isPttActive = ref.watch(
      salaProvider(widget.salaId).select((s) => s.isPttActive),
    );
    final activeSpeakerId = ref.watch(
      salaProvider(widget.salaId).select((s) => s.activeSpeakerId),
    );

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: mapState.myPosition ?? _kDefaultCenter,
            initialZoom: 14,
            onMapReady: () {
              _mapReady = true;
              setState(() {});
              if (_pendingCenter != null) {
                _mapController.move(_pendingCenter!, 14);
                _pendingCenter = null;
              }
            },
            onMapEvent: _onMapEvent,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.noray4.noray4',
              maxZoom: 19,
              retinaMode: RetinaMode.isHighDensity(context),
            ),
            if (mapState.routePolyline.isNotEmpty)
              PolylineLayer(polylines: [
                Polyline(
                  points: mapState.routePolyline,
                  color: Colors.white.withValues(alpha: 0.5),
                  strokeWidth: 3,
                ),
              ]),
            if (mapState.destination != null && mapState.myPosition != null)
              PolylineLayer(polylines: [
                Polyline(
                  points: [mapState.myPosition!, mapState.destination!],
                  color: kGreen.withValues(alpha: 0.8),
                  strokeWidth: 2,
                ),
              ]),
            if (mapState.destination != null)
              MarkerLayer(
                markers: [_buildDestinationMarker(mapState.destination!)],
              ),
            ValueListenableBuilder<Map<String, LatLng>>(
              valueListenable: _animatedPositions,
              builder: (ctx, animPos, _) => MarkerLayer(
                markers: _buildRiderMarkers(
                  mapState.riders,
                  animPos,
                  isPttActive,
                  activeSpeakerId,
                ),
              ),
            ),
          ],
        ),
        // Loader overlay — visible until first rider positions arrive.
        AnimatedOpacity(
          opacity: _firstPositionsReceived ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          child: _firstPositionsReceived
              ? const SizedBox.shrink()
              : ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      color: const Color(0xFF131312).withValues(alpha: 0.55),
                      child: const Center(
                        child: _MapLoader(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Map Loader ───────────────────────────────────────────────────────────────

class _MapLoader extends StatefulWidget {
  const _MapLoader();

  @override
  State<_MapLoader> createState() => _MapLoaderState();
}

class _MapLoaderState extends State<_MapLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1A).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF474747),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Localizando riders',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rider Marker ─────────────────────────────────────────────────────────────

class _RiderMarkerWidget extends ConsumerWidget {
  final MapRiderPosition rider;
  final bool isSpeaking;
  final double size;

  const _RiderMarkerWidget({
    required this.rider,
    this.isSpeaking = false,
    this.size = 52.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderColor = isSpeaking
        ? kAccentRed
        : (rider.isMe ? Noray4Colors.darkAccent : riderColor(rider.riderId));
    const borderWidth = 2.0;
    // Scale circle relative to the marker frame (leave 6px padding for arrow).
    final circleSize = (size - 6).clamp(24.0, 46.0);
    final fontSize = (circleSize * 0.28).clamp(9.0, 13.0);
    final showArrow =
        rider.heading != null && (rider.speed ?? 0) > 2;

    final ownAvatar =
        rider.isMe ? ref.watch(authProvider).user?.avatarUrl : null;

    Widget circle = Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: kAccentRed.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : (rider.isMe
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null),
      ),
      padding: const EdgeInsets.all(borderWidth),
      child: RiderAvatarCircle(
        riderId: rider.riderId,
        initials: rider.initials,
        size: circleSize - (borderWidth * 2),
        overrideUrl: ownAvatar,
        fontSize: fontSize,
      ),
    );

    if (!rider.isOnline) circle = Opacity(opacity: 0.4, child: circle);

    if (!showArrow) return circle;

    final frameSize = size;
    return SizedBox.square(
      dimension: frameSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: rider.heading! * pi / 180,
            child: SizedBox.square(
              dimension: frameSize,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 6,
                  height: 12,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          circle,
        ],
      ),
    );
  }
}

// ─── Rider Sheet ──────────────────────────────────────────────────────────────

class _RiderSheet extends StatelessWidget {
  final MapRiderPosition rider;
  final LatLng? myPosition;

  const _RiderSheet({required this.rider, this.myPosition});

  @override
  Widget build(BuildContext context) {
    const dist = Distance();
    final distKm = myPosition != null
        ? dist.as(LengthUnit.Kilometer, myPosition!, rider.position)
        : null;
    final speedStr = (rider.speed != null && rider.speed! >= 0)
        ? '${(rider.speed! * 3.6).round()} km/h'
        : '—';
    final distStr =
        distKm != null ? '${distKm.toStringAsFixed(1)} km' : '—';

    return Container(
      decoration: const BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
              color: Noray4Colors.darkOutlineVariant, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Noray4Spacing.s6,
        Noray4Spacing.s4,
        Noray4Spacing.s6,
        Noray4Spacing.s6 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Noray4Colors.darkOutlineVariant,
              borderRadius: Noray4Radius.pill,
            ),
          ),
          const SizedBox(height: Noray4Spacing.s6),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Noray4Colors.darkSurfaceContainerHighest,
                  border: Border.all(
                    color: rider.isMe
                        ? Colors.white
                        : riderColor(rider.riderId),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    rider.initials,
                    style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Noray4Spacing.s4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.isMe ? 'Tú' : rider.initials,
                    style: Noray4TextStyles.headlineM
                        .copyWith(color: Noray4Colors.darkPrimary),
                  ),
                  Text(
                    rider.isOnline ? 'En línea' : 'Sin señal',
                    style: Noray4TextStyles.bodySmall.copyWith(
                        color: Noray4Colors.darkOnSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Noray4Spacing.s6),
          Row(
            children: [
              Expanded(
                  child: _SheetStat(label: 'VELOCIDAD', value: speedStr)),
              const SizedBox(width: Noray4Spacing.s4),
              Expanded(
                  child: _SheetStat(label: 'DISTANCIA', value: distStr)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetStat extends StatelessWidget {
  final String label;
  final String value;
  const _SheetStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Noray4Spacing.s4),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerHighest,
        borderRadius: Noray4Radius.secondary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Noray4TextStyles.label.copyWith(
                  color: Noray4Colors.darkOnSurfaceVariant, fontSize: 9)),
          const SizedBox(height: Noray4Spacing.s1),
          Text(value,
              style: Noray4TextStyles.headlineM.copyWith(
                  color: Noray4Colors.darkPrimary, fontSize: 16)),
        ],
      ),
    );
  }
}

// ─── Destination Sheet ────────────────────────────────────────────────────────

class _DestinationSheet extends StatelessWidget {
  final LatLng dest;
  final VoidCallback onClear;
  const _DestinationSheet({required this.dest, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
              color: Noray4Colors.darkOutlineVariant, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Noray4Spacing.s6,
        Noray4Spacing.s4,
        Noray4Spacing.s6,
        Noray4Spacing.s6 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Noray4Colors.darkOutlineVariant,
              borderRadius: Noray4Radius.pill,
            ),
          ),
          const SizedBox(height: Noray4Spacing.s6),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: 0.12),
                  borderRadius: Noray4Radius.secondary,
                  border: Border.all(
                      color: kGreen.withValues(alpha: 0.4), width: 0.5),
                ),
                child:
                    const Icon(RemixIcons.flag_line, size: 20, color: kGreen),
              ),
              const SizedBox(width: Noray4Spacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Destino marcado',
                        style: Noray4TextStyles.headlineM
                            .copyWith(color: Noray4Colors.darkPrimary)),
                    Text(
                      '${dest.latitude.toStringAsFixed(5)}, '
                      '${dest.longitude.toStringAsFixed(5)}',
                      style: Noray4TextStyles.bodySmall.copyWith(
                          color: Noray4Colors.darkOnSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Noray4Spacing.s6),
          GestureDetector(
            onTap: onClear,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: Noray4Radius.primary,
                border: Border.all(
                    color: Noray4Colors.darkOutlineVariant, width: 0.5),
              ),
              child: Center(
                child: Text(
                  'Quitar destino',
                  style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkOnSurfaceVariant),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
