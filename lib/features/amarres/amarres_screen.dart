import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/amarres/providers/amarres_provider.dart';
import 'package:noray4/features/amarres/widgets/amarre_card.dart';

class AmarresScreen extends ConsumerWidget {
  const AmarresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(amarresProvider);

    return Scaffold(
      backgroundColor: Noray4Colors.darkBackground,
      body: Column(
        children: [
          _AmarresAppBar(),
          _TotalKmBanner(totalKm: state.totalKm, total: state.amarres.length),
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                : state.error != null
                    ? Center(
                        child: Text(
                          'Sin conexión',
                          style: Noray4TextStyles.body.copyWith(
                            color: Noray4Colors.darkSecondary,
                          ),
                        ),
                      )
                    : state.amarres.isEmpty
                        ? _EmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              Noray4Spacing.s6,
                              Noray4Spacing.s4,
                              Noray4Spacing.s6,
                              Noray4Spacing.s8,
                            ),
                            itemCount: state.amarres.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: Noray4Spacing.s4),
                            itemBuilder: (context, i) =>
                                AmarreCard(amarre: state.amarres[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

class _AmarresAppBar extends StatelessWidget {
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
            Text(
              'Mis registros',
              style: Noray4TextStyles.wordmark.copyWith(
                color: Noray4Colors.darkPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.04 * 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalKmBanner extends StatelessWidget {
  final int totalKm;
  final int total;
  const _TotalKmBanner({required this.totalKm, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        Noray4Spacing.s6, 0, Noray4Spacing.s6, Noray4Spacing.s4,
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${totalKm >= 1000 ? '${(totalKm / 1000).toStringAsFixed(1)}k' : totalKm} km',
                  style: Noray4TextStyles.headlineL.copyWith(
                    color: Noray4Colors.darkPrimary,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.04 * 32,
                  ),
                ),
                Text(
                  'KILÓMETROS TOTALES',
                  style: Noray4TextStyles.label.copyWith(
                    color: Noray4Colors.darkSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 0.5,
            height: 40,
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(width: Noray4Spacing.s6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$total',
                style: Noray4TextStyles.headlineL.copyWith(
                  color: Noray4Colors.darkPrimary,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.04 * 32,
                ),
              ),
              Text(
                'REGISTROS',
                style: Noray4TextStyles.label.copyWith(
                  color: Noray4Colors.darkSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
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
          const Icon(Symbols.anchor, size: 40, color: Color(0xFF474747)),
          const SizedBox(height: Noray4Spacing.s4),
          Text(
            'Aún no tienes registros',
            style: Noray4TextStyles.headlineM.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: Noray4Spacing.s2),
          Text(
            'Convoca y empieza a rodar.',
            style: Noray4TextStyles.body.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
