import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/core/theme/noray4_theme.dart';

class EditarPerfilScreen extends ConsumerStatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  ConsumerState<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends ConsumerState<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _ciudadCtrl;
  late final TextEditingController _bioCtrl;
  final _modeloCtrl = TextEditingController(text: 'Honda CB500F');
  final _anioCtrl = TextEditingController(text: '2021');
  final _kilometrajeCtrl = TextEditingController(text: '18400');
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nombreCtrl = TextEditingController(text: user?.nombre ?? '');
    _ciudadCtrl = TextEditingController(text: user?.ciudad ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ciudadCtrl.dispose();
    _bioCtrl.dispose();
    _modeloCtrl.dispose();
    _anioCtrl.dispose();
    _kilometrajeCtrl.dispose();
    super.dispose();
  }

  String _initials(String nombre) {
    final parts = nombre.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  Future<void> _guardar() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await ref.read(authProvider.notifier).updateProfile(
          nombre: _nombreCtrl.text.trim(),
          ciudad: _ciudadCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
        );
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Perfil actualizado',
          style: Noray4TextStyles.body.copyWith(
            color: Noray4Colors.darkPrimary,
          ),
        ),
        backgroundColor: Noray4Colors.darkSurfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Noray4Colors.darkOutlineVariant,
            width: 0.5,
          ),
        ),
      ),
    );
    context.pop();
  }

  Future<void> _cambiarFoto() async {
    if (_isUploadingAvatar) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null || !mounted) return;
    setState(() => _isUploadingAvatar = true);
    try {
      await ref.read(authProvider.notifier).uploadAvatarFile(picked.path);
      await HapticFeedback.lightImpact();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo subir la foto',
              style: Noray4TextStyles.body
                  .copyWith(color: Noray4Colors.darkPrimary),
            ),
            backgroundColor: Noray4Colors.darkSurfaceContainerHigh,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = ref.watch(authProvider).user?.nombre ?? '';
    final avatarUrl = ref.watch(authProvider).user?.avatarUrl;
    return Scaffold(
      backgroundColor: Noray4Colors.darkBackground,
      appBar: AppBar(
        backgroundColor: Noray4Colors.darkBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back,
              size: 24, color: Noray4Colors.darkPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Editar perfil',
          style: Noray4TextStyles.headlineM.copyWith(
            color: Noray4Colors.darkPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            color: Noray4Colors.darkOutlineVariant,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Noray4Spacing.s6,
            Noray4Spacing.s8,
            Noray4Spacing.s6,
            Noray4Spacing.s8 * 2,
          ),
          children: [
            // Avatar
            Center(
              child: Column(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: Noray4Colors.darkSurfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Noray4Colors.darkOutlineVariant
                            .withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (avatarUrl != null && avatarUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => Center(
                              child: Text(
                                _initials(nombre),
                                style: Noray4TextStyles.headlineL.copyWith(
                                  color: Noray4Colors.darkSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            errorWidget: (ctx, url, err) => Center(
                              child: Text(
                                _initials(nombre),
                                style: Noray4TextStyles.headlineL.copyWith(
                                  color: Noray4Colors.darkSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else
                          Center(
                            child: Text(
                              _initials(nombre),
                              style: Noray4TextStyles.headlineL.copyWith(
                                color: Noray4Colors.darkSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (_isUploadingAvatar)
                          Container(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Noray4Colors.darkPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Noray4Spacing.s2),
                  TextButton(
                    onPressed: _isUploadingAvatar ? null : _cambiarFoto,
                    style: TextButton.styleFrom(
                      foregroundColor: Noray4Colors.darkSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Noray4Spacing.s4,
                        vertical: Noray4Spacing.s2,
                      ),
                    ),
                    child: Text(
                      'Cambiar foto',
                      style: Noray4TextStyles.body.copyWith(
                        color: Noray4Colors.darkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Noray4Spacing.s8),

            // Nombre
            _Field(
              label: 'Nombre completo',
              controller: _nombreCtrl,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre no puede estar vacío'
                  : null,
            ),
            const SizedBox(height: Noray4Spacing.s4),

            // Ciudad
            _Field(
              label: 'Ciudad',
              controller: _ciudadCtrl,
            ),
            const SizedBox(height: Noray4Spacing.s4),

            // Bio
            _Field(
              label: 'Bio',
              controller: _bioCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: Noray4Spacing.s8),

            // Separador — Mi moto
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 0.5,
                    color: Noray4Colors.darkOutlineVariant,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Noray4Spacing.s4),
                  child: Text(
                    'MI MOTO',
                    style: Noray4TextStyles.label.copyWith(
                      color: Noray4Colors.darkSecondary,
                      letterSpacing: 0.2 * 10,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 0.5,
                    color: Noray4Colors.darkOutlineVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Noray4Spacing.s8),

            // Modelo
            _Field(
              label: 'Modelo',
              hint: 'Honda CB500F',
              controller: _modeloCtrl,
            ),
            const SizedBox(height: Noray4Spacing.s4),

            // Año
            _Field(
              label: 'Año',
              hint: '2021',
              controller: _anioCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: Noray4Spacing.s4),

            // Kilometraje
            _Field(
              label: 'Kilometraje',
              hint: '18400',
              controller: _kilometrajeCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: Noray4Spacing.s8),

            // Guardar
            GestureDetector(
              onTap: _guardar,
              child: AnimatedOpacity(
                opacity: _isSaving ? 0.7 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    color: Noray4Colors.darkPrimary,
                    borderRadius: Noray4Radius.primary,
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFF0C1C20),
                            ),
                          )
                        : Text(
                            'Guardar cambios',
                            style: Noray4TextStyles.body.copyWith(
                              color: Noray4Colors.darkBackground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Noray4TextStyles.label.copyWith(
            color: Noray4Colors.darkSecondary,
            letterSpacing: 0.05 * 10,
          ),
        ),
        const SizedBox(height: Noray4Spacing.s2),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: Noray4TextStyles.body.copyWith(
            color: Noray4Colors.darkPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Noray4TextStyles.body.copyWith(
              color: Noray4Colors.darkOutline,
            ),
            filled: true,
            fillColor: Noray4Colors.darkSurfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Noray4Spacing.s4,
              vertical: Noray4Spacing.s4,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Noray4Colors.darkOutlineVariant,
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Noray4Colors.darkOutline,
                width: 0.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Noray4Colors.darkOutlineVariant,
                width: 0.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Noray4Colors.darkOutline,
                width: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
