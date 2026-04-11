import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/perfil/models/perfil_models.dart';

class MotoCard extends StatelessWidget {
  final MotoInfo moto;
  const MotoCard({super.key, required this.moto});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainer,
        borderRadius: Noray4Radius.primary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen placeholder
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.33, 0.59, 0.11, 0, -10,
                0.33, 0.59, 0.11, 0, -10,
                0.33, 0.59, 0.11, 0, -10,
                0,    0,    0,    0.8, 0,
              ]),
              child: Container(
                height: 160,
                color: Noray4Colors.darkSurfaceContainerHigh,
                child: const Center(
                  child: Icon(
                    Symbols.two_wheeler,
                    size: 56,
                    color: Color(0xFF474747),
                  ),
                ),
              ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(Noray4Spacing.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moto.nombre,
                  style: Noray4TextStyles.headlineM.copyWith(
                    color: Noray4Colors.darkPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  moto.tipo,
                  style: Noray4TextStyles.body.copyWith(
                    color: Noray4Colors.darkSecondary,
                  ),
                ),
                const SizedBox(height: Noray4Spacing.s4),
                Container(
                  height: 0.5,
                  color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.1),
                ),
                const SizedBox(height: Noray4Spacing.s4),
                Row(
                  children: [
                    const Icon(
                      Symbols.speed,
                      size: 16,
                      color: Color(0xFF474747),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatKm(moto.kmAcumulados)} km acumulados',
                      style: Noray4TextStyles.body.copyWith(
                        color: Noray4Colors.darkOnSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatKm(int km) {
    if (km >= 1000) {
      return '${(km / 1000).toStringAsFixed(1)}k'
          .replaceAll('.0k', 'k');
    }
    return '$km';
  }
}
