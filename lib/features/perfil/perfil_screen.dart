import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/perfil/providers/perfil_provider.dart';
import 'package:noray4/features/perfil/widgets/moto_card.dart';
import 'package:noray4/features/perfil/widgets/perfil_menu_item.dart';
import 'package:noray4/features/perfil/widgets/stats_bento_grid.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilProvider);

    return Scaffold(
      backgroundColor: Noray4Colors.darkBackground,
      body: Column(
        children: [
          _PerfilAppBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Noray4Spacing.s6,
                Noray4Spacing.s8,
                Noray4Spacing.s6,
                Noray4Spacing.s8 * 4,
              ),
              children: [
                // Avatar + Nombre
                _ProfileHeader(
                  nombre: perfil.nombre,
                  ubicacion: perfil.ubicacion,
                ),
                const SizedBox(height: Noray4Spacing.s8 + 4),
                // Stats bento grid
                StatsBentoGrid(stats: perfil.stats),
                const SizedBox(height: Noray4Spacing.s8 + 4),
                // Menu items
                PerfilMenuItem(
                  icon: Symbols.anchor,
                  label: 'Mis registros',
                  onTap: () => context.push('/amarres'),
                ),
                const SizedBox(height: Noray4Spacing.s4),
                PerfilMenuItem(
                  icon: Symbols.group,
                  label: 'Mi tripulación',
                  onTap: () {},
                ),
                const SizedBox(height: Noray4Spacing.s4),
                PerfilMenuItem(
                  icon: Symbols.hub,
                  label: 'Mi noray',
                  onTap: () {},
                ),
                PerfilMenuItem(
                  icon: Symbols.settings,
                  label: 'Configuración',
                  showTopDivider: true,
                  onTap: () {},
                ),
                const SizedBox(height: Noray4Spacing.s4),
                _LogoutTile(ref: ref),
                const SizedBox(height: Noray4Spacing.s8 + 4),
                // Tu moto
                _MotoSection(moto: perfil.moto),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerfilAppBar extends StatelessWidget {
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
            const Icon(Symbols.menu, size: 24,
                color: Noray4Colors.darkPrimary),
            Text(
              'Noray⁴',
              style: Noray4TextStyles.wordmark.copyWith(
                color: Noray4Colors.darkPrimary,
                fontSize: 18,
                letterSpacing: -0.05 * 18,
              ),
            ),
            IconButton(
              icon: const Icon(Symbols.edit, size: 24,
                  color: Noray4Colors.darkPrimary),
              onPressed: () => context.push('/perfil/editar'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String nombre;
  final String ubicacion;
  const _ProfileHeader({required this.nombre, required this.ubicacion});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar circle
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Noray4Colors.darkSurfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: const Center(
            child: Icon(
              Symbols.person,
              fill: 1,
              size: 48,
              color: Color(0xFF474747),
            ),
          ),
        ),
        const SizedBox(height: Noray4Spacing.s6),
        Text(
          nombre,
          style: Noray4TextStyles.headlineL.copyWith(
            color: Noray4Colors.darkPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.04 * 32,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ubicacion,
          style: Noray4TextStyles.body.copyWith(
            color: Noray4Colors.darkSecondary,
          ),
        ),
      ],
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final WidgetRef ref;
  const _LogoutTile({required this.ref});

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF474747), width: 0.5),
        ),
        title: Text(
          'Cerrar sesión',
          style: Noray4TextStyles.headlineM.copyWith(
            color: Colors.white,
          ),
        ),
        content: Text(
          '¿Seguro que quieres cerrar sesión?',
          style: Noray4TextStyles.body.copyWith(
            color: Noray4Colors.darkSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: Noray4TextStyles.body.copyWith(
                color: Noray4Colors.darkSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Cerrar sesión',
              style: Noray4TextStyles.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirm(context),
      child: Container(
        padding: const EdgeInsets.all(Noray4Spacing.s4),
        decoration: BoxDecoration(
          color: Noray4Colors.darkSurfaceContainerLowest,
          borderRadius: Noray4Radius.secondary,
        ),
        child: Row(
          children: [
            const Icon(
              Symbols.logout,
              size: 22,
              color: Color(0xFF919191),
            ),
            const SizedBox(width: Noray4Spacing.s4),
            Expanded(
              child: Text(
                'Cerrar sesión',
                style: Noray4TextStyles.body.copyWith(
                  color: Noray4Colors.darkOnSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotoSection extends StatelessWidget {
  final dynamic moto;
  const _MotoSection({required this.moto});

  @override
  Widget build(BuildContext context) {
    if (moto == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TU MOTO',
              style: Noray4TextStyles.label.copyWith(
                color: Noray4Colors.darkSecondary,
                letterSpacing: 0.2 * 10,
              ),
            ),
            Text(
              'DETALLES TÉCNICOS',
              style: Noray4TextStyles.label.copyWith(
                color: Noray4Colors.darkOutlineVariant,
                fontSize: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: Noray4Spacing.s6),
        MotoCard(moto: moto),
      ],
    );
  }
}
