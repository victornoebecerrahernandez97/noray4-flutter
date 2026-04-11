import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/sala/models/sala_models.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _defaultCenter = LatLng(19.4326, -99.1332);

const _darkTileFilter = ColorFilter.matrix(<double>[
  -1, 0, 0, 0, 255,
   0,-1, 0, 0, 255,
   0, 0,-1, 0, 255,
   0, 0, 0, 1,   0,
]);

// ─── MapTab ───────────────────────────────────────────────────────────────────

class MapTab extends ConsumerStatefulWidget {
  final SalaState sala;
  final VoidCallback onPttPressed;
  final VoidCallback onPttReleased;

  const MapTab({
    super.key,
    required this.sala,
    required this.onPttPressed,
    required this.onPttReleased,
  });

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _voiceAnim;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _voiceAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _voiceAnim.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? get _myRiderId => ref.read(authProvider).user?.id;

  Map<String, String> get _initialsMap {
    return {
      for (final r in widget.sala.riders)
        if (r.riderId != null) r.riderId!: r.initials,
    };
  }

  List<RiderPosition> get _activePositions => widget.sala.lastPositions.values
      .where((p) => !p.isStale)
      .toList();

  // ── Map controls ──────────────────────────────────────────────────────────

  void _zoomIn() => _mapController.move(
      _mapController.camera.center, _mapController.camera.zoom + 1);

  void _zoomOut() => _mapController.move(
      _mapController.camera.center, _mapController.camera.zoom - 1);

  void _centerOnMe() {
    final myId = _myRiderId;
    final pos = myId != null ? widget.sala.lastPositions[myId] : null;
    if (pos != null && !pos.isStale) {
      _mapController.move(LatLng(pos.lat, pos.lng), 15);
    } else {
      _mapController.move(_defaultCenter, 13);
    }
  }

  void _fitAll() {
    final positions = _activePositions;
    if (positions.isEmpty) {
      _mapController.move(_defaultCenter, 13);
      return;
    }
    if (positions.length == 1) {
      _mapController.move(LatLng(positions.first.lat, positions.first.lng), 14);
      return;
    }
    final lats = positions.map((p) => p.lat);
    final lngs = positions.map((p) => p.lng);
    final bounds = LatLngBounds(
      LatLng(lats.reduce(min), lngs.reduce(min)),
      LatLng(lats.reduce(max), lngs.reduce(max)),
    );
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(64),
      ),
    );
  }

  // ── Markers ───────────────────────────────────────────────────────────────

  List<Marker> _buildMarkers() {
    final myId = _myRiderId;
    final initials = _initialsMap;
    return _activePositions.map((pos) {
      final isSelf = myId != null && pos.riderId == myId;
      final label = isSelf
          ? 'YO'
          : (initials[pos.riderId] ?? pos.riderId.substring(0, 2).toUpperCase());
      final heading = pos.heading;
      final hasHeading = heading != null && heading >= 0;
      Widget marker = _RiderMarker(initials: label, isSelf: isSelf);
      if (hasHeading) {
        marker = Transform.rotate(
          angle: heading * pi / 180,
          child: marker,
        );
      }
      return Marker(
        point: LatLng(pos.lat, pos.lng),
        width: 40,
        height: 40,
        child: marker,
      );
    }).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sala = widget.sala;
    return Stack(
      children: [
        // ── Mapa OSM con filtro oscuro ───────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.noray4.app',
              tileBuilder: (context, tile, _) => ColorFiltered(
                colorFilter: _darkTileFilter,
                child: tile,
              ),
            ),
            MarkerLayer(markers: _buildMarkers()),
          ],
        ),
        // ── GPS off banner ───────────────────────────────────────────────────
        if (!sala.gpsActive)
          Positioned(
            top: 16,
            left: 16,
            child: _GpsBanner(),
          ),
        // ── Map controls ────────────────────────────────────────────────────
        Positioned(
          top: 16,
          right: 16,
          child: _ZoomControls(
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onCenterMe: _centerOnMe,
            onFitAll: _fitAll,
          ),
        ),
        // ── Bottom metrics + PTT ─────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomPanel(
            sala: sala,
            voiceAnim: _voiceAnim,
            activeCount: _activePositions.length,
            onPttPressed: widget.onPttPressed,
            onPttReleased: widget.onPttReleased,
          ),
        ),
      ],
    );
  }
}

// ─── Rider Marker ─────────────────────────────────────────────────────────────

class _RiderMarker extends StatelessWidget {
  final String initials;
  final bool isSelf;
  const _RiderMarker({required this.initials, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelf
            ? Noray4Colors.darkPrimary
            : Noray4Colors.darkSurfaceContainerHighest,
        border: Border.all(
          color: isSelf ? Colors.white : Noray4Colors.darkOutlineVariant,
          width: isSelf ? 2 : 0.5,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: Noray4TextStyles.bodySmall.copyWith(
            color: isSelf
                ? const Color(0xFF131312)
                : Noray4Colors.darkPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ─── GPS Off Banner ───────────────────────────────────────────────────────────

class _GpsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Noray4Spacing.s4, vertical: Noray4Spacing.s2),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: Noray4Radius.secondary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.location_off,
              size: 16, color: Noray4Colors.darkOnSurfaceVariant),
          const SizedBox(width: Noray4Spacing.s2),
          Text(
            'GPS inactivo',
            style: Noray4TextStyles.bodySmall.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Zoom Controls ────────────────────────────────────────────────────────────

class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenterMe;
  final VoidCallback onFitAll;

  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenterMe,
    required this.onFitAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ZoomBtn(icon: Symbols.add, onTap: onZoomIn),
        const SizedBox(height: Noray4Spacing.s2),
        _ZoomBtn(icon: Symbols.remove, onTap: onZoomOut),
        const SizedBox(height: Noray4Spacing.s2),
        _ZoomBtn(icon: Symbols.near_me, onTap: onCenterMe),
        const SizedBox(height: Noray4Spacing.s2),
        _ZoomBtn(icon: Symbols.fit_screen, onTap: onFitAll),
      ],
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xCC2A2A29),
          borderRadius: Noray4Radius.secondary,
          border: Border.all(
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Icon(icon, size: 22, color: Noray4Colors.darkOnSurface),
      ),
    );
  }
}

// ─── Bottom Panel ─────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final SalaState sala;
  final AnimationController voiceAnim;
  final int activeCount;
  final VoidCallback onPttPressed;
  final VoidCallback onPttReleased;

  const _BottomPanel({
    required this.sala,
    required this.voiceAnim,
    required this.activeCount,
    required this.onPttPressed,
    required this.onPttReleased,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Noray4Spacing.s6, 0, Noray4Spacing.s6, Noray4Spacing.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _MetricCard(label: 'TIEMPO', value: sala.tiempo)),
              const SizedBox(width: Noray4Spacing.s4),
              Expanded(
                  child: _MetricCard(label: 'DIST.', value: sala.distancia)),
              const SizedBox(width: Noray4Spacing.s4),
              Expanded(
                  child: _MetricCard(
                      label: 'RIDERS',
                      value: '$activeCount online')),
            ],
          ),
          const SizedBox(height: Noray4Spacing.s4),
          _RidersRow(
            riders: sala.riders,
            voiceAnim: voiceAnim,
            activeSpeakerName: sala.activeSpeakerName,
          ),
          const SizedBox(height: Noray4Spacing.s4),
          _PttButton(
            isActive: sala.isPttActive,
            activeSpeakerName: sala.activeSpeakerName,
            onPressed: onPttPressed,
            onReleased: onPttReleased,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Noray4Spacing.s4),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: Noray4Radius.primary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Noray4TextStyles.label.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: Noray4Spacing.s1),
          Text(
            value,
            style: Noray4TextStyles.headlineM.copyWith(
              color: Noray4Colors.darkPrimary,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _RidersRow extends StatelessWidget {
  final List<SalaRider> riders;
  final AnimationController voiceAnim;
  final String? activeSpeakerName;

  const _RidersRow({
    required this.riders,
    required this.voiceAnim,
    required this.activeSpeakerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Noray4Spacing.s4),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: Noray4Radius.primary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 40,
            child: Stack(
              children: [
                for (int i = 0; i < riders.length; i++)
                  Positioned(
                    left: i * 28.0,
                    child: _Avatar(initials: riders[i].initials),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              AnimatedBuilder(
                animation: voiceAnim,
                builder: (context, child) => Icon(
                  Symbols.graphic_eq,
                  fill: 1,
                  size: 22,
                  color: Noray4Colors.darkOnSurfaceVariant
                      .withValues(alpha: 0.4 + voiceAnim.value * 0.6),
                ),
              ),
              const SizedBox(width: Noray4Spacing.s2),
              Text(
                activeSpeakerName ?? 'Canal listo',
                style: Noray4TextStyles.body.copyWith(
                  color: Noray4Colors.darkOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(
            color: Noray4Colors.darkSurfaceContainerLow, width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: Noray4TextStyles.bodySmall.copyWith(
            color: Noray4Colors.darkPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PttButton extends StatelessWidget {
  final bool isActive;
  final String? activeSpeakerName;
  final VoidCallback onPressed;
  final VoidCallback onReleased;

  const _PttButton({
    required this.isActive,
    required this.activeSpeakerName,
    required this.onPressed,
    required this.onReleased,
  });

  String get _label {
    if (isActive) return 'Hablando...';
    if (activeSpeakerName != null) return activeSpeakerName!;
    return 'Hablar';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPressed(),
      onTapUp: (_) => onReleased(),
      onTapCancel: onReleased,
      child: AnimatedScale(
        scale: isActive ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Noray4Colors.darkPrimary,
            borderRadius: Noray4Radius.primary,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Symbols.mic,
                  fill: 1, size: 24, color: Color(0xFF1A1C1C)),
              const SizedBox(width: 12),
              Text(
                _label,
                style: Noray4TextStyles.headlineM.copyWith(
                  color: const Color(0xFF1A1C1C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
