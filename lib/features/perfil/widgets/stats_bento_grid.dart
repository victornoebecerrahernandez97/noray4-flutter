import 'package:flutter/material.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/perfil/models/perfil_models.dart';

class StatsBentoGrid extends StatelessWidget {
  final List<PerfilStat> stats;

  const StatsBentoGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats
          .map((s) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: Noray4Spacing.s2 + 4),
                  child: _StatCell(stat: s),
                ),
              ))
          .toList(),
    );
  }
}

class _StatCell extends StatelessWidget {
  final PerfilStat stat;
  const _StatCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(Noray4Spacing.s4),
        decoration: BoxDecoration(
          color: Noray4Colors.darkSurfaceContainerLow,
          borderRadius: Noray4Radius.primary,
          border: Border.all(
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: Text(
                    stat.valor,
                    maxLines: 1,
                    style: Noray4TextStyles.headlineL.copyWith(
                      color: Noray4Colors.darkPrimary,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.03 * 32,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              stat.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Noray4TextStyles.label.copyWith(
                color: Noray4Colors.darkSecondary,
                fontSize: 9,
                letterSpacing: 0.2 * 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
