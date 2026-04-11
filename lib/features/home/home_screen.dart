import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/home/models/home_models.dart';
import 'package:noray4/features/home/providers/home_provider.dart';
import 'package:noray4/features/home/widgets/noray_activo_card.dart';
import 'package:noray4/features/home/widgets/proximo_amarre_card.dart';
import 'package:noray4/features/home/widgets/ruta_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchCtrl = TextEditingController();
  bool _searchActive = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchActive = !_searchActive;
      if (!_searchActive) {
        _searchQuery = '';
        _searchCtrl.clear();
      }
    });
  }

  List<RutaComunidad> _filtered(List<RutaComunidad> rutas) {
    if (_searchQuery.trim().isEmpty) return rutas;
    final q = _searchQuery.toLowerCase();
    return rutas.where((r) => r.nombre.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final rutas = _filtered(state.rutas);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Noray4Colors.darkBackground,
      drawer: _HomeDrawer(),
      floatingActionButton: _searchActive
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/salida/nueva'),
              backgroundColor: Noray4Colors.darkPrimary,
              foregroundColor: Noray4Colors.darkBackground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: Noray4Radius.primary),
              icon: const Icon(Symbols.anchor, size: 20),
              label: Text(
                'Convocar',
                style: Noray4TextStyles.body.copyWith(
                  color: Noray4Colors.darkBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          _HomeAppBar(
            searchActive: _searchActive,
            searchCtrl: _searchCtrl,
            onMenuTap: () => _scaffoldKey.currentState!.openDrawer(),
            onSearchToggle: _toggleSearch,
            onSearchChanged: (q) => setState(() => _searchQuery = q),
            onNotificationsTap: () => context.push('/notificaciones'),
          ),
          Expanded(
            child: _searchActive && rutas.isEmpty && _searchQuery.isNotEmpty
                ? _SearchEmpty(query: _searchQuery)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Noray4Spacing.s6,
                      Noray4Spacing.s4,
                      Noray4Spacing.s6,
                      Noray4Spacing.s8,
                    ),
                    children: [
                      if (!_searchActive && state.norayActivo != null) ...[
                        _SectionLabel(label: 'Salida en curso'),
                        const SizedBox(height: Noray4Spacing.s4),
                        NorayActivoCard(
                          noray: state.norayActivo!,
                          onTap: () => context
                              .push('/sala/${state.norayActivo!.id}'),
                        ),
                        const SizedBox(height: Noray4Spacing.s8 + 8),
                      ],
                      if (!_searchActive &&
                          state.proximosAmarres.isNotEmpty) ...[
                        _SectionLabel(label: 'Próximos registros'),
                        const SizedBox(height: Noray4Spacing.s4),
                        ...state.proximosAmarres.map((a) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: Noray4Spacing.s4),
                              child: ProximoAmareCard(amarre: a),
                            )),
                        const SizedBox(height: Noray4Spacing.s4),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionLabel(label: 'Rutas de la comunidad'),
                          if (!_searchActive)
                            const Icon(Symbols.tune,
                                size: 20, color: Noray4Colors.darkSecondary),
                        ],
                      ),
                      const SizedBox(height: Noray4Spacing.s6),
                      ...rutas.map((r) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: Noray4Spacing.s8),
                            child: RutaCard(
                              ruta: r,
                              onToggleFavorita: () => ref
                                  .read(homeProvider.notifier)
                                  .toggleFavorita(r.id),
                            ),
                          )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  final bool searchActive;
  final TextEditingController searchCtrl;
  final VoidCallback onMenuTap;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onNotificationsTap;

  const _HomeAppBar({
    required this.searchActive,
    required this.searchCtrl,
    required this.onMenuTap,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        color: Noray4Colors.darkBackground,
        padding: const EdgeInsets.symmetric(horizontal: Noray4Spacing.s6),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          firstCurve: Curves.easeInOut,
          secondCurve: Curves.easeInOut,
          sizeCurve: Curves.easeInOut,
          crossFadeState: searchActive
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onMenuTap,
                    child: const Icon(Symbols.menu,
                        size: 24, color: Noray4Colors.darkPrimary),
                  ),
                  const SizedBox(width: Noray4Spacing.s4),
                  Text(
                    'Noray⁴',
                    style: Noray4TextStyles.wordmark.copyWith(
                      color: Noray4Colors.darkPrimary,
                      fontSize: 18,
                      letterSpacing: -0.05 * 18,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onSearchToggle,
                    child: const Icon(Symbols.search,
                        size: 24, color: Noray4Colors.darkPrimary),
                  ),
                  const SizedBox(width: Noray4Spacing.s4),
                  GestureDetector(
                    onTap: onNotificationsTap,
                    child: const Icon(Symbols.notifications,
                        size: 24, color: Noray4Colors.darkPrimary),
                  ),
                ],
              ),
            ],
          ),
          secondChild: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Noray4Spacing.s4,
                  ),
                  decoration: BoxDecoration(
                    color: Noray4Colors.darkSurfaceContainerLow,
                    borderRadius: Noray4Radius.secondary,
                    border: Border.all(
                      color: Noray4Colors.darkOutlineVariant
                          .withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Symbols.search,
                          size: 16, color: Noray4Colors.darkOutline),
                      const SizedBox(width: Noray4Spacing.s2),
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          autofocus: true,
                          onChanged: onSearchChanged,
                          style: Noray4TextStyles.body.copyWith(
                            color: Noray4Colors.darkPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar ruta...',
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
              ),
              const SizedBox(width: Noray4Spacing.s4),
              GestureDetector(
                onTap: onSearchToggle,
                child: const Icon(Symbols.close,
                    size: 24, color: Noray4Colors.darkPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Drawer ───────────────────────────────────────────────────────────────────

class _HomeDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final nombre = user?.nombre ?? 'Rider';
    final ciudad = user?.ciudad ?? '';

    String initials(String n) {
      final parts = n.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'R';
    }

    void nav(String path, {bool replace = false}) {
      Navigator.of(context).pop();
      replace ? context.go(path) : context.push(path);
    }

    return Drawer(
      backgroundColor: const Color(0xFF0D0D0D),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Noray4Spacing.s6,
                Noray4Spacing.s6,
                Noray4Spacing.s6,
                Noray4Spacing.s4,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Noray4Colors.darkSurfaceContainerHighest,
                    child: Text(
                      initials(nombre),
                      style: Noray4TextStyles.headlineM.copyWith(
                        color: Noray4Colors.darkSecondary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: Noray4Spacing.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: Noray4TextStyles.body.copyWith(
                            color: Noray4Colors.darkPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (ciudad.isNotEmpty)
                          Text(
                            ciudad,
                            style: Noray4TextStyles.bodySmall.copyWith(
                              color: Noray4Colors.darkOutline,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Separador
            Container(
              height: 0.5,
              margin: const EdgeInsets.symmetric(
                  horizontal: Noray4Spacing.s6,
                  vertical: Noray4Spacing.s2),
              color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
            ),

            // Menú
            const SizedBox(height: Noray4Spacing.s2),
            _DrawerItem(
              icon: Symbols.person,
              label: 'Mi perfil',
              onTap: () => nav('/perfil', replace: true),
            ),
            _DrawerItem(
              icon: Symbols.book_2,
              label: 'Mis registros',
              onTap: () => nav('/registros', replace: true),
            ),
            _DrawerItem(
              icon: Symbols.group,
              label: 'Mi tripulación',
              onTap: () => nav('/tripulacion'),
            ),
            _DrawerItem(
              icon: Symbols.explore,
              label: 'Explorar rutas',
              onTap: () => nav('/rutas', replace: true),
            ),
            _DrawerItem(
              icon: Symbols.settings,
              label: 'Configuración',
              onTap: () => nav('/configuracion'),
            ),

            const Spacer(),

            // Separador footer
            Container(
              height: 0.5,
              margin: const EdgeInsets.symmetric(
                  horizontal: Noray4Spacing.s6,
                  vertical: Noray4Spacing.s2),
              color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.2),
            ),

            // Logout
            _DrawerItem(
              icon: Symbols.logout,
              label: 'Cerrar sesión',
              labelColor: Noray4Colors.darkOutline,
              iconColor: Noray4Colors.darkOutline,
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authProvider.notifier).logout();
              },
            ),
            const SizedBox(height: Noray4Spacing.s4),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      overlayColor: WidgetStatePropertyAll(
        Noray4Colors.darkSurfaceContainerLow.withValues(alpha: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Noray4Spacing.s6,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? Noray4Colors.darkSecondary,
            ),
            const SizedBox(width: Noray4Spacing.s4),
            Text(
              label,
              style: Noray4TextStyles.body.copyWith(
                color: labelColor ?? Noray4Colors.darkPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Search ─────────────────────────────────────────────────────────────

class _SearchEmpty extends StatelessWidget {
  final String query;
  const _SearchEmpty({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.search_off, size: 40, color: Color(0xFF474747)),
          const SizedBox(height: Noray4Spacing.s4),
          Text(
            'Sin resultados para tu búsqueda',
            style: Noray4TextStyles.body.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Noray4TextStyles.label.copyWith(
        color: Noray4Colors.darkSecondary,
        letterSpacing: 0.08 * 10,
      ),
    );
  }
}
