import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/core/services/haptics.dart';
import 'package:noray4/core/theme/noray4_theme.dart';

class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: Noray4Colors.darkBackground,
      body: Column(
        children: [
          _AppBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Noray4Spacing.s6, Noray4Spacing.s4,
                Noray4Spacing.s6, Noray4Spacing.s8,
              ),
              children: [
                _SectionLabel('CUENTA'),
                const SizedBox(height: Noray4Spacing.s4),
                _InfoRow(label: 'Nombre', value: user?.nombre ?? '—'),
                const SizedBox(height: Noray4Spacing.s2),
                _InfoRow(
                  label: 'Tipo de cuenta',
                  value: (user?.isGuest ?? true) ? 'Invitado' : 'Usuario',
                ),
                const SizedBox(height: Noray4Spacing.s8),
                _SectionLabel('PREFERENCIAS'),
                const SizedBox(height: Noray4Spacing.s4),
                _SettingRow(
                  icon: Symbols.notifications,
                  label: 'Notificaciones',
                  trailing: const Icon(Symbols.chevron_right,
                      size: 18, color: Color(0xFF474747)),
                ),
                const SizedBox(height: Noray4Spacing.s2),
                _SettingRow(
                  icon: Symbols.language,
                  label: 'Idioma',
                  trailing: Text('Español',
                      style: Noray4TextStyles.body.copyWith(
                          color: Noray4Colors.darkOnSurfaceVariant)),
                ),
                const SizedBox(height: Noray4Spacing.s2),
                _SettingRow(
                  icon: Symbols.privacy_tip,
                  label: 'Privacidad',
                  trailing: const Icon(Symbols.chevron_right,
                      size: 18, color: Color(0xFF474747)),
                ),
                const SizedBox(height: Noray4Spacing.s8),
                _SectionLabel('SESIÓN'),
                const SizedBox(height: Noray4Spacing.s4),
                _LogoutButton(
                  onTap: () async {
                    N4Haptics.medium();
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.goNamed('onboarding');
                  },
                ),
                const SizedBox(height: Noray4Spacing.s8),
                Center(
                  child: Text('Noray4 v1.0.0',
                      style: Noray4TextStyles.bodySmall.copyWith(
                          color: Noray4Colors.darkOutlineVariant)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        color: Noray4Colors.darkBackground,
        padding: const EdgeInsets.symmetric(horizontal: Noray4Spacing.s6),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Symbols.arrow_back,
                  size: 24, color: Noray4Colors.darkPrimary),
            ),
            const SizedBox(width: Noray4Spacing.s4),
            Text('Configuración',
                style: Noray4TextStyles.wordmark.copyWith(
                  color: Noray4Colors.darkPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Noray4TextStyles.label.copyWith(
            color: Noray4Colors.darkSecondary, letterSpacing: 0.08 * 10));
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Noray4Spacing.s4),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerLowest,
        borderRadius: Noray4Radius.secondary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Noray4TextStyles.body.copyWith(
                  color: Noray4Colors.darkOnSurfaceVariant)),
          Text(value,
              style: Noray4TextStyles.body.copyWith(
                  color: Noray4Colors.darkPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Noray4Spacing.s4),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerLowest,
        borderRadius: Noray4Radius.secondary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Noray4Colors.darkOnSurfaceVariant),
          const SizedBox(width: Noray4Spacing.s4),
          Expanded(
              child: Text(label,
                  style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkOnSurface))),
          trailing,
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Noray4Spacing.s4),
        decoration: BoxDecoration(
          color: Noray4Colors.darkSurfaceContainerLowest,
          borderRadius: Noray4Radius.secondary,
          border: Border.all(
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(Symbols.logout, size: 20,
                color: Color(0xFF919191)),
            const SizedBox(width: Noray4Spacing.s4),
            Text('Cerrar sesión',
                style: Noray4TextStyles.body.copyWith(
                    color: Noray4Colors.darkOnSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
