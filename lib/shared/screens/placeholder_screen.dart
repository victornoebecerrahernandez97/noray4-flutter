import 'package:flutter/material.dart';
import 'package:noray4/core/theme/noray4_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  final String label;
  final int icon;

  const PlaceholderScreen({
    super.key,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Noray4Colors.darkBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconData(icon, fontFamily: 'MaterialSymbolsOutlined'),
              size: 40,
              color: Noray4Colors.darkOnSurfaceVariant,
            ),
            const SizedBox(height: Noray4Spacing.s4),
            Text(
              label,
              style: Noray4TextStyles.headlineM.copyWith(
                color: Noray4Colors.darkOnSurfaceVariant,
              ),
            ),
            const SizedBox(height: Noray4Spacing.s2),
            Text(
              'Próximamente',
              style: Noray4TextStyles.body.copyWith(
                color: Noray4Colors.darkOnSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
