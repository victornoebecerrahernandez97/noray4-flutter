import 'package:flutter/material.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/sala/models/sala_models.dart';

class SalaTabBar extends StatelessWidget {
  final SalaTab activeTab;
  final ValueChanged<SalaTab> onTabSelected;

  const SalaTabBar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  static const _tabs = [
    (tab: SalaTab.mapa, label: 'Mapa'),
    (tab: SalaTab.chat, label: 'Chat'),
    (tab: SalaTab.voz, label: 'Voz'),
    (tab: SalaTab.archivos, label: 'Archivos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF262624), width: 0.5),
        ),
      ),
      child: Row(
        children: _tabs
            .map((item) => _Tab(
                  label: item.label,
                  isActive: item.tab == activeTab,
                  onTap: () => onTabSelected(item.tab),
                ))
            .toList(),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: Noray4Spacing.s8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive
                    ? Noray4Colors.darkPrimary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: Noray4TextStyles.label.copyWith(
              fontSize: 11,
              color: isActive
                  ? Noray4Colors.darkPrimary
                  : Noray4Colors.darkOnSurfaceVariant,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
