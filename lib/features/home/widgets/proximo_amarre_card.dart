import 'package:flutter/material.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/home/models/home_models.dart';

class ProximoAmareCard extends StatelessWidget {
  final ProximoAmarre amarre;
  final VoidCallback? onTap;

  const ProximoAmareCard({super.key, required this.amarre, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Noray4Spacing.s4 + 4),
        decoration: BoxDecoration(
          color: Noray4Colors.darkSurfaceContainer,
          borderRadius: Noray4Radius.primary,
          border: Border.all(
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            _DateBadge(dia: amarre.dia, diaSemana: amarre.diaSemana),
            const SizedBox(width: Noray4Spacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    amarre.nombre,
                    style: Noray4TextStyles.headlineM.copyWith(
                      color: Noray4Colors.darkPrimary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Punto de reunión: ${amarre.puntoReunion}',
                    style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Noray4Spacing.s2),
            _StatusPill(status: amarre.status),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final int dia;
  final String diaSemana;
  const _DateBadge({required this.dia, required this.diaSemana});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerHighest,
        borderRadius: Noray4Radius.secondary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant,
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            diaSemana.toUpperCase(),
            style: Noray4TextStyles.label.copyWith(
              fontSize: 9,
              color: Noray4Colors.darkSecondary,
            ),
          ),
          Text(
            '$dia',
            style: Noray4TextStyles.headlineM.copyWith(
              color: Noray4Colors.darkPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: Noray4Radius.pill,
        border: Border.all(color: Noray4Colors.darkPrimary, width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: Noray4TextStyles.label.copyWith(
          color: Noray4Colors.darkPrimary,
          fontSize: 10,
        ),
      ),
    );
  }
}
