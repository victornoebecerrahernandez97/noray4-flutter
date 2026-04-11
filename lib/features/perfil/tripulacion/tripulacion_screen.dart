import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';

class _Rider {
  final String initials;
  final String nombre;
  final String moto;
  final int amarres;
  const _Rider({
    required this.initials,
    required this.nombre,
    required this.moto,
    required this.amarres,
  });
}

const _mockRiders = [
  _Rider(initials: 'MR', nombre: 'Marcus R.', moto: 'Kawasaki Z900', amarres: 18),
  _Rider(initials: 'EV', nombre: 'Elara V.', moto: 'BMW F800GS', amarres: 31),
  _Rider(initials: 'RK', nombre: 'Rider K.', moto: 'Yamaha MT-07', amarres: 9),
  _Rider(initials: 'JD', nombre: 'Juan D.', moto: 'Honda CB650R', amarres: 24),
];

class TripulacionScreen extends StatelessWidget {
  const TripulacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Noray4Colors.darkBackground,
      body: Column(
        children: [
          _AppBar(),
          _StatsRow(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Noray4Spacing.s6, Noray4Spacing.s4,
                Noray4Spacing.s6, Noray4Spacing.s8,
              ),
              itemCount: _mockRiders.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: Noray4Spacing.s4),
              itemBuilder: (context, i) =>
                  _RiderCard(rider: _mockRiders[i]),
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
            Text('Mi tripulación',
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

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          Noray4Spacing.s6, 0, Noray4Spacing.s6, Noray4Spacing.s4),
      padding: const EdgeInsets.all(Noray4Spacing.s4),
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
          _Stat(value: '${_mockRiders.length}', label: 'RIDERS'),
          _vline(),
          _Stat(
            value: '${_mockRiders.fold(0, (s, r) => s + r.amarres)}',
            label: 'REGISTROS TOTALES',
          ),
        ],
      ),
    );
  }

  Widget _vline() => Container(
        width: 0.5,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: Noray4Spacing.s6),
        color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
      );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: Noray4TextStyles.headlineL.copyWith(
                color: Noray4Colors.darkPrimary,
                fontWeight: FontWeight.w300,
                fontSize: 28)),
        Text(label,
            style: Noray4TextStyles.label.copyWith(
                color: Noray4Colors.darkSecondary, fontSize: 8)),
      ],
    );
  }
}

class _RiderCard extends StatelessWidget {
  final _Rider rider;
  const _RiderCard({required this.rider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Noray4Spacing.s4),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerLowest,
        borderRadius: Noray4Radius.primary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Noray4Colors.darkSurfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(rider.initials,
                  style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkPrimary,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: Noray4Spacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rider.nombre,
                    style: Noray4TextStyles.body.copyWith(
                        color: Noray4Colors.darkPrimary,
                        fontWeight: FontWeight.w600)),
                Text(rider.moto,
                    style: Noray4TextStyles.bodySmall.copyWith(
                        color: Noray4Colors.darkOnSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${rider.amarres}',
                  style: Noray4TextStyles.headlineM.copyWith(
                      color: Noray4Colors.darkPrimary,
                      fontWeight: FontWeight.w300,
                      fontSize: 18)),
              Text('REGISTROS',
                  style: Noray4TextStyles.label.copyWith(
                      color: Noray4Colors.darkSecondary, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }
}
