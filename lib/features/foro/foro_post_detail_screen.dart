import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/foro/models/foro_models.dart';
import 'package:noray4/features/foro/providers/foro_provider.dart';

class ForoPostDetailScreen extends ConsumerWidget {
  final String postId;
  const ForoPostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(foroProvider);
    final post = state.posts.where((p) => p.id == postId).firstOrNull;

    if (post == null) {
      return Scaffold(
        backgroundColor: Noray4Colors.darkBackground,
        body: const Center(child: Text('Post no encontrado',
            style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Noray4Colors.darkBackground,
      body: Column(
        children: [
          _PostAppBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Noray4Spacing.s6, Noray4Spacing.s4,
                Noray4Spacing.s6, 120,
              ),
              children: [
                _PostHeader(post: post),
                const SizedBox(height: Noray4Spacing.s6),
                _PostBody(post: post),
                const SizedBox(height: Noray4Spacing.s8),
                _RepliesHeader(count: post.respuestas),
                const SizedBox(height: Noray4Spacing.s4),
                ..._mockReplies(post),
              ],
            ),
          ),
          _ReplyInputBar(),
        ],
      ),
    );
  }

  List<Widget> _mockReplies(ForoPost post) {
    if (post.respuestas == 0) return [];
    return [
      _ReplyBubble(autor: '@rider_mx', texto: 'Totalmente de acuerdo. Lo mismo me pasó en la sierra.', hace: 'hace 1h'),
      const SizedBox(height: Noray4Spacing.s4),
      _ReplyBubble(autor: '@moto_cdmx', texto: '¿Alguien tiene más contexto sobre esto?', hace: 'hace 3h'),
      const SizedBox(height: Noray4Spacing.s4),
      _ReplyBubble(autor: '@surf_rider', texto: 'Gracias por compartirlo, muy útil.', hace: 'ayer'),
    ];
  }
}

class _PostAppBar extends StatelessWidget {
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
            Text('Foro',
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

class _PostHeader extends StatelessWidget {
  final ForoPost post;
  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(post.autor,
                style: Noray4TextStyles.label.copyWith(
                    color: Noray4Colors.darkSecondary)),
            Text(post.hace,
                style: Noray4TextStyles.bodySmall.copyWith(
                    color: Noray4Colors.darkOnSurfaceVariant)),
          ],
        ),
        const SizedBox(height: Noray4Spacing.s2),
        Text(post.titulo,
            style: Noray4TextStyles.headlineL.copyWith(
              color: Noray4Colors.darkPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.03 * 22,
            )),
        const SizedBox(height: Noray4Spacing.s4),
        Wrap(
          spacing: Noray4Spacing.s2,
          children: post.tags.map((t) => _Tag(label: t)).toList(),
        ),
      ],
    );
  }
}

class _PostBody extends StatelessWidget {
  final ForoPost post;
  const _PostBody({required this.post});

  @override
  Widget build(BuildContext context) {
    return Text(
      post.preview,
      style: Noray4TextStyles.body.copyWith(
        color: Noray4Colors.darkOnSurface,
        height: 1.7,
        fontSize: 15,
      ),
    );
  }
}

class _RepliesHeader extends StatelessWidget {
  final int count;
  const _RepliesHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$count RESPUESTAS',
            style: Noray4TextStyles.label.copyWith(
                color: Noray4Colors.darkSecondary, letterSpacing: 0.08 * 10)),
      ],
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  final String autor;
  final String texto;
  final String hace;
  const _ReplyBubble({required this.autor, required this.texto, required this.hace});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Noray4Spacing.s4),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerLow,
        borderRadius: Noray4Radius.primary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(autor,
                  style: Noray4TextStyles.label.copyWith(
                      color: Noray4Colors.darkSecondary, fontSize: 9)),
              Text(hace,
                  style: Noray4TextStyles.bodySmall.copyWith(
                      color: Noray4Colors.darkOnSurfaceVariant, fontSize: 10)),
            ],
          ),
          const SizedBox(height: Noray4Spacing.s2),
          Text(texto,
              style: Noray4TextStyles.body.copyWith(
                  color: Noray4Colors.darkOnSurface, height: 1.5)),
        ],
      ),
    );
  }
}

class _ReplyInputBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          Noray4Spacing.s6, Noray4Spacing.s2,
          Noray4Spacing.s6,
          Noray4Spacing.s2 + MediaQuery.of(context).padding.bottom),
      color: Noray4Colors.darkBackground,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Noray4Spacing.s4, vertical: 12),
              decoration: BoxDecoration(
                color: Noray4Colors.darkSurfaceContainerLow,
                borderRadius: Noray4Radius.pill,
                border: Border.all(
                  color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: TextField(
                style: Noray4TextStyles.body.copyWith(
                    color: Noray4Colors.darkPrimary),
                decoration: InputDecoration(
                  hintText: 'Responder...',
                  hintStyle: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkOnSurfaceVariant),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: Noray4Spacing.s2),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Noray4Colors.darkPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Symbols.arrow_upward,
                size: 20, color: Color(0xFF111110)),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: Noray4Radius.pill,
        border: Border.all(color: Noray4Colors.darkOutlineVariant, width: 0.5),
      ),
      child: Text(label,
          style: Noray4TextStyles.bodySmall.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant, fontSize: 10)),
    );
  }
}
