import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/foro/models/foro_models.dart';

class ForoPostCard extends StatelessWidget {
  final ForoPost post;
  final VoidCallback? onTap;

  const ForoPostCard({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Noray4Spacing.s4 + 4),
        decoration: BoxDecoration(
          color: Noray4Colors.darkSurfaceContainerLowest,
          borderRadius: Noray4Radius.primary,
          border: Border.all(
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: autor + tiempo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  post.autor,
                  style: Noray4TextStyles.label.copyWith(
                    color: Noray4Colors.darkSecondary,
                    letterSpacing: 0.05 * 10,
                  ),
                ),
                Text(
                  post.hace,
                  style: Noray4TextStyles.bodySmall.copyWith(
                    color: Noray4Colors.darkOnSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Noray4Spacing.s2),
            // Título
            Text(
              post.titulo,
              style: Noray4TextStyles.headlineM.copyWith(
                color: Noray4Colors.darkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Noray4Spacing.s2),
            // Preview
            Text(
              post.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Noray4TextStyles.body.copyWith(
                color: Noray4Colors.darkOnSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: Noray4Spacing.s4),
            // Footer: tags + respuestas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: Noray4Spacing.s2,
                  children: post.tags
                      .map((t) => _Tag(label: t))
                      .toList(),
                ),
                Row(
                  children: [
                    const Icon(Symbols.forum, size: 14,
                        color: Color(0xFF919191)),
                    const SizedBox(width: 4),
                    Text(
                      '${post.respuestas}',
                      style: Noray4TextStyles.bodySmall.copyWith(
                        color: Noray4Colors.darkOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: Noray4TextStyles.bodySmall.copyWith(
          color: Noray4Colors.darkOnSurfaceVariant,
          fontSize: 10,
        ),
      ),
    );
  }
}
