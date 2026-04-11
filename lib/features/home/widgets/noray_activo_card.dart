import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/home/models/home_models.dart';

class NorayActivoCard extends StatefulWidget {
  final NorayActivo noray;
  final VoidCallback onTap;

  const NorayActivoCard({super.key, required this.noray, required this.onTap});

  @override
  State<NorayActivoCard> createState() => _NorayActivoCardState();
}

class _NorayActivoCardState extends State<NorayActivoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 192,
        decoration: BoxDecoration(
          color: Noray4Colors.darkSurfaceContainerLow,
          borderRadius: Noray4Radius.primary,
          border: Border.all(
            color: Noray4Colors.darkPrimary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: Noray4Radius.primary,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gradient overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6131312)],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(Noray4Spacing.s4 + 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Pills(noray: widget.noray, pulse: _pulse),
                    _Info(noray: widget.noray),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pills extends StatelessWidget {
  final NorayActivo noray;
  final AnimationController pulse;
  const _Pills({required this.noray, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Noray4Spacing.s2,
      children: [
        _LivePill(pulse: pulse),
        if (noray.hasVoz) _Pill(label: 'Voz abierta'),
        if (noray.hasGps) _Pill(label: 'GPS activo'),
      ],
    );
  }
}

class _LivePill extends StatelessWidget {
  final AnimationController pulse;
  const _LivePill({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Noray4Colors.darkPrimary,
        borderRadius: Noray4Radius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) => Opacity(
              opacity: 0.4 + pulse.value * 0.6,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: Noray4TextStyles.label.copyWith(
              fontSize: 10,
              color: const Color(0xFF1A1C1C),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: Noray4Radius.pill,
        border: Border.all(
          color: Noray4Colors.darkOnSurface.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: Noray4TextStyles.bodySmall.copyWith(
          color: Noray4Colors.darkOnSurface,
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final NorayActivo noray;
  const _Info({required this.noray});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          noray.nombre,
          style: Noray4TextStyles.headlineM.copyWith(
            color: Noray4Colors.darkPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Symbols.distance,
              size: 14,
              color: Color(0xFFC6C6C6),
            ),
            const SizedBox(width: 4),
            Text(
              '${noray.km.toStringAsFixed(0)} km recorridos · ${noray.tiempo}',
              style: Noray4TextStyles.bodySmall.copyWith(
                color: Noray4Colors.darkOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
