import 'dart:math' show max;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';
import 'package:noray4/core/services/haptics.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/amarres/models/amarres_models.dart';
import 'package:noray4/features/amarres/providers/amarres_provider.dart';
import 'package:noray4/features/sala/models/sala_models.dart';
import 'package:noray4/features/sala/providers/map_provider.dart';
import 'package:noray4/features/sala/providers/sala_provider.dart';
import 'package:noray4/features/sala/widgets/archivos_tab.dart';
import 'package:noray4/features/sala/widgets/chat_bubble.dart';
import 'package:noray4/features/sala/widgets/chat_input_bar.dart';
import 'package:noray4/features/sala/widgets/map_tab.dart';
import 'package:noray4/shared/widgets/rider_avatar.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _kPanelExpanded = 290.0;
const _kPanelCollapsed = 72.0;
const _kPanelPttActive = 310.0;

const _kAccentRed = Color(0xFFFF3B30);
const _kSecondary = Color(0xFF8E8E93);

// ─── Glass helper ─────────────────────────────────────────────────────────────

BoxDecoration _glassBox({
  double topLeft = 20,
  double topRight = 20,
  double bottomLeft = 0,
  double bottomRight = 0,
}) =>
    BoxDecoration(
      color: const Color(0xB80F0F0F),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(topLeft),
        topRight: Radius.circular(topRight),
        bottomLeft: Radius.circular(bottomLeft),
        bottomRight: Radius.circular(bottomRight),
      ),
      border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
    );

Widget _blur({
  required Widget child,
  double sigma = 16,
  BorderRadius? radius,
}) {
  final clip = radius != null
      ? ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: child,
          ),
        )
      : ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: child,
          ),
        );
  return clip;
}

// ─── SalaScreen ───────────────────────────────────────────────────────────────

class SalaScreen extends ConsumerStatefulWidget {
  final String salaId;
  final Map<String, dynamic>? salaData;

  const SalaScreen({super.key, required this.salaId, this.salaData});

  @override
  ConsumerState<SalaScreen> createState() => _SalaScreenState();
}

class _SalaScreenState extends ConsumerState<SalaScreen> {
  final _mapCtrl = MapTabController();

  String _nombre(SalaState sala) {
    final fromData =
        (widget.salaData?['nombre'] as String?)?.isNotEmpty == true
            ? widget.salaData!['nombre'] as String
            : null;
    return fromData ?? sala.nombre;
  }

  Future<void> _cerrarSalida(SalaState sala) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _CerrarSalidaSheet(),
    );
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(salaProvider(widget.salaId).notifier);
    final mapState = ref.read(mapProvider(widget.salaId));

    // Intenta cerrar en backend y obtener el amarre real
    Amarre? amarre = await notifier.closeSalaAndGetAmarre();

    // Fallback si el backend falla o el rider no es admin
    amarre ??= Amarre(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: _nombre(sala),
      fecha: DateTime.now(),
      km: mapState.distanceTraveled.round(),
      duracion: sala.tiempo,
      participantes: sala.riders
          .map((r) => r.displayName ?? r.initials)
          .toList(),
      zona: 'Reciente',
    );

    if (!mounted) return;
    ref.read(amarresProvider.notifier).addAmarre(amarre);
    await N4Haptics.heavy();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Registro guardado. ¡Buena salida!',
        style: Noray4TextStyles.body.copyWith(
            color: Noray4Colors.darkPrimary),
      ),
      backgroundColor: Noray4Colors.darkSurfaceContainerHigh,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: Noray4Radius.secondary,
        side: const BorderSide(
            color: Noray4Colors.darkOutlineVariant, width: 0.5),
      ),
    ));

    context.go('/registros');
  }

  @override
  Widget build(BuildContext context) {
    final sala = ref.watch(salaProvider(widget.salaId));
    final nombre = _nombre(sala);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Mapa full screen
          Positioned.fill(
            child: MapTab(
              salaId: widget.salaId,
              controller: _mapCtrl,
            ),
          ),

          // 2. Header glass
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _HeaderSala(
              salaId: widget.salaId,
              nombre: nombre,
              onCerrar: () => _cerrarSalida(sala),
            ),
          ),

          // 3. Stats overlay
          Positioned(
            top: 60 + MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: _StatsOverlay(salaId: widget.salaId),
          ),

          // 4. FABs columna derecha
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.42,
            child: _MapFABs(
              salaId: widget.salaId,
              mapCtrl: _mapCtrl,
            ),
          ),

          // 5. Bottom panel collapsable
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomPanel(salaId: widget.salaId),
          ),
        ],
      ),
    );
  }
}

// ─── Header Sala ──────────────────────────────────────────────────────────────

class _HeaderSala extends ConsumerWidget {
  final String salaId;
  final String nombre;
  final VoidCallback onCerrar;

  const _HeaderSala({
    required this.salaId,
    required this.nombre,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riders =
        ref.watch(salaProvider(salaId).select((s) => s.riders));
    final onlineCount = ref.watch(
        salaProvider(salaId).select((s) => s.onlineRiderIds.length));
    final totalCount = max(onlineCount, riders.length);
    final topPad = MediaQuery.of(context).padding.top;

    return _blur(
      sigma: 12,
      child: Container(
        height: 56 + topPad,
        padding: EdgeInsets.only(
          top: topPad,
          left: Noray4Spacing.s4,
          right: Noray4Spacing.s4,
        ),
        color: const Color(0xCC0A0A0A),
        child: Row(
          children: [
            // Back
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: const Icon(RemixIcons.arrow_left_line,
                    size: 22, color: Colors.white),
              ),
            ),
            const SizedBox(width: Noray4Spacing.s2),
            // Nombre
            Expanded(
              child: Text(
                nombre.isEmpty ? 'Salida en curso' : nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Riders pill — muestra online en tiempo real, fallback a lista estática
            if (riders.isNotEmpty || onlineCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Noray4Colors.darkAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: Noray4Colors.darkAccent.withValues(alpha: 0.6),
                      width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Noray4Colors.darkAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      onlineCount < totalCount
                          ? '$onlineCount/$totalCount riders'
                          : '$totalCount riders',
                      style: const TextStyle(
                        color: Noray4Colors.darkAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Noray4Spacing.s2),
            ],
            // More menu
            GestureDetector(
              onTap: onCerrar,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: Icon(RemixIcons.more_2_fill,
                    size: 20, color: _kSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Overlay ────────────────────────────────────────────────────────────

class _StatsOverlay extends ConsumerWidget {
  final String salaId;
  const _StatsOverlay({required this.salaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed =
        ref.watch(mapProvider(salaId).select((s) => s.currentSpeed));
    final dist =
        ref.watch(mapProvider(salaId).select((s) => s.distanceTraveled));

    return Center(
      child: _blur(
        radius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: _glassBox(
              topLeft: 20,
              topRight: 20,
              bottomLeft: 20,
              bottomRight: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatCell(
                value: speed != null ? '${speed.round()}' : '—',
                unit: 'km/h',
                label: 'VELOCIDAD',
              ),
              Container(
                width: 1,
                height: 32,
                color: const Color(0x1AFFFFFF),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _StatCell(
                value: dist.toStringAsFixed(1),
                unit: 'km',
                label: 'DISTANCIA',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _StatCell({
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Courier',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: _kSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ─── Map FABs ─────────────────────────────────────────────────────────────────

class _MapFABs extends ConsumerWidget {
  final String salaId;
  final MapTabController mapCtrl;

  const _MapFABs({required this.salaId, required this.mapCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoFollow =
        ref.watch(mapProvider(salaId).select((s) => s.autoFollow));
    final groupFollow =
        ref.watch(mapProvider(salaId).select((s) => s.groupFollow));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FabBtn(
          icon: RemixIcons.navigation_line,
          active: autoFollow,
          onTap: mapCtrl.centerOnMe,
        ),
        const SizedBox(height: 8),
        _FabBtn(
          icon: RemixIcons.group_line,
          active: groupFollow,
          onTap: mapCtrl.fitAll,
        ),
        const SizedBox(height: 8),
        _FabBtn(
          icon: RemixIcons.map_pin_line,
          onTap: () {}, // POI toggle — próximo sprint
        ),
      ],
    );
  }
}

class _FabBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _FabBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _blur(
        radius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: _glassBox(
              topLeft: 20,
              topRight: 20,
              bottomLeft: 20,
              bottomRight: 20),
          child: Icon(
            icon,
            size: 18,
            color: active ? Colors.white : _kSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Panel ─────────────────────────────────────────────────────────────

class _BottomPanel extends ConsumerStatefulWidget {
  final String salaId;
  const _BottomPanel({required this.salaId});

  @override
  ConsumerState<_BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends ConsumerState<_BottomPanel>
    with TickerProviderStateMixin {
  late AnimationController _panelCtrl;
  Animation<double> _panelH =
      const AlwaysStoppedAnimation(_kPanelExpanded);

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _panelCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    if (!mounted) return;
    setState(() {
      _panelH = Tween<double>(begin: _panelH.value, end: target).animate(
        CurvedAnimation(parent: _panelCtrl, curve: Curves.easeInOut),
      );
    });
    _panelCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final sala = ref.watch(salaProvider(widget.salaId));
    final notifier = ref.read(salaProvider(widget.salaId).notifier);

    // PTT state → expand to pttActive height
    ref.listen(
      salaProvider(widget.salaId).select((s) => s.isPttActive),
      (prev, next) {
        if (next) {
          _pulseCtrl.repeat();
          _animateTo(_kPanelPttActive);
        } else {
          _pulseCtrl.stop();
          _pulseCtrl.reset();
          if (sala.activeTab != SalaTab.mapa) {
            _animateTo(_kPanelExpanded);
          }
        }
      },
    );

    // Tab change → collapse if mapa
    ref.listen(
      salaProvider(widget.salaId).select((s) => s.activeTab),
      (prev, next) {
        if (next == SalaTab.mapa) {
          _animateTo(_kPanelCollapsed);
        } else if (prev == SalaTab.mapa) {
          _animateTo(_kPanelExpanded);
        }
      },
    );

    final double bottomPad = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 300) {
          notifier.switchTab(SalaTab.mapa);
        } else if (v < -300 && sala.activeTab == SalaTab.mapa) {
          notifier.switchTab(SalaTab.voz);
        }
      },
      child: AnimatedBuilder(
        animation: _panelCtrl,
        builder: (context, _) {
          final h = _panelH.value + bottomPad;
          final isCollapsed = _panelH.value <= _kPanelCollapsed + 10;

          return _blur(
            radius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: h,
              decoration: _glassBox(),
              child: isCollapsed
                  ? _CollapsedBar(
                      salaId: widget.salaId,
                      activeTab: sala.activeTab,
                      onTabTap: notifier.switchTab,
                    )
                  : _ExpandedContent(
                      sala: sala,
                      notifier: notifier,
                      pulseCtrl: _pulseCtrl,
                      bottomPad: bottomPad,
                    ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Collapsed bar ────────────────────────────────────────────────────────────

class _CollapsedBar extends ConsumerWidget {
  final String salaId;
  final SalaTab activeTab;
  final void Function(SalaTab) onTabTap;

  const _CollapsedBar({
    required this.salaId,
    required this.activeTab,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riders =
        ref.watch(salaProvider(salaId).select((s) => s.riders));
    final onlineRiderIds =
        ref.watch(salaProvider(salaId).select((s) => s.onlineRiderIds));

    const tabs = [
      (SalaTab.mapa, RemixIcons.map_2_line),
      (SalaTab.chat, RemixIcons.chat_1_line),
      (SalaTab.voz, RemixIcons.mic_line),
      (SalaTab.archivos, RemixIcons.folder_3_line),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tab icons
              Row(
                children: tabs.map((t) {
                  final isActive = activeTab == t.$1;
                  return GestureDetector(
                    onTap: () => onTabTap(t.$1),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: Icon(
                        t.$2,
                        size: 22,
                        color: isActive ? Colors.white : _kSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Mini avatars overlapping
              _MiniAvatarsRow(riders: riders, onlineRiderIds: onlineRiderIds),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAvatarsRow extends StatelessWidget {
  final List<SalaRider> riders;
  final Set<String> onlineRiderIds;
  const _MiniAvatarsRow({
    required this.riders,
    required this.onlineRiderIds,
  });

  @override
  Widget build(BuildContext context) {
    if (riders.isEmpty) return const SizedBox.shrink();
    final shown = riders.take(5).toList();
    return SizedBox(
      width: shown.length * 16.0 + 8,
      height: 24,
      child: Stack(
        children: shown.asMap().entries.map((e) {
          final rider = e.value;
          final isOnline =
              rider.riderId != null && onlineRiderIds.contains(rider.riderId);
          final color = (rider.riderId != null
                  ? riderColor(rider.riderId!)
                  : _kSecondary)
              .withValues(alpha: isOnline ? 1.0 : 0.3);
          return Positioned(
            left: e.key * 16.0,
            child: Opacity(
              opacity: isOnline ? 1.0 : 0.5,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                padding: const EdgeInsets.all(1),
                child: RiderAvatarCircle(
                  riderId: rider.riderId,
                  initials: rider.initials,
                  size: 20,
                  fontSize: 8,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Expanded content ─────────────────────────────────────────────────────────

class _ExpandedContent extends StatelessWidget {
  final SalaState sala;
  final SalaNotifier notifier;
  final AnimationController pulseCtrl;
  final double bottomPad;

  const _ExpandedContent({
    required this.sala,
    required this.notifier,
    required this.pulseCtrl,
    required this.bottomPad,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drag handle
        const _DragHandle(),
        // Speaking banner (pttActive only)
        if (sala.isPttActive && sala.activeSpeakerName != null)
          _SpeakingBanner(name: sala.activeSpeakerName!),
        // Metrics row
        _MetricsRow(sala: sala),
        // Tab bar
        _TabsRow(activeTab: sala.activeTab, onTabTap: notifier.switchTab),
        // Content
        Expanded(
          child: _TabContent(
            sala: sala,
            notifier: notifier,
            pulseCtrl: pulseCtrl,
          ),
        ),
      ],
    );
  }
}

// ─── Drag handle ─────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ─── Speaking banner ─────────────────────────────────────────────────────────

class _SpeakingBanner extends StatelessWidget {
  final String name;
  const _SpeakingBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kAccentRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: _kAccentRed.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: _kAccentRed),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$name está hablando...',
              style: const TextStyle(
                color: _kAccentRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Metrics row ─────────────────────────────────────────────────────────────

class _MetricsRow extends ConsumerWidget {
  final SalaState sala;
  const _MetricsRow({required this.sala});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(
        mapProvider(sala.salaId).select((s) => s.currentSpeed));
    final dist = ref.watch(
        mapProvider(sala.salaId).select((s) => s.distanceTraveled));

    final onlineCount = ref.watch(
        salaProvider(sala.salaId).select((s) => s.onlineRiderIds.length));
    final totalCount = max(onlineCount, sala.riders.length);
    final ridersLabel = onlineCount < totalCount && totalCount > 0
        ? '$onlineCount/$totalCount'
        : '$totalCount';

    final metrics = [
      (speed != null ? '${speed.round()}' : '—', 'KM/H'),
      (dist.toStringAsFixed(1), 'KM'),
      (ridersLabel, 'RIDERS'),
      (sala.tiempo, 'TIEMPO'),
    ];

    return SizedBox(
      height: 64,
      child: Row(
        children: metrics.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: i < metrics.length - 1
                      ? const BorderSide(
                          color: Color(0x1AFFFFFF), width: 1)
                      : BorderSide.none,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    m.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Courier',
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.$2,
                    style: const TextStyle(
                      color: _kSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Tabs row ─────────────────────────────────────────────────────────────────

class _TabsRow extends StatelessWidget {
  final SalaTab activeTab;
  final void Function(SalaTab) onTabTap;

  const _TabsRow({required this.activeTab, required this.onTabTap});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (SalaTab.mapa, 'Mapa'),
      (SalaTab.chat, 'Chat'),
      (SalaTab.voz, 'Voz'),
      (SalaTab.archivos, 'Archivos'),
    ];

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x12FFFFFF), width: 1),
        ),
      ),
      child: Row(
        children: tabs.map((t) {
          final isActive = activeTab == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabTap(t.$1),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: isActive
                        ? const BorderSide(
                            color: Colors.white, width: 2)
                        : BorderSide.none,
                  ),
                ),
                child: Text(
                  t.$2,
                  style: TextStyle(
                    color: isActive ? Colors.white : _kSecondary,
                    fontSize: 13,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Tab content dispatcher ───────────────────────────────────────────────────

class _TabContent extends StatelessWidget {
  final SalaState sala;
  final SalaNotifier notifier;
  final AnimationController pulseCtrl;

  const _TabContent({
    required this.sala,
    required this.notifier,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    switch (sala.activeTab) {
      case SalaTab.voz:
      case SalaTab.mapa:
        return _VozContent(sala: sala, notifier: notifier, pulseCtrl: pulseCtrl);
      case SalaTab.chat:
        return _ChatContent(sala: sala, notifier: notifier);
      case SalaTab.archivos:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ArchivosTab(
            fotos: sala.fotos,
            onUploadFoto: notifier.uploadSalaFoto,
          ),
        );
    }
  }
}

// ─── Voz content ─────────────────────────────────────────────────────────────

class _VozContent extends StatelessWidget {
  final SalaState sala;
  final SalaNotifier notifier;
  final AnimationController pulseCtrl;

  const _VozContent({
    required this.sala,
    required this.notifier,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Columna izquierda: canales ──────────────────────────────────
          SizedBox(
            width: 110,
            child: _ChannelPillsVertical(activeChannel: 'General'),
          ),
          // ── Centro: botón PTT ───────────────────────────────────────────
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PttButton(
                  isActive: sala.isPttActive,
                  activeSpeakerName: sala.activeSpeakerName,
                  pulseCtrl: pulseCtrl,
                  onDown: () => notifier.setPtt(true),
                  onUp: () => notifier.setPtt(false),
                ),
                const SizedBox(height: 6),
                Text(
                  sala.activeSpeakerName != null
                      ? sala.activeSpeakerName!
                      : 'Mantén para hablar',
                  style: TextStyle(
                    color: sala.activeSpeakerName != null
                        ? Colors.white
                        : _kSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // ── Columna derecha: riders ─────────────────────────────────────
          SizedBox(
            width: 44,
            child: _RidersColVoz(
              riders: sala.riders,
              onlineRiderIds: sala.onlineRiderIds,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Channel pills verticales ─────────────────────────────────────────────────

class _ChannelPillsVertical extends StatelessWidget {
  final String activeChannel;
  const _ChannelPillsVertical({required this.activeChannel});

  @override
  Widget build(BuildContext context) {
    const channels = ['General', 'Líderes', 'Emergencia'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: channels.map((ch) {
        final isActive = ch == activeChannel;
        return GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? Noray4Colors.darkAccent
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isActive
                    ? Noray4Colors.darkAccent
                    : Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ch,
                  style: TextStyle(
                    color: isActive ? const Color(0xFF0C1C20) : _kSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 4),
                  Text(
                    '✓',
                    style: const TextStyle(
                      color: Color(0xFF0C1C20),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── PTT Button ───────────────────────────────────────────────────────────────

class _PttButton extends StatefulWidget {
  final bool isActive;
  final String? activeSpeakerName;
  final AnimationController pulseCtrl;
  final VoidCallback onDown;
  final VoidCallback onUp;

  const _PttButton({
    required this.isActive,
    required this.activeSpeakerName,
    required this.pulseCtrl,
    required this.onDown,
    required this.onUp,
  });

  @override
  State<_PttButton> createState() => _PttButtonState();
}

class _PttButtonState extends State<_PttButton> {
  bool _isPressed = false;

  void _handleDown(PointerDownEvent _) {
    setState(() => _isPressed = true);
    widget.onDown();
  }

  void _handleUp(PointerEvent _) {
    setState(() => _isPressed = false);
    widget.onUp();
  }

  Widget _ring(double t) {
    final scale = 1.0 + t * 0.8;
    final opacity = (1.0 - t) * 0.25;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _kAccentRed.withValues(alpha: opacity),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Muestra estado activo inmediatamente al presionar (no espera confirmación del servidor)
    final showing = _isPressed || widget.isActive;

    return Listener(
      onPointerDown: _handleDown,
      onPointerUp: _handleUp,
      onPointerCancel: _handleUp,
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedBuilder(
          animation: widget.pulseCtrl,
          builder: (ctx, _) {
            final t1 = widget.pulseCtrl.value;
            final t2 = (widget.pulseCtrl.value + 0.5) % 1.0;

            return SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (showing) ...[_ring(t1), _ring(t2)],
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: showing ? 80 : 72,
                    height: showing ? 80 : 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: showing
                          ? _kAccentRed
                          : Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: showing
                            ? _kAccentRed
                            : Colors.white.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          showing
                              ? RemixIcons.mic_fill
                              : RemixIcons.mic_line,
                          size: 28,
                          color: Colors.white,
                        ),
                        if (showing) ...[
                          const SizedBox(height: 2),
                          const Text(
                            '● ●',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Riders column (Voz tab) ──────────────────────────────────────────────────

class _RidersColVoz extends StatelessWidget {
  final List<SalaRider> riders;
  final Set<String> onlineRiderIds;
  const _RidersColVoz({required this.riders, required this.onlineRiderIds});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: riders.take(5).map((rider) {
        final color = rider.riderId != null
            ? riderColor(rider.riderId!)
            : _kSecondary;
        final isOnline =
            rider.riderId != null && onlineRiderIds.contains(rider.riderId);
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isOnline ? color : color.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(1.5),
          child: Opacity(
            opacity: isOnline ? 1.0 : 0.6,
            child: RiderAvatarCircle(
              riderId: rider.riderId,
              initials: rider.initials,
              size: 30,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Chat content ─────────────────────────────────────────────────────────────

class _ChatContent extends StatefulWidget {
  final SalaState sala;
  final SalaNotifier notifier;

  const _ChatContent({required this.sala, required this.notifier});

  @override
  State<_ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<_ChatContent> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ChatContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sala.messages.length != widget.sala.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            reverse: true,
            itemCount: widget.sala.messages.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: Noray4Spacing.s4),
            itemBuilder: (_, i) {
              final msgs = widget.sala.messages.reversed.toList();
              return ChatBubble(
                message: msgs[i],
                onDelete: widget.notifier.deleteMessage,
                onEdit: widget.notifier.editMessage,
              );
            },
          ),
        ),
        ChatInputBar(
          onSend: widget.notifier.sendMessage,
          onSendImage: widget.notifier.sendImage,
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Cerrar Salida Sheet ──────────────────────────────────────────────────────

class _CerrarSalidaSheet extends StatelessWidget {
  const _CerrarSalidaSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top:
              BorderSide(color: Noray4Colors.darkOutlineVariant, width: 0.5),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Noray4Colors.darkSurfaceContainerHighest,
              borderRadius: Noray4Radius.secondary,
              border: Border.all(
                  color: Noray4Colors.darkOutlineVariant, width: 0.5),
            ),
            child: const Icon(RemixIcons.flag_line,
                size: 22, color: Noray4Colors.darkPrimary),
          ),
          const SizedBox(height: Noray4Spacing.s4),
          Text(
            '¿Cerrar esta salida?',
            style: Noray4TextStyles.headlineM.copyWith(
              color: Noray4Colors.darkPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Noray4Spacing.s2),
          Text(
            'Se generará un registro con el recorrido de hoy.',
            style: Noray4TextStyles.body.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Noray4Spacing.s8),
          _SheetButton(
            label: 'Cerrar y guardar registro',
            primary: true,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: Noray4Spacing.s2),
          _SheetButton(
            label: 'Seguir rodando',
            primary: false,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatefulWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _SheetButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  State<_SheetButton> createState() => _SheetButtonState();
}

class _SheetButtonState extends State<_SheetButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: widget.primary
                ? Noray4Colors.darkPrimary
                : Colors.transparent,
            borderRadius: Noray4Radius.primary,
            border: widget.primary
                ? null
                : Border.all(
                    color: Noray4Colors.darkOutlineVariant, width: 0.5),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: Noray4TextStyles.body.copyWith(
                color: widget.primary
                    ? Noray4Colors.darkBackground
                    : Noray4Colors.darkSecondary,
                fontWeight: widget.primary
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
