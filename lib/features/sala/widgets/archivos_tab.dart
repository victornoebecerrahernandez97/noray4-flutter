import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';

// ─── Modelo local ─────────────────────────────────────────────────────────────

class ArchivoItem {
  final String id;
  final String nombre;
  final String tipo; // 'pdf' | 'imagen' | 'enlace' | 'coordenada'
  final String meta;
  final String riderNombre;
  final DateTime subidoEn;

  const ArchivoItem({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.meta,
    required this.riderNombre,
    required this.subidoEn,
  });
}

// ─── Mock data ────────────────────────────────────────────────────────────────

final _now = DateTime.now();

final _mockArchivos = [
  ArchivoItem(
    id: '1',
    nombre: 'Ruta Pirineos 2026.pdf',
    tipo: 'pdf',
    meta: '2.4 MB',
    riderNombre: 'Marcos',
    subidoEn: _now.subtract(const Duration(minutes: 20)),
  ),
  ArchivoItem(
    id: '2',
    nombre: 'Foto en el puerto de montaña',
    tipo: 'imagen',
    meta: '1.1 MB',
    riderNombre: 'Sara',
    subidoEn: _now.subtract(const Duration(hours: 1, minutes: 10)),
  ),
  ArchivoItem(
    id: '3',
    nombre: 'Parada recomendada — La Venta',
    tipo: 'enlace',
    meta: 'maps.google.com',
    riderNombre: 'Tú',
    subidoEn: _now.subtract(const Duration(hours: 2, minutes: 45)),
  ),
  ArchivoItem(
    id: '4',
    nombre: 'Paisaje desde el mirador',
    tipo: 'imagen',
    meta: '870 KB',
    riderNombre: 'Dani',
    subidoEn: _now.subtract(const Duration(hours: 3)),
  ),
  ArchivoItem(
    id: '5',
    nombre: 'Punto de encuentro',
    tipo: 'coordenada',
    meta: '42°19\'14"N 1°59\'02"E',
    riderNombre: 'Marcos',
    subidoEn: _now.subtract(const Duration(hours: 5, minutes: 30)),
  ),
];

// ─── Helpers ──────────────────────────────────────────────────────────────────

IconData _iconForTipo(String tipo) {
  switch (tipo) {
    case 'pdf':
      return Symbols.picture_as_pdf;
    case 'imagen':
      return Symbols.image;
    case 'enlace':
      return Symbols.link;
    case 'coordenada':
      return Symbols.location_on;
    default:
      return Symbols.insert_drive_file;
  }
}

String _horaRelativa(DateTime subidoEn) {
  final diff = DateTime.now().difference(subidoEn);
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
  if (diff.inHours < 24) return 'hace ${diff.inHours}h';
  return 'hace ${diff.inDays}d';
}

// ─── Widget principal ─────────────────────────────────────────────────────────

class ArchivosTab extends StatelessWidget {
  final List<ArchivoItem>? archivos;

  const ArchivosTab({super.key, this.archivos});

  @override
  Widget build(BuildContext context) {
    final items = archivos ?? _mockArchivos;
    if (items.isEmpty) return const _EmptyState();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: Noray4Spacing.s4,
        vertical: Noray4Spacing.s4,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: Noray4Spacing.s2),
      itemBuilder: (context, i) => _ArchivoTile(item: items[i]),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _ArchivoTile extends StatelessWidget {
  final ArchivoItem item;
  const _ArchivoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBottomSheet(context, item),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Noray4Spacing.s4,
          vertical: Noray4Spacing.s4,
        ),
        decoration: BoxDecoration(
          color: Noray4Colors.darkSurfaceContainerLowest,
          borderRadius: Noray4Radius.primary,
          border: Border.all(
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Icono tipo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Noray4Colors.darkSurfaceContainerHigh,
                borderRadius: Noray4Radius.secondary,
              ),
              child: Icon(
                _iconForTipo(item.tipo),
                size: 20,
                color: Noray4Colors.darkOnSurfaceVariant,
              ),
            ),
            const SizedBox(width: Noray4Spacing.s4),
            // Nombre + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkOnSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.meta} · ${item.riderNombre}',
                    style: Noray4TextStyles.bodySmall.copyWith(
                      color: Noray4Colors.darkOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Noray4Spacing.s2),
            // Hora relativa
            Text(
              _horaRelativa(item.subidoEn),
              style: Noray4TextStyles.bodySmall.copyWith(
                color: Noray4Colors.darkOutline,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom sheet ─────────────────────────────────────────────────────────────

void _showBottomSheet(BuildContext context, ArchivoItem item) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Noray4Colors.darkSurfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (_) => _ArchivoSheet(item: item),
  );
}

class _ArchivoSheet extends StatelessWidget {
  final ArchivoItem item;
  const _ArchivoSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Noray4Spacing.s6,
          Noray4Spacing.s4,
          Noray4Spacing.s6,
          Noray4Spacing.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Noray4Colors.darkOutlineVariant,
                  borderRadius: Noray4Radius.pill,
                ),
              ),
            ),
            const SizedBox(height: Noray4Spacing.s6),
            // Icono + nombre
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Noray4Colors.darkSurfaceContainerHigh,
                    borderRadius: Noray4Radius.secondary,
                  ),
                  child: Icon(
                    _iconForTipo(item.tipo),
                    size: 24,
                    color: Noray4Colors.darkOnSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Noray4Spacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombre,
                        style: Noray4TextStyles.headlineM.copyWith(
                          color: Noray4Colors.darkPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.tipo.toUpperCase(),
                        style: Noray4TextStyles.label.copyWith(
                          color: Noray4Colors.darkOutline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Noray4Spacing.s8),
            // Botón Abrir
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Noray4Colors.darkPrimary,
                  borderRadius: Noray4Radius.primary,
                ),
                child: Center(
                  child: Text(
                    'Abrir',
                    style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkBackground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Symbols.folder_open,
            size: 40,
            color: Noray4Colors.darkOutlineVariant,
          ),
          const SizedBox(height: Noray4Spacing.s4),
          Text(
            'Sin archivos compartidos',
            style: Noray4TextStyles.body.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
