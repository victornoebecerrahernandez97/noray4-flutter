import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  static const _items = [
    _Notif(
      icon: Symbols.directions_bike,
      titulo: 'Nueva salida cerca',
      descripcion: 'RiderMX convocó una salida en tu zona',
      tiempo: 'Hace 5 min',
      leida: false,
    ),
    _Notif(
      icon: Symbols.group,
      titulo: 'Te unieron a una tripulación',
      descripcion: 'Fuiste agregado a Lobos del Asfalto',
      tiempo: 'Hace 1h',
      leida: false,
    ),
    _Notif(
      icon: Symbols.flag,
      titulo: 'Salida completada',
      descripcion: 'Tu registro de hoy está listo',
      tiempo: 'Hace 3h',
      leida: true,
    ),
    _Notif(
      icon: Symbols.star,
      titulo: 'Ruta destacada',
      descripcion: 'Tu ruta fue marcada como favorita 12 veces',
      tiempo: 'Ayer',
      leida: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Noray4Colors.darkBackground,
      body: Column(
        children: [
          _AppBar(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: Noray4Spacing.s6,
                vertical: Noray4Spacing.s4,
              ),
              itemCount: _items.length,
              separatorBuilder: (_, _) => Container(
                height: 0.5,
                margin: const EdgeInsets.symmetric(vertical: Noray4Spacing.s2),
                color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.2),
              ),
              itemBuilder: (_, i) => _NotifTile(item: _items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ─────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        color: Noray4Colors.darkBackground,
        padding: const EdgeInsets.symmetric(horizontal: Noray4Spacing.s6),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(
                Symbols.arrow_back,
                size: 24,
                color: Noray4Colors.darkPrimary,
              ),
            ),
            const SizedBox(width: Noray4Spacing.s4),
            Text(
              'Notificaciones',
              style: Noray4TextStyles.wordmark.copyWith(
                color: Noray4Colors.darkPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.04 * 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final _Notif item;
  const _NotifTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Noray4Spacing.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono en círculo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Noray4Colors.darkSurfaceContainerHigh,
              borderRadius: Noray4Radius.pill,
              border: Border.all(
                color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: item.leida
                  ? Noray4Colors.darkOnSurfaceVariant
                  : Noray4Colors.darkPrimary,
            ),
          ),
          const SizedBox(width: Noray4Spacing.s4),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.titulo,
                      style: Noray4TextStyles.body.copyWith(
                        color: item.leida
                            ? Noray4Colors.darkOnSurfaceVariant
                            : Noray4Colors.darkPrimary,
                        fontWeight:
                            item.leida ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                    if (!item.leida)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Noray4Colors.darkPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.descripcion,
                  style: Noray4TextStyles.bodySmall.copyWith(
                    color: Noray4Colors.darkOnSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.tiempo,
                  style: Noray4TextStyles.label.copyWith(
                    color: Noray4Colors.darkOutline,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────

class _Notif {
  final IconData icon;
  final String titulo;
  final String descripcion;
  final String tiempo;
  final bool leida;

  const _Notif({
    required this.icon,
    required this.titulo,
    required this.descripcion,
    required this.tiempo,
    required this.leida,
  });
}
