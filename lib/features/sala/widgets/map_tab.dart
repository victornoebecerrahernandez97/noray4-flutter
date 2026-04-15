import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:remixicon/remixicon.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/sala/providers/map_provider.dart';
import 'package:noray4/features/sala/providers/sala_provider.dart';

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

  ProviderSubscription<Map<String, MapRiderPosition>>? _ridersSub;
  ProviderSubscription<LatLng?>? _myPosSub;

  @override
  void initState() {
    super.initState();
    widget.controller?.centerOnMe = _centerOnMe;
    widget.controller?.fitAll = _fitAll;

    _ridersSub = ref.listenManual(
      mapProvider(widget.salaId).select((s) => s.riders),
      (prev, next) => _onRidersChanged(prev ?? {}, next),
      fireImmediately: true,
    );
    _myPosSub = ref.listenManual(
      mapProvider(widget.salaId).select((s) => s.myPosition),
      (prev, pos) {
        if (prev == null && pos != null) {
          // Primera posición GPS recibida — centrar cámara sin esperar interacción
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_mapReady && mounted) {
              _mapController.move(pos, 14);
            }
          });
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
  }

  // ── Auto-follow ───────────────────────────────────────────────────────────

  void _onMyPositionChanged(LatLng? pos) {
    if (!_mapReady || pos == null) return;
    if (ref.read(mapProvider(widget.salaId)).autoFollow) {
      _mapController.move(pos, _mapController.camera.zoom);
    }
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveStart &&
        event.source == MapEventSource.dragStart) {
      ref.read(mapProvider(widget.salaId).notifier).disableAutoFollow();
    }
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  void _centerOnMe() {
    if (!_mapReady) return;
    final s = ref.read(mapProvider(widget.salaId));
    if (s.myPosition != null) _mapController.move(s.myPosition!, 15);
    if (!s.autoFollow) {
      ref.read(mapProvider(widget.salaId).notifier).toggleAutoFollow();
    }
  }

  void _fitAll() {
    if (!_mapReady) return;
    ref.read(mapProvider(widget.salaId).notifier).disableAutoFollow();
    final riders =
        ref.read(mapProvider(widget.salaId)).riders.values.where((r) => r.isOnline).toList();
    if (riders.isEmpty) {
      _mapController.move(_kDefaultCenter, 13);
      return;
    }
    if (riders.length == 1) {
      _mapController.move(riders.first.position, 15);
      return;
    }
    final lats = riders.map((r) => r.position.latitude);
    final lngs = riders.map((r) => r.position.longitude);
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(
        LatLng(lats.reduce(min), lngs.reduce(min)),
        LatLng(lats.reduce(max), lngs.reduce(max)),
      ),
      padding: const EdgeInsets.all(80),
    ));
  }

  // ── Markers ───────────────────────────────────────────────────────────────

  List<Marker> _buildRiderMarkers(
    Map<String, MapRiderPosition> riders,
    Map<String, LatLng> animPos,
    bool isPttActive,
    String? activeSpeakerId,
  ) {
    return riders.values.map((rider) {
      final pos = animPos[rider.riderId] ?? rider.position;
      final isSpeaking = isPttActive && rider.isMe;
      return Marker(
        point: pos,
        width: 52,
        height: 52,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => _showRiderSheet(rider),
          child: _RiderMarkerWidget(
            rider: rider,
            isSpeaking: isSpeaking,
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

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: mapState.myPosition ?? _kDefaultCenter,
        initialZoom: 14,
        onMapReady: () => setState(() => _mapReady = true),
        onMapEvent: _onMapEvent,
      ),
      children: [
        // Layer 1: CartoDB dark tiles
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.noray4.noray4',
          maxZoom: 19,
          retinaMode: RetinaMode.isHighDensity(context),
        ),
        // Layer 2: OSRM route
        if (mapState.routePolyline.isNotEmpty)
          PolylineLayer(polylines: [
            Polyline(
              points: mapState.routePolyline,
              color: Colors.white.withValues(alpha: 0.5),
              strokeWidth: 3,
            ),
          ]),
        // Layer 3: Destination line
        if (mapState.destination != null && mapState.myPosition != null)
          PolylineLayer(polylines: [
            Polyline(
              points: [mapState.myPosition!, mapState.destination!],
              color: kGreen.withValues(alpha: 0.8),
              strokeWidth: 2,
            ),
          ]),
        // Layer 4: Destination marker
        if (mapState.destination != null)
          MarkerLayer(
            markers: [_buildDestinationMarker(mapState.destination!)],
          ),
        // Layer 5: Rider markers (animated)
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
        // Layer 6: POIs — próximo sprint
      ],
    );
  }
}

// ─── Rider Marker ─────────────────────────────────────────────────────────────

class _RiderMarkerWidget extends StatelessWidget {
  final MapRiderPosition rider;
  final bool isSpeaking;

  const _RiderMarkerWidget({required this.rider, this.isSpeaking = false});

  @override
  Widget build(BuildContext context) {
    final borderColor = isSpeaking
        ? kAccentRed
        : (rider.isMe ? Colors.white : riderColor(rider.riderId));
    const bgColor = Color(0xFF1C1C1E);
    final borderWidth = rider.isMe ? 3.0 : 1.5;
    final circleSize = rider.isMe ? 44.0 : 40.0;
    final showArrow =
        rider.heading != null && (rider.speed ?? 0) > 2;

    Widget circle = Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
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
      child: Center(
        child: Text(
          rider.initials,
          style: TextStyle(
            color: Noray4Colors.darkPrimary,
            fontSize: rider.isMe ? 13 : 11,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );

    if (!rider.isOnline) circle = Opacity(opacity: 0.4, child: circle);

    if (!showArrow) return circle;

    const frameSize = 52.0;
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
