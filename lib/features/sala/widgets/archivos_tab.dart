import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/sala/models/sala_models.dart';

// ─── Widget principal ─────────────────────────────────────────────────────────

class ArchivosTab extends StatelessWidget {
  final List<SalaFoto> fotos;
  final Future<void> Function(String filePath)? onUploadFoto;

  const ArchivosTab({
    super.key,
    this.fotos = const [],
    this.onUploadFoto,
  });

  Future<void> _pickAndUpload(BuildContext context) async {
    if (onUploadFoto == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    try {
      await onUploadFoto!(picked.path);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir la foto')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (fotos.isEmpty) {
      return _EmptyState(onUpload: () => _pickAndUpload(context));
    }

    return Column(
      children: [
        // Botón subir foto
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Noray4Spacing.s4,
            Noray4Spacing.s4,
            Noray4Spacing.s4,
            0,
          ),
          child: _UploadButton(onTap: () => _pickAndUpload(context)),
        ),
        const SizedBox(height: Noray4Spacing.s4),
        // Grid de fotos
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              Noray4Spacing.s4,
              0,
              Noray4Spacing.s4,
              Noray4Spacing.s4,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: fotos.length,
            itemBuilder: (context, i) => _FotoTile(
              foto: fotos[i],
              onTap: () => _openPhoto(context, fotos[i]),
            ),
          ),
        ),
      ],
    );
  }

  void _openPhoto(BuildContext context, SalaFoto foto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Noray4Colors.darkSurfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _FotoSheet(foto: foto),
    );
  }
}

// ─── Upload button ────────────────────────────────────────────────────────────

class _UploadButton extends StatelessWidget {
  final VoidCallback onTap;
  const _UploadButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Noray4Colors.darkSurfaceContainerHigh,
          borderRadius: Noray4Radius.secondary,
          border: Border.all(
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Symbols.add_photo_alternate,
              size: 18,
              color: Noray4Colors.darkOnSurfaceVariant,
            ),
            const SizedBox(width: Noray4Spacing.s2),
            Text(
              'Subir evidencia',
              style: Noray4TextStyles.body.copyWith(
                color: Noray4Colors.darkOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Foto tile ────────────────────────────────────────────────────────────────

class _FotoTile extends StatelessWidget {
  final SalaFoto foto;
  final VoidCallback onTap;
  const _FotoTile({required this.foto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: Noray4Radius.secondary,
        child: CachedNetworkImage(
          imageUrl: foto.thumbUrl,
          fit: BoxFit.cover,
          placeholder: (context0, url0) => Container(
            color: Noray4Colors.darkSurfaceContainerHigh,
          ),
          errorWidget: (context0, url0, err) => Container(
            color: Noray4Colors.darkSurfaceContainerHigh,
            child: const Icon(
              Symbols.broken_image,
              color: Noray4Colors.darkOutlineVariant,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Foto detail sheet ────────────────────────────────────────────────────────

class _FotoSheet extends StatelessWidget {
  final SalaFoto foto;
  const _FotoSheet({required this.foto});

  @override
  Widget build(BuildContext context) {
    final taken = DateTime.tryParse(foto.takenAt);
    final timeStr = taken != null
        ? '${taken.day}/${taken.month}/${taken.year} ${taken.hour.toString().padLeft(2, '0')}:${taken.minute.toString().padLeft(2, '0')}'
        : '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Noray4Spacing.s4,
          Noray4Spacing.s4,
          Noray4Spacing.s4,
          Noray4Spacing.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Noray4Colors.darkOutlineVariant,
                  borderRadius: Noray4Radius.pill,
                ),
              ),
            ),
            const SizedBox(height: Noray4Spacing.s4),
            // Imagen
            ClipRRect(
              borderRadius: Noray4Radius.primary,
              child: CachedNetworkImage(
                imageUrl: foto.url,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: Noray4Spacing.s4),
            // Caption
            if (foto.caption != null && foto.caption!.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  foto.caption!,
                  style: Noray4TextStyles.body
                      .copyWith(color: Noray4Colors.darkOnSurface),
                ),
              ),
              const SizedBox(height: Noray4Spacing.s2),
            ],
            // Meta
            if (timeStr.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  timeStr,
                  style: Noray4TextStyles.bodySmall
                      .copyWith(color: Noray4Colors.darkOnSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyState({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Symbols.photo_library,
            size: 40,
            color: Noray4Colors.darkOutlineVariant,
          ),
          const SizedBox(height: Noray4Spacing.s4),
          Text(
            'Sin evidencias aún',
            style: Noray4TextStyles.body.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: Noray4Spacing.s6),
          GestureDetector(
            onTap: onUpload,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Noray4Spacing.s6,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Noray4Colors.darkPrimary,
                borderRadius: Noray4Radius.primary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Symbols.add_photo_alternate,
                    size: 18,
                    color: Noray4Colors.darkBackground,
                  ),
                  const SizedBox(width: Noray4Spacing.s2),
                  Text(
                    'Subir primera foto',
                    style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
