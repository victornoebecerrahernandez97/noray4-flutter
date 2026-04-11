import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/services/haptics.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/amarres/models/amarres_models.dart';
import 'package:noray4/features/amarres/providers/amarres_provider.dart';

class AmarreCard extends ConsumerWidget {
  final Amarre amarre;

  const AmarreCard({super.key, required this.amarre});

  Future<void> _clonar(BuildContext context, WidgetRef ref) async {
    final clon = Amarre(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: 'Copia — ${amarre.nombre}',
      fecha: DateTime.now(),
      km: amarre.km,
      duracion: amarre.duracion,
      participantes: amarre.participantes,
      zona: amarre.zona,
    );
    ref.read(amarresProvider.notifier).addAmarre(clon);
    await N4Haptics.medium();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ruta clonada en tus registros',
          style: Noray4TextStyles.body.copyWith(
            color: Noray4Colors.darkPrimary,
          ),
        ),
        backgroundColor: Noray4Colors.darkSurfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: Noray4Radius.secondary,
          side: const BorderSide(
            color: Noray4Colors.darkOutlineVariant,
            width: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/amarres/detalle', extra: amarre),
      child: Container(
        decoration: BoxDecoration(
          color: Noray4Colors.darkSurfaceContainerLowest,
          borderRadius: Noray4Radius.primary,
          border: Border.all(
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.15),
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
              child: AspectRatio(
                aspectRatio: 21 / 9,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0.33, 0.59, 0.11, 0, -25,
                    0.33, 0.59, 0.11, 0, -25,
                    0.33, 0.59, 0.11, 0, -25,
                    0,    0,    0,    1,   0,
                  ]),
                  child: Container(
                    color: Noray4Colors.darkSurfaceContainer,
                    child: const Center(
                      child: Icon(
                        Symbols.route,
                        size: 36,
                        color: Color(0xFF474747),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Metadata
            Padding(
              padding: const EdgeInsets.all(Noray4Spacing.s4 + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        amarre.fechaFormateada.toUpperCase(),
                        style: Noray4TextStyles.label.copyWith(
                          color: Noray4Colors.darkSecondary,
                          fontSize: 9,
                          letterSpacing: 0.08 * 9,
                        ),
                      ),
                      Text(
                        amarre.zona,
                        style: Noray4TextStyles.label.copyWith(
                          color: Noray4Colors.darkOnSurfaceVariant,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Noray4Spacing.s2),
                  Text(
                    amarre.nombre,
                    style: Noray4TextStyles.headlineM.copyWith(
                      color: Noray4Colors.darkPrimary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: Noray4Spacing.s4),
                  // Stats + botón clonar
                  Row(
                    children: [
                      _Stat(icon: Symbols.route, value: '${amarre.km} km'),
                      const SizedBox(width: Noray4Spacing.s6),
                      _Stat(icon: Symbols.schedule, value: amarre.duracion),
                      const SizedBox(width: Noray4Spacing.s6),
                      _Stat(
                        icon: Symbols.group,
                        value: '${amarre.participantes.length}',
                      ),
                      const Spacer(),
                      // Botón clonar
                      GestureDetector(
                        onTap: () => _clonar(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Noray4Colors.darkSurfaceContainerHigh,
                            borderRadius: Noray4Radius.secondary,
                            border: Border.all(
                              color: Noray4Colors.darkOutlineVariant
                                  .withValues(alpha: 0.4),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Symbols.copy_all,
                                size: 13,
                                color: Noray4Colors.darkSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Clonar',
                                style: Noray4TextStyles.label.copyWith(
                                  color: Noray4Colors.darkSecondary,
                                  letterSpacing: 0,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  const _Stat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Noray4Colors.darkOnSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          value,
          style: Noray4TextStyles.bodySmall.copyWith(
            color: Noray4Colors.darkOnSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
