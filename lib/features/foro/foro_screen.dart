import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/foro/providers/foro_provider.dart';
import 'package:noray4/features/foro/widgets/foro_post_card.dart';

class ForoScreen extends ConsumerWidget {
  const ForoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(foroProvider);

    return Scaffold(
      backgroundColor: Noray4Colors.darkBackground,
      body: Column(
        children: [
          _ForoAppBar(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Noray4Spacing.s6,
                Noray4Spacing.s4,
                Noray4Spacing.s6,
                Noray4Spacing.s8 * 3,
              ),
              itemCount: state.posts.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: Noray4Spacing.s4),
              itemBuilder: (context, i) =>
                  ForoPostCard(post: state.posts[i]),
            ),
          ),
        ],
      ),
      floatingActionButton: _NuevoPostBtn(),
    );
  }
}

class _ForoAppBar extends StatelessWidget {
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
              'Foro',
              style: Noray4TextStyles.headlineL.copyWith(
                color: Noray4Colors.darkPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.04 * 24,
              ),
            ),
            const Icon(Symbols.search, size: 22,
                color: Noray4Colors.darkSecondary),
          ],
        ),
      ),
    );
  }
}

class _NuevoPostBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Noray4Spacing.s8 + 4),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Noray4Spacing.s6,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: Noray4Colors.darkPrimary,
            borderRadius: Noray4Radius.pill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Symbols.edit, size: 18, color: Color(0xFF111110)),
              const SizedBox(width: Noray4Spacing.s2),
              Text(
                'Nuevo post',
                style: Noray4TextStyles.body.copyWith(
                  color: const Color(0xFF111110),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
