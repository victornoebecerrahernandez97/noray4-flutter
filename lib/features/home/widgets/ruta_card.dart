import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/home/models/home_models.dart';

class RutaCard extends StatelessWidget {
  final RutaComunidad ruta;
  final VoidCallback onToggleFavorita;

  const RutaCard({
    super.key,
    required this.ruta,
    required this.onToggleFavorita,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RutaImage(ruta: ruta, onToggleFavorita: onToggleFavorita),
        const SizedBox(height: 12),
        _RutaMeta(ruta: ruta),
      ],
    );
  }
}

class _RutaImage extends StatelessWidget {
  final RutaComunidad ruta;
  final VoidCallback onToggleFavorita;
  const _RutaImage({required this.ruta, required this.onToggleFavorita});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 21 / 9,
      child: ClipRRect(
        borderRadius: Noray4Radius.primary,
        child: Container(
          decoration: BoxDecoration(
            color: Noray4Colors.darkSurfaceContainerLow,
            border: Border.all(
              color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.2),
              width: 0.5,
            ),
            borderRadius: Noray4Radius.primary,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Placeholder imagen (grayscale)
              ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.33, 0.59, 0.11, 0, -20,
                  0.33, 0.59, 0.11, 0, -20,
                  0.33, 0.59, 0.11, 0, -20,
                  0,    0,    0,    1, 0,
                ]),
                child: Container(color: Noray4Colors.darkSurfaceContainer),
              ),
              // Botón favorita
              Positioned(
                bottom: 12,
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
                      ruta.isFavorita ? Symbols.favorite : Symbols.favorite,
                      fill: ruta.isFavorita ? 1 : 0,
                      size: 20,
                      color: Noray4Colors.darkPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RutaMeta extends StatelessWidget {
  final RutaComunidad ruta;
  const _RutaMeta({required this.ruta});

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
                  Text(
                    ruta.autor,
                    style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkOnSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('·',
                        style: Noray4TextStyles.body.copyWith(
                            color: Noray4Colors.darkSecondary)),
                  ),
                  Text('${ruta.km} km',
                      style: Noray4TextStyles.body
                          .copyWith(color: Noray4Colors.darkSecondary)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('·',
                        style: Noray4TextStyles.body.copyWith(
                            color: Noray4Colors.darkSecondary)),
                  ),
                  Text(ruta.hace,
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
}
