import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/services/haptics.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/amarres/models/amarres_models.dart';
import 'package:noray4/features/amarres/providers/amarres_provider.dart';

class AmarreDetalleScreen extends ConsumerWidget {
  final Amarre amarre;
  const AmarreDetalleScreen({super.key, required this.amarre});

  Future<void> _clonar(BuildContext context, WidgetRef ref) async {
    final clon = Amarre(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: 'Copia — ${amarre.nombre}',
      fecha: DateTime.now(),
      km: amarre.km,
      duracion: amarre.duracion,
      participantes: amarre.participantes,
      zona: amarre.zona,
    );
    ref.read(amarresProvider.notifier).addAmarre(clon);
    await N4Haptics.medium();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ruta clonada en tus registros',
          style: Noray4TextStyles.body.copyWith(
            color: Noray4Colors.darkPrimary,
          ),
        ),
        backgroundColor: Noray4Colors.darkSurfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: Noray4Radius.secondary,
          side: const BorderSide(
            color: Noray4Colors.darkOutlineVariant,
            width: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Noray4Colors.darkBackground,
      body: CustomScrollView(
        slivers: [
          _CoverSliverAppBar(
            amarre: amarre,
            onClonar: () => _clonar(context, ref),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Noray4Spacing.s6,
              Noray4Spacing.s6,
              Noray4Spacing.s6,
              Noray4Spacing.s8 * 3,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StatsRow(amarre: amarre),
                const SizedBox(height: Noray4Spacing.s8),
                _SectionLabel(label: 'Recorrido'),
                const SizedBox(height: Noray4Spacing.s4),
                _MapaMock(),
                const SizedBox(height: Noray4Spacing.s8),
                _SectionLabel(label: 'Galería'),
                const SizedBox(height: Noray4Spacing.s4),
                _Galeria(),
                const SizedBox(height: Noray4Spacing.s8),
                _SectionLabel(label: 'Tripulación'),
                const SizedBox(height: Noray4Spacing.s4),
                _RidersRow(participantes: amarre.participantes),
                const SizedBox(height: Noray4Spacing.s8),
                _SectionLabel(label: 'Notas'),
                const SizedBox(height: Noray4Spacing.s4),
                _Notas(),
                const SizedBox(height: Noray4Spacing.s8),
                // ── Botón clonar full-width ──────────────────────────────
                _ClonarButton(onTap: () => _clonar(context, ref)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SliverAppBar con portada ─────────────────────────────────────────────────

class _CoverSliverAppBar extends StatelessWidget {
  final Amarre amarre;
  final VoidCallback onClonar;
  const _CoverSliverAppBar({required this.amarre, required this.onClonar});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: Noray4Colors.darkBackground,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Noray4Colors.darkSurfaceContainerHigh.withValues(alpha: 0.85),
            borderRadius: Noray4Radius.secondary,
            border: Border.all(
              color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: const Icon(
            Symbols.arrow_back,
            size: 20,
            color: Noray4Colors.darkPrimary,
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: onClonar,
          child: Container(
            margin: const EdgeInsets.only(right: Noray4Spacing.s4, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: Noray4Spacing.s4,
              vertical: Noray4Spacing.s2,
            ),
            decoration: BoxDecoration(
              color: Noray4Colors.darkSurfaceContainerHigh.withValues(alpha: 0.85),
              borderRadius: Noray4Radius.secondary,
              border: Border.all(
                color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Symbols.copy_all,
                  size: 14,
                  color: Noray4Colors.darkPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Clonar ruta',
                  style: Noray4TextStyles.bodySmall.copyWith(
                    color: Noray4Colors.darkPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      title: Text(
        amarre.nombre,
        style: Noray4TextStyles.body.copyWith(
          color: Noray4Colors.darkPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://picsum.photos/seed/${amarre.id}/800/400',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: Noray4Colors.darkSurfaceContainer,
                child: const Icon(
                  Symbols.image,
                  size: 40,
                  color: Noray4Colors.darkOutlineVariant,
                ),
              ),
            ),
            // Gradiente inferior para legibilidad del título
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC131312)],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Amarre amarre;
  const _StatsRow({required this.amarre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Noray4Spacing.s6),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerLow,
        borderRadius: Noray4Radius.primary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              icon: Symbols.route,
              value: '${amarre.km} km',
              label: 'DISTANCIA',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatCell(
              icon: Symbols.schedule,
              value: amarre.duracion,
              label: 'DURACIÓN',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatCell(
              icon: Symbols.group,
              value: '${amarre.participantes.length}',
              label: 'RIDERS',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCell({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Noray4Colors.darkOnSurfaceVariant),
        const SizedBox(height: Noray4Spacing.s2),
        Text(
          value,
          style: Noray4TextStyles.headlineM.copyWith(
            color: Noray4Colors.darkPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Noray4TextStyles.label.copyWith(
            color: Noray4Colors.darkSecondary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 48,
      color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
    );
  }
}

// ─── Mapa mock ────────────────────────────────────────────────────────────────

class _MapaMock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerLowest,
        borderRadius: Noray4Radius.primary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dot grid
          CustomPaint(painter: _DotGridPainter(), size: Size.infinite),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Symbols.map,
                size: 36,
                color: Noray4Colors.darkOutlineVariant,
              ),
              const SizedBox(height: Noray4Spacing.s2),
              Text(
                'Mapa del recorrido',
                style: Noray4TextStyles.bodySmall.copyWith(
                  color: Noray4Colors.darkOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF262624)
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Galería ──────────────────────────────────────────────────────────────────

const _galeriaSeed = ['moto1', 'route2', 'trail3', 'sunset4', 'road5', 'curve6'];

class _Galeria extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: Noray4Spacing.s2,
        mainAxisSpacing: Noray4Spacing.s2,
      ),
      itemCount: _galeriaSeed.length,
      itemBuilder: (context, i) {
        return ClipRRect(
          borderRadius: Noray4Radius.secondary,
          child: Image.network(
            'https://picsum.photos/seed/${_galeriaSeed[i]}/300/300',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: Noray4Colors.darkSurfaceContainer,
              child: const Icon(
                Symbols.image,
                size: 24,
                color: Noray4Colors.darkOutlineVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Riders row ───────────────────────────────────────────────────────────────

class _RidersRow extends StatelessWidget {
  final List<String> participantes;
  const _RidersRow({required this.participantes});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final p in participantes) ...[
          _RiderAvatar(alias: p),
          const SizedBox(width: Noray4Spacing.s4),
        ],
      ],
    );
  }
}

class _RiderAvatar extends StatelessWidget {
  final String alias;
  const _RiderAvatar({required this.alias});

  String get _initials {
    final clean = alias.replaceAll('@', '').replaceAll('_', ' ').trim();
    final parts = clean.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Noray4Colors.darkSurfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              _initials,
              style: Noray4TextStyles.bodySmall.copyWith(
                color: Noray4Colors.darkPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: Noray4Spacing.s2),
        Text(
          alias,
          style: Noray4TextStyles.label.copyWith(
            color: Noray4Colors.darkSecondary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

// ─── Notas ────────────────────────────────────────────────────────────────────

class _Notas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Noray4Spacing.s6),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerLowest,
        borderRadius: Noray4Radius.primary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Text(
        'Salida puntual a las 7am desde el periférico. La subida al puerto fue limpia, sin tráfico. '
        'La parada en el km 180 fue el punto alto del día — vista despejada y café decente. '
        'Repetir este circuito en temporada fría.',
        style: Noray4TextStyles.body.copyWith(
          color: Noray4Colors.darkOnSurfaceVariant,
          height: 1.7,
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

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

// ─── Botón clonar full-width ──────────────────────────────────────────────────

class _ClonarButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ClonarButton({required this.onTap});

  @override
  State<_ClonarButton> createState() => _ClonarButtonState();
}

class _ClonarButtonState extends State<_ClonarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: Noray4Radius.primary,
            border: Border.all(
              color: Noray4Colors.darkOutlineVariant,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Symbols.copy_all,
                size: 18,
                color: Noray4Colors.darkSecondary,
              ),
              const SizedBox(width: Noray4Spacing.s2),
              Text(
                'Clonar ruta',
                style: Noray4TextStyles.body.copyWith(
                  color: Noray4Colors.darkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
