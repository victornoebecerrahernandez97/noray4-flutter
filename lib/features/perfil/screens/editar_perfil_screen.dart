import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).updateProfile(
          nombre: _nombreCtrl.text.trim(),
          ciudad: _ciudadCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
        );
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final nombre = ref.watch(authProvider).user?.nombre ?? '';
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
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Noray4Colors.darkSurfaceContainerHighest,
                    child: Text(
                      _initials(nombre),
                      style: Noray4TextStyles.headlineL.copyWith(
                        color: Noray4Colors.darkSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: Noray4Spacing.s2),
                  TextButton(
                    onPressed: () {},
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
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _guardar,
                style: TextButton.styleFrom(
                  backgroundColor: Noray4Colors.darkPrimary,
                  foregroundColor: Noray4Colors.darkBackground,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Guardar cambios',
                  style: Noray4TextStyles.body.copyWith(
                    color: Noray4Colors.darkBackground,
                    fontWeight: FontWeight.w600,
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
