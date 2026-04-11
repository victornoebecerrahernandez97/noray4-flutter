import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/rutas/models/rutas_models.dart';
import 'package:noray4/features/rutas/providers/rutas_provider.dart';
import 'package:noray4/features/rutas/widgets/ruta_explore_card.dart';

class RutasScreen extends ConsumerWidget {
  const RutasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rutasProvider);

    return Scaffold(
      backgroundColor: Noray4Colors.darkBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RutasAppBar(),
          _SearchBar(
            onChanged: (q) => ref.read(rutasProvider.notifier).setQuery(q),
          ),
          _FiltroChips(
            active: state.filtroActivo,
            onSelected: (f) => ref.read(rutasProvider.notifier).setFiltro(f),
          ),
          Expanded(
            child: state.rutasFiltradas.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Noray4Spacing.s6,
                      Noray4Spacing.s4,
                      Noray4Spacing.s6,
                      Noray4Spacing.s8 * 3,
                    ),
                    itemCount: state.rutasFiltradas.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: Noray4Spacing.s8),
                    itemBuilder: (context, i) {
                      final ruta = state.rutasFiltradas[i];
                      return RutaExploreCard(
                        ruta: ruta,
                        onToggleFavorita: () => ref
                            .read(rutasProvider.notifier)
                            .toggleFavorita(ruta.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RutasAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        color: Noray4Colors.darkBackground,
        padding: const EdgeInsets.symmetric(horizontal: Noray4Spacing.s6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rutas',
              style: Noray4TextStyles.headlineL.copyWith(
                color: Noray4Colors.darkPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.04 * 24,
              ),
            ),
            const Icon(Symbols.tune, size: 22, color: Noray4Colors.darkSecondary),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Noray4Spacing.s6,
        vertical: Noray4Spacing.s2,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Noray4Spacing.s4,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Noray4Colors.darkSurfaceContainerLow,
          borderRadius: Noray4Radius.secondary,
          border: Border.all(
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(Symbols.search, size: 18,
                color: Color(0xFF919191)),
            const SizedBox(width: Noray4Spacing.s2),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                style: Noray4TextStyles.body.copyWith(
                  color: Noray4Colors.darkPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar ruta o zona...',
                  hintStyle: Noray4TextStyles.body.copyWith(
                    color: Noray4Colors.darkOnSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltroChips extends StatelessWidget {
  final RutaFiltro active;
  final ValueChanged<RutaFiltro> onSelected;

  const _FiltroChips({required this.active, required this.onSelected});

  static const _filtros = [
    (filtro: RutaFiltro.todas, label: 'Todas', icon: Symbols.route),
    (filtro: RutaFiltro.cercanas, label: 'Cercanas', icon: Symbols.near_me),
    (filtro: RutaFiltro.populares, label: 'Populares', icon: Symbols.trending_up),
    (filtro: RutaFiltro.recientes, label: 'Recientes', icon: Symbols.schedule),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Noray4Spacing.s6),
        itemCount: _filtros.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = _filtros[i];
          return _FilterBadge(
            label: item.label,
            icon: item.icon,
            isActive: item.filtro == active,
            onTap: () => onSelected(item.filtro),
          );
        },
      ),
    );
  }
}

class _FilterBadge extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterBadge({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_FilterBadge> createState() => _FilterBadgeState();
}

class _FilterBadgeState extends State<_FilterBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      value: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_FilterBadge old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _scaleCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isActive ? Noray4Colors.darkPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? Noray4Colors.darkPrimary
                  : Noray4Colors.darkOutlineVariant.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: isActive
                    ? const Color(0xFF111110)
                    : Noray4Colors.darkOnSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ).copyWith(
                  color: isActive
                      ? const Color(0xFF111110)
                      : Noray4Colors.darkOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.search_off, size: 40,
              color: Color(0xFF474747)),
          const SizedBox(height: Noray4Spacing.s4),
          Text(
            'Sin resultados',
            style: Noray4TextStyles.headlineM.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
