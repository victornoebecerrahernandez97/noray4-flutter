import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/core/services/haptics.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/perfil/services/riders_service.dart';

// ─── Provider de presets (backend /riders/avatar-presets) ────────────────────

final avatarPresetsProvider = FutureProvider<List<AvatarPreset>>((ref) async {
  return RidersService().getAvatarPresets();
});

// ─── Step widget — Disney+ style grid ────────────────────────────────────────

class AvatarStep extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const AvatarStep({super.key, required this.onDone});

  @override
  ConsumerState<AvatarStep> createState() => _AvatarStepState();
}

class _AvatarStepState extends ConsumerState<AvatarStep> {
  int _selectedIndex = -1; // -1 = nada, N = preset N, -2 = uploaded
  String? _uploadedPath;
  bool _isSaving = false;

  Future<void> _pickFromGallery() async {
    if (_isSaving) return;
    N4Haptics.light();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _uploadedPath = picked.path;
      _selectedIndex = -2;
    });
  }

  void _selectPreset(int i) {
    if (_isSaving) return;
    N4Haptics.selection();
    setState(() {
      _selectedIndex = i;
      _uploadedPath = null;
    });
  }

  Future<void> _continue() async {
    if (_isSaving) return;
    final presets = ref.read(avatarPresetsProvider).maybeWhen(
          data: (d) => d,
          orElse: () => const <AvatarPreset>[],
        );
    if (_uploadedPath == null &&
        (_selectedIndex < 0 || _selectedIndex >= presets.length)) {
      return; // nada seleccionado → no avanza
    }
    N4Haptics.medium();
    setState(() => _isSaving = true);
    try {
      if (_uploadedPath != null) {
        await ref.read(authProvider.notifier).uploadAvatarFile(_uploadedPath!);
      } else {
        await ref
            .read(authProvider.notifier)
            .setAvatarPreset(presets[_selectedIndex].url);
      }
      if (!mounted) return;
      widget.onDone();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No pudimos guardar el avatar. Intenta de nuevo.',
            style: Noray4TextStyles.body.copyWith(color: Colors.white),
          ),
          backgroundColor: Noray4Colors.darkSurfaceContainerHigh,
        ),
      );
    }
  }

  void _skip() {
    N4Haptics.selection();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final presetsAsync = ref.watch(avatarPresetsProvider);
    final hasSelection = _uploadedPath != null ||
        (_selectedIndex >= 0 &&
            _selectedIndex <
                presetsAsync.maybeWhen(
                  data: (d) => d.length,
                  orElse: () => 0,
                ));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Noray4Spacing.s6,
          Noray4Spacing.s4,
          Noray4Spacing.s6,
          Noray4Spacing.s4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onSkip: _isSaving ? null : _skip),
            const SizedBox(height: Noray4Spacing.s8 + Noray4Spacing.s2),
            Text(
              '¿Quién rueda?',
              textAlign: TextAlign.center,
              style: Noray4TextStyles.headlineL.copyWith(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.03 * 34,
                height: 1.1,
              ),
            ),
            const SizedBox(height: Noray4Spacing.s2),
            Text(
              'Elige tu avatar o sube una foto.',
              textAlign: TextAlign.center,
              style: Noray4TextStyles.body.copyWith(
                color: Noray4Colors.darkOnSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: Noray4Spacing.s8),
            Expanded(
              child: presetsAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Noray4Colors.darkOutline,
                    ),
                  ),
                ),
                error: (_, __) => Center(
                  child: Text(
                    'No pudimos cargar los avatares.\nPuedes subir tu foto.',
                    textAlign: TextAlign.center,
                    style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkOnSurfaceVariant,
                    ),
                  ),
                ),
                data: (list) => _AvatarGrid(
                  presets: list,
                  selectedIndex: _selectedIndex,
                  uploadedPath: _uploadedPath,
                  onSelect: _selectPreset,
                  onUpload: _pickFromGallery,
                ),
              ),
            ),
            const SizedBox(height: Noray4Spacing.s4),
            _ContinuarButton(
              onTap: _continue,
              isLoading: _isSaving,
              enabled: hasSelection,
            ),
            const SizedBox(height: Noray4Spacing.s2),
          ],
        ),
      ),
    );
  }
}

// ─── Header con skip ─────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback? onSkip;
  const _Header({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Paso final',
          style: Noray4TextStyles.label.copyWith(
            color: Noray4Colors.darkOutline,
            letterSpacing: 0.1 * 10,
          ),
        ),
        GestureDetector(
          onTap: onSkip,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Noray4Spacing.s2,
              horizontal: Noray4Spacing.s2,
            ),
            child: Text(
              'Omitir',
              style: Noray4TextStyles.body.copyWith(
                color: onSkip == null
                    ? Noray4Colors.darkOutline
                    : Noray4Colors.darkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Grid estilo Disney+ ─────────────────────────────────────────────────────

class _AvatarGrid extends StatelessWidget {
  final List<AvatarPreset> presets;
  final int selectedIndex;
  final String? uploadedPath;
  final void Function(int) onSelect;
  final VoidCallback onUpload;

  const _AvatarGrid({
    required this.presets,
    required this.selectedIndex,
    required this.uploadedPath,
    required this.onSelect,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = presets.length + 1; // +1 = upload

    return LayoutBuilder(
      builder: (ctx, c) {
        const cols = 3;
        const gapX = 16.0;
        const gapY = 20.0;
        final cellSize = (c.maxWidth - (gapX * (cols - 1))) / cols;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: gapX,
            runSpacing: gapY,
            children: List.generate(totalItems, (i) {
              if (i < presets.length) {
                return SizedBox(
                  width: cellSize,
                  child: _AvatarTile(
                    label: presets[i].label,
                    imageUrl: presets[i].url,
                    isActive: selectedIndex == i && uploadedPath == null,
                    onTap: () => onSelect(i),
                  ),
                );
              }
              return SizedBox(
                width: cellSize,
                child: _UploadTile(
                  imagePath: uploadedPath,
                  isActive: uploadedPath != null,
                  onTap: onUpload,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ─── Avatar tile (círculo + label) ───────────────────────────────────────────

class _AvatarTile extends StatelessWidget {
  final String label;
  final String imageUrl;
  final bool isActive;
  final VoidCallback onTap;

  const _AvatarTile({
    required this.label,
    required this.imageUrl,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedScale(
            scale: isActive ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(isActive ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? Noray4Colors.darkAccent
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color:
                              Noray4Colors.darkAccent.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: -2,
                        ),
                      ]
                    : const [],
              ),
              child: ClipOval(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Noray4Colors.darkSurfaceContainer,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Noray4Colors.darkSurfaceContainer,
                      alignment: Alignment.center,
                      child: const Icon(
                        Symbols.broken_image,
                        color: Noray4Colors.darkOutline,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Noray4TextStyles.bodySmall.copyWith(
              color: isActive ? Colors.white : Noray4Colors.darkSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upload tile (círculo con +) ─────────────────────────────────────────────

class _UploadTile extends StatelessWidget {
  final String? imagePath;
  final bool isActive;
  final VoidCallback onTap;

  const _UploadTile({
    required this.imagePath,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedScale(
            scale: isActive ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(isActive ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? Noray4Colors.darkAccent
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color:
                              Noray4Colors.darkAccent.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: -2,
                        ),
                      ]
                    : const [],
              ),
              child: ClipOval(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: imagePath != null
                      ? Image.file(File(imagePath!), fit: BoxFit.cover)
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            color: Noray4Colors.darkSurfaceContainerLow,
                            border: Border.all(
                              color: Noray4Colors.darkOutlineVariant,
                              width: 0.5,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Symbols.add_a_photo,
                              size: 26,
                              color: Noray4Colors.darkAccent,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            imagePath != null ? 'Tu foto' : 'Subir',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Noray4TextStyles.bodySmall.copyWith(
              color: isActive ? Colors.white : Noray4Colors.darkSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Continuar button ────────────────────────────────────────────────────────

class _ContinuarButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final bool enabled;
  const _ContinuarButton({
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  State<_ContinuarButton> createState() => _ContinuarButtonState();
}

class _ContinuarButtonState extends State<_ContinuarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.enabled && !widget.isLoading;
    final bg = widget.enabled
        ? Noray4Colors.darkAccent
        : Noray4Colors.darkSurfaceContainerHigh;
    final fg = widget.enabled
        ? const Color(0xFF0C1C20)
        : Noray4Colors.darkOutline;
    return GestureDetector(
      onTapDown: isInteractive ? (_) => setState(() => _pressed = true) : null,
      onTapUp: isInteractive
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel:
          isInteractive ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedOpacity(
          opacity: widget.isLoading ? 0.75 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: Noray4Radius.primary,
              boxShadow: widget.enabled && !widget.isLoading
                  ? [
                      BoxShadow(
                        color:
                            Noray4Colors.darkAccent.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: -4,
                      ),
                    ]
                  : const [],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFF0C1C20),
                      ),
                    )
                  : Text(
                      widget.enabled ? 'Listo, entrar a Noray' : 'Elige un avatar',
                      style: Noray4TextStyles.body.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
