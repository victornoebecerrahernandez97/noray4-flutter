import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';

class PerfilMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool showTopDivider;

  const PerfilMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.showTopDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTopDivider) ...[
          const SizedBox(height: Noray4Spacing.s4),
          Container(
            height: 0.5,
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.1),
          ),
          const SizedBox(height: Noray4Spacing.s4),
        ],
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Noray4Spacing.s4),
            decoration: BoxDecoration(
              color: Noray4Colors.darkSurfaceContainerLowest,
              borderRadius: Noray4Radius.secondary,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: Noray4Colors.darkSecondary,
                ),
                const SizedBox(width: Noray4Spacing.s4),
                Expanded(
                  child: Text(
                    label,
                    style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkOnSurface,
                    ),
                  ),
                ),
                const Icon(
                  Symbols.chevron_right,
                  size: 18,
                  color: Color(0xFF474747),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
