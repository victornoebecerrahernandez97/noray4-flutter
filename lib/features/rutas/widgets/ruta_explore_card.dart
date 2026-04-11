import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/rutas/models/rutas_models.dart';

class RutaExploreCard extends StatelessWidget {
  final Ruta ruta;
  final VoidCallback onToggleFavorita;
  final VoidCallback? onTap;

  const RutaExploreCard({
    super.key,
    required this.ruta,
    required this.onToggleFavorita,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardImage(ruta: ruta, onToggleFavorita: onToggleFavorita),
          const SizedBox(height: 12),
          _CardMeta(ruta: ruta),
        ],
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final Ruta ruta;
  final VoidCallback onToggleFavorita;
  const _CardImage({required this.ruta, required this.onToggleFavorita});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 21 / 9,
      child: ClipRRect(
        borderRadius: Noray4Radius.primary,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.33, 0.59, 0.11, 0, -20,
                0.33, 0.59, 0.11, 0, -20,
                0.33, 0.59, 0.11, 0, -20,
                0,    0,    0,    1,  0,
              ]),
              child: Container(color: Noray4Colors.darkSurfaceContainer),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.2),
                  width: 0.5,
                ),
                borderRadius: Noray4Radius.primary,
              ),
            ),
            Positioned(
              bottom: 10,
              left: 12,
              child: _DificultadPill(dificultad: ruta.dificultadLabel),
            ),
            Positioned(
              bottom: 10,
              right: 12,
              child: GestureDetector(
                onTap: onToggleFavorita,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Noray4Colors.darkBackground.withValues(alpha: 0.8),
                    borderRadius: Noray4Radius.secondary,
                    border: Border.all(
                      color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    Symbols.favorite,
                    fill: ruta.isFavorita ? 1 : 0,
                    size: 18,
                    color: Noray4Colors.darkPrimary,
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

class _DificultadPill extends StatelessWidget {
  final String dificultad;
  const _DificultadPill({required this.dificultad});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Noray4Colors.darkBackground.withValues(alpha: 0.8),
        borderRadius: Noray4Radius.pill,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Text(
        dificultad.toUpperCase(),
        style: Noray4TextStyles.label.copyWith(
          fontSize: 9,
          color: Noray4Colors.darkOnSurfaceVariant,
        ),
      ),
    );
  }
}

class _CardMeta extends StatelessWidget {
  final Ruta ruta;
  const _CardMeta({required this.ruta});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ruta.nombre,
                style: Noray4TextStyles.headlineM.copyWith(
                  color: Noray4Colors.darkPrimary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(ruta.autor,
                      style: Noray4TextStyles.body
                          .copyWith(color: Noray4Colors.darkOnSurface)),
                  _dot(),
                  Text('${ruta.km} km',
                      style: Noray4TextStyles.body
                          .copyWith(color: Noray4Colors.darkSecondary)),
                  _dot(),
                  Text(ruta.duracion,
                      style: Noray4TextStyles.body
                          .copyWith(color: Noray4Colors.darkSecondary)),
                  _dot(),
                  const Icon(Symbols.person, size: 12,
                      color: Color(0xFFC7C7C2)),
                  const SizedBox(width: 2),
                  Text('${ruta.participantes}',
                      style: Noray4TextStyles.body
                          .copyWith(color: Noray4Colors.darkSecondary)),
                ],
              ),
            ],
          ),
        ),
        const Icon(Symbols.more_vert, size: 20, color: Color(0xFFC7C7C2)),
      ],
    );
  }

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text('·',
            style: Noray4TextStyles.body
                .copyWith(color: Noray4Colors.darkSecondary)),
      );
}
