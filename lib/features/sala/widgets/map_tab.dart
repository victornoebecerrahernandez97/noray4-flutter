import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/sala/models/sala_models.dart';

// ─── Mock data (no GPS real todavía) ─────────────────────────────────────────

const _cdmx = LatLng(19.4326, -99.1332);

const _mockPositions = [
  LatLng(19.4350, -99.1310), // isSelf
  LatLng(19.4300, -99.1360),
  LatLng(19.4380, -99.1280),
  LatLng(19.4270, -99.1390),
];

const _darkTileFilter = ColorFilter.matrix(<double>[
  -1, 0, 0, 0, 255,
   0,-1, 0, 0, 255,
   0, 0,-1, 0, 255,
   0, 0, 0, 1,   0,
]);

// ─── MapTab ───────────────────────────────────────────────────────────────────

class MapTab extends StatefulWidget {
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
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with SingleTickerProviderStateMixin {
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

  void _zoomIn() => _mapController.move(
      _mapController.camera.center, _mapController.camera.zoom + 1);
  void _zoomOut() => _mapController.move(
      _mapController.camera.center, _mapController.camera.zoom - 1);
  void _resetCenter() => _mapController.move(_cdmx, 13);

  List<Marker> _buildMarkers() {
    final riders = widget.sala.riders;
    return List.generate(_mockPositions.length, (i) {
      final initials =
          i < riders.length ? riders[i].initials : (i == 0 ? 'YO' : '+');
      return Marker(
        point: _mockPositions[i],
        width: 40,
        height: 40,
        child: _RiderMarker(initials: initials, isSelf: i == 0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Mapa real OSM con filtro oscuro ──────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _cdmx,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.noray4.app',
              // Filtro por tile → los markers no se ven afectados
              tileBuilder: (context, tile, _) => ColorFiltered(
                colorFilter: _darkTileFilter,
                child: tile,
              ),
            ),
            MarkerLayer(markers: _buildMarkers()),
          ],
        ),
        // ── Zoom controls ─────────────────────────────────────────────────────
        Positioned(
          top: 16,
          right: 16,
          child: _ZoomControls(
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onCenter: _resetCenter,
          ),
        ),
        // ── Bottom metrics + PTT ──────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomPanel(
            sala: widget.sala,
            voiceAnim: _voiceAnim,
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
          color: isSelf
              ? Noray4Colors.darkPrimary.withValues(alpha: 0.4)
              : Noray4Colors.darkOutlineVariant,
          width: isSelf ? 2 : 0.5,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: Noray4TextStyles.bodySmall.copyWith(
            color:
                isSelf ? const Color(0xFF131312) : Noray4Colors.darkPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ─── Zoom Controls ────────────────────────────────────────────────────────────

class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenter;

  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ZoomBtn(icon: Symbols.add, onTap: onZoomIn),
        const SizedBox(height: 8),
        _ZoomBtn(icon: Symbols.remove, onTap: onZoomOut),
        const SizedBox(height: 8),
        _ZoomBtn(icon: Symbols.near_me, onTap: onCenter),
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
  final VoidCallback onPttPressed;
  final VoidCallback onPttReleased;

  const _BottomPanel({
    required this.sala,
    required this.voiceAnim,
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
                      value: '${sala.riders.length + 5} online')),
            ],
          ),
          const SizedBox(height: Noray4Spacing.s4),
          _RidersRow(riders: sala.riders, voiceAnim: voiceAnim),
          const SizedBox(height: Noray4Spacing.s4),
          _PttButton(
            isActive: sala.isPttActive,
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
          const SizedBox(height: 4),
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
  const _RidersRow({required this.riders, required this.voiceAnim});

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
                Positioned(
                  left: riders.length * 28.0,
                  child: const _Avatar(initials: '+5'),
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
              const SizedBox(width: 8),
              Text(
                'Voz activa',
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
  final VoidCallback onPressed;
  final VoidCallback onReleased;

  const _PttButton({
    required this.isActive,
    required this.onPressed,
    required this.onReleased,
  });

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
                'Hablar',
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
