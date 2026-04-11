import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';

class N4BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const N4BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Symbols.home, label: 'INICIO'),
    _NavItem(icon: Symbols.explore, label: 'SALIDAS'),
    _NavItem(icon: Symbols.book_2, label: 'REGISTROS'),
    _NavItem(icon: Symbols.person, label: 'PERFIL'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xCC111110),
            border: Border(
              top: BorderSide(color: Color(0xFF262624), width: 0.5),
            ),
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedScale(
                    scale: active ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _items[i].icon,
                          fill: active ? 1 : 0,
                          size: 24,
                          color: active
                              ? Noray4Colors.darkPrimary
                              : Noray4Colors.darkSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _items[i].label,
                          style: Noray4TextStyles.label.copyWith(
                            fontSize: 9,
                            color: active
                                ? Noray4Colors.darkPrimary
                                : Noray4Colors.darkSecondary,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
