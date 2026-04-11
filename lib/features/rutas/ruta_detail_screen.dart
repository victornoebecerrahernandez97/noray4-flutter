import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/services/haptics.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/rutas/models/rutas_models.dart';
import 'package:noray4/features/rutas/providers/rutas_provider.dart';

class RutaDetailScreen extends ConsumerWidget {
  final String rutaId;
  const RutaDetailScreen({super.key, required this.rutaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rutasProvider);
    final ruta = state.rutas.where((r) => r.id == rutaId).firstOrNull;

    if (ruta == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF131312),
        body: Center(child: Text('Ruta no encontrada',
            style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Noray4Colors.darkBackground,
      body: CustomScrollView(
        slivers: [
          _RutaAppBar(ruta: ruta, ref: ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Noray4Spacing.s6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetricsRow(ruta: ruta),
                  const SizedBox(height: Noray4Spacing.s8),
                  _MapPreview(),
                  const SizedBox(height: Noray4Spacing.s8),
                  _InfoSection(ruta: ruta),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _BottomCTA(ruta: ruta),
    );
  }
}

class _RutaAppBar extends StatelessWidget {
  final Ruta ruta;
  final WidgetRef ref;
  const _RutaAppBar({required this.ruta, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Noray4Colors.darkBackground,
      expandedHeight: 220,
      pinned: true,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Symbols.arrow_back,
              color: Noray4Colors.darkPrimary, size: 24),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            N4Haptics.selection();
            ref.read(rutasProvider.notifier).toggleFavorita(ruta.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Symbols.favorite,
              fill: ruta.isFavorita ? 1 : 0,
              color: Noray4Colors.darkPrimary,
              size: 22,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _GradientBackground(seed: ruta.id),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xFF131312)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DificultadChip(label: ruta.dificultadLabel),
                  const SizedBox(height: 6),
                  Text(
                    ruta.nombre,
                    style: Noray4TextStyles.headlineL.copyWith(
                      color: Noray4Colors.darkPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        title: Text(ruta.nombre,
            style: Noray4TextStyles.body.copyWith(
              color: Noray4Colors.darkPrimary,
              fontWeight: FontWeight.w600,
            )),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        collapseMode: CollapseMode.pin,
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final Ruta ruta;
  const _MetricsRow({required this.ruta});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Metric(icon: Symbols.route, value: '${ruta.km} km', label: 'DISTANCIA')),
        const SizedBox(width: Noray4Spacing.s4),
        Expanded(child: _Metric(icon: Symbols.schedule, value: ruta.duracion, label: 'DURACIÓN')),
        const SizedBox(width: Noray4Spacing.s4),
        Expanded(child: _Metric(icon: Symbols.person, value: '${ruta.participantes}', label: 'RIDERS')),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Metric({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          Icon(icon, size: 16, color: Noray4Colors.darkOnSurfaceVariant),
          const SizedBox(height: 6),
          Text(value,
              style: Noray4TextStyles.headlineM.copyWith(
                  color: Noray4Colors.darkPrimary, fontSize: 16)),
          Text(label,
              style: Noray4TextStyles.label.copyWith(
                  color: Noray4Colors.darkSecondary, fontSize: 8)),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: Noray4Radius.primary,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _DarkDotGrid()),
            CustomPaint(painter: _SimpleRoute()),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Noray4Colors.darkSurfaceContainerHigh.withValues(alpha: 0.9),
                  borderRadius: Noray4Radius.pill,
                  border: Border.all(
                    color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text('Vista previa',
                    style: Noray4TextStyles.label.copyWith(
                        color: Noray4Colors.darkOnSurfaceVariant, fontSize: 9)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkDotGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Noray4Colors.darkSurfaceContainerLowest);
    final p = Paint()..color = const Color(0xFF262624);
    const sp = 20.0;
    for (double x = 0; x < size.width; x += sp) {
      for (double y = 0; y < size.height; y += sp) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SimpleRoute extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Noray4Colors.darkPrimary.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.8)
      ..cubicTo(size.width * 0.3, size.height * 0.4,
          size.width * 0.6, size.height * 0.6, size.width * 0.9, size.height * 0.2);
    canvas.drawPath(path, p);
    final dot = Paint()..color = Noray4Colors.darkPrimary;
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 5, dot);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 5, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _InfoSection extends StatelessWidget {
  final Ruta ruta;
  const _InfoSection({required this.ruta});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DETALLES', style: Noray4TextStyles.label.copyWith(
            color: Noray4Colors.darkSecondary, letterSpacing: 0.1 * 10)),
        const SizedBox(height: Noray4Spacing.s4),
        _InfoRow(icon: Symbols.person, label: 'Autor', value: ruta.autor),
        const SizedBox(height: Noray4Spacing.s4),
        _InfoRow(icon: Symbols.location_on, label: 'Zona', value: ruta.zona),
        const SizedBox(height: Noray4Spacing.s4),
        _InfoRow(icon: Symbols.trending_up, label: 'Dificultad', value: ruta.dificultadLabel),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Noray4Colors.darkOnSurfaceVariant),
        const SizedBox(width: Noray4Spacing.s4),
        Text('$label  ', style: Noray4TextStyles.body.copyWith(
            color: Noray4Colors.darkOnSurfaceVariant)),
        Text(value, style: Noray4TextStyles.body.copyWith(
            color: Noray4Colors.darkPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BottomCTA extends StatelessWidget {
  final Ruta ruta;
  const _BottomCTA({required this.ruta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          Noray4Spacing.s6, Noray4Spacing.s4,
          Noray4Spacing.s6, Noray4Spacing.s4 + MediaQuery.of(context).padding.bottom),
      color: Noray4Colors.darkBackground,
      child: GestureDetector(
        onTap: () {
          N4Haptics.medium();
          context.pushNamed('crear-sala');
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Noray4Colors.darkPrimary,
            borderRadius: Noray4Radius.primary,
          ),
          child: Center(
            child: Text('Convocar en esta ruta',
                style: Noray4TextStyles.body.copyWith(
                  color: const Color(0xFF111110),
                  fontWeight: FontWeight.w600,
                )),
          ),
        ),
      ),
    );
  }
}

class _DificultadChip extends StatelessWidget {
  final String label;
  const _DificultadChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Noray4Colors.darkBackground.withValues(alpha: 0.7),
        borderRadius: Noray4Radius.pill,
        border: Border.all(
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.4),
            width: 0.5),
      ),
      child: Text(label.toUpperCase(),
          style: Noray4TextStyles.label.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant, fontSize: 9)),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  final String seed;
  const _GradientBackground({required this.seed});

  @override
  Widget build(BuildContext context) {
    final hash = seed.hashCode.abs();
    final h1 = (hash % 360).toDouble();
    final h2 = ((hash ~/ 360) % 360).toDouble();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, h1, 0.15, 0.18).toColor(),
            HSLColor.fromAHSL(1, h2, 0.12, 0.12).toColor(),
          ],
        ),
      ),
    );
  }
}
