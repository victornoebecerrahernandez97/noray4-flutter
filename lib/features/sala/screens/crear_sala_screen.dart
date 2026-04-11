import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/services/haptics.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/sala/services/salas_service.dart';

enum _Privacidad { publica, privada }

class CrearSalaScreen extends ConsumerStatefulWidget {
  const CrearSalaScreen({super.key});

  @override
  ConsumerState<CrearSalaScreen> createState() => _CrearSalaScreenState();
}

class _CrearSalaScreenState extends ConsumerState<CrearSalaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  _Privacidad _privacidad = _Privacidad.publica;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _onBack() async {
    final hasContent =
        _nombreCtrl.text.isNotEmpty || _descCtrl.text.isNotEmpty;
    if (!hasContent) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => const _DescartarDialog(),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _crearSala() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await N4Haptics.medium();
    try {
      final sala = await SalasService().createSala(
        name: _nombreCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        isPrivate: _privacidad == _Privacidad.privada,
      );
      if (!mounted) return;
      context.push('/sala/${sala.id}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo convocar la salida',
            style: Noray4TextStyles.body.copyWith(
              color: Noray4Colors.darkPrimary,
            ),
          ),
          backgroundColor: Noray4Colors.darkSurfaceContainerHigh,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: Noray4Colors.darkBackground,
        body: Column(
          children: [
            _AppBar(onBack: _onBack),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Noray4Spacing.s6,
                    Noray4Spacing.s8,
                    Noray4Spacing.s6,
                    Noray4Spacing.s8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Convocar',
                        style: Noray4TextStyles.headlineL.copyWith(
                          color: Noray4Colors.darkPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.04 * 32,
                        ),
                      ),
                      const SizedBox(height: Noray4Spacing.s2),
                      Text(
                        'Define cómo quieres que ruede tu tripulación.',
                        style: Noray4TextStyles.body.copyWith(
                          color: Noray4Colors.darkOnSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: Noray4Spacing.s8),

                      // ── Nombre ──────────────────────────────────────────
                      _FieldLabel('NOMBRE DE LA SALIDA'),
                      const SizedBox(height: Noray4Spacing.s2),
                      _FormField(
                        controller: _nombreCtrl,
                        hint: 'Ej. Vuelta al cerro del padre',
                        autofocus: true,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Dale un nombre a la salida'
                            : null,
                      ),
                      const SizedBox(height: Noray4Spacing.s6),

                      // ── Descripción ──────────────────────────────────────
                      _FieldLabel('DESCRIPCIÓN'),
                      const SizedBox(height: Noray4Spacing.s2),
                      _FormField(
                        controller: _descCtrl,
                        hint: 'Punto de encuentro, recomendaciones...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: Noray4Spacing.s6),

                      // ── Privacidad ───────────────────────────────────────
                      _FieldLabel('PRIVACIDAD'),
                      const SizedBox(height: Noray4Spacing.s2),
                      _PrivacidadSelector(
                        value: _privacidad,
                        onChanged: (v) => setState(() => _privacidad = v),
                      ),
                      const SizedBox(height: Noray4Spacing.s8),

                      // ── Botón ────────────────────────────────────────────
                      _BotonCrear(
                        onTap: _isLoading ? null : _crearSala,
                        isLoading: _isLoading,
                      ),
                    ],
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

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final VoidCallback onBack;
  const _AppBar({required this.onBack});

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
              onTap: onBack,
              child: const Icon(
                Symbols.arrow_back,
                size: 24,
                color: Noray4Colors.darkPrimary,
              ),
            ),
            const SizedBox(width: Noray4Spacing.s4),
            Text(
              'Nueva salida',
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

// ─── Field Label ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Noray4TextStyles.label.copyWith(
        color: Noray4Colors.darkSecondary,
        letterSpacing: 0.08 * 10,
      ),
    );
  }
}

// ─── Form Field ───────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      validator: validator,
      style: Noray4TextStyles.body.copyWith(
        color: Noray4Colors.darkPrimary,
        height: 1.6,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Noray4TextStyles.body.copyWith(
          color: Noray4Colors.darkOnSurfaceVariant,
        ),
        filled: true,
        fillColor: Noray4Colors.darkSurfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Noray4Spacing.s4,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Noray4Radius.secondary,
          borderSide: BorderSide(
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Noray4Radius.secondary,
          borderSide: const BorderSide(
            color: Noray4Colors.darkOutline,
            width: 0.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Noray4Radius.secondary,
          borderSide: BorderSide(
            color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Noray4Radius.secondary,
          borderSide: const BorderSide(
            color: Noray4Colors.darkOutline,
            width: 0.5,
          ),
        ),
        errorStyle: Noray4TextStyles.bodySmall.copyWith(
          color: Noray4Colors.darkSecondary,
        ),
      ),
    );
  }
}

// ─── Privacidad Selector ─────────────────────────────────────────────────────

class _PrivacidadSelector extends StatelessWidget {
  final _Privacidad value;
  final ValueChanged<_Privacidad> onChanged;

  const _PrivacidadSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PrivacidadOption(
            label: 'Pública',
            icon: Symbols.public,
            selected: value == _Privacidad.publica,
            onTap: () => onChanged(_Privacidad.publica),
          ),
        ),
        const SizedBox(width: Noray4Spacing.s2),
        Expanded(
          child: _PrivacidadOption(
            label: 'Privada',
            icon: Symbols.lock,
            selected: value == _Privacidad.privada,
            onTap: () => onChanged(_Privacidad.privada),
          ),
        ),
      ],
    );
  }
}

class _PrivacidadOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PrivacidadOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          vertical: Noray4Spacing.s4,
          horizontal: Noray4Spacing.s4,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Noray4Colors.darkSurfaceContainerHigh
              : Noray4Colors.darkSurfaceContainerLow,
          borderRadius: Noray4Radius.secondary,
          border: Border.all(
            color: selected
                ? Noray4Colors.darkPrimary
                : Noray4Colors.darkOutlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(selected),
                size: 18,
                color: selected
                    ? Noray4Colors.darkPrimary
                    : Noray4Colors.darkOnSurfaceVariant,
              ),
            ),
            const SizedBox(width: Noray4Spacing.s2),
            Text(
              label,
              style: Noray4TextStyles.body.copyWith(
                color: selected
                    ? Noray4Colors.darkPrimary
                    : Noray4Colors.darkOnSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón Crear ─────────────────────────────────────────────────────────────

class _BotonCrear extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  const _BotonCrear({required this.onTap, this.isLoading = false});

  @override
  State<_BotonCrear> createState() => _BotonCrearState();
}

class _BotonCrearState extends State<_BotonCrear> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Noray4Colors.darkPrimary,
            borderRadius: Noray4Radius.primary,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Color(0xFF111110),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                        Symbols.anchor, size: 20, color: Color(0xFF111110)),
                    const SizedBox(width: Noray4Spacing.s2),
                    Text(
                      'Convocar salida',
                      style: Noray4TextStyles.body.copyWith(
                        color: const Color(0xFF111110),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Diálogo Descartar ────────────────────────────────────────────────────────

class _DescartarDialog extends StatelessWidget {
  const _DescartarDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Noray4Colors.darkSurfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: Noray4Radius.primary),
      title: Text(
        'Descartar cambios',
        style: Noray4TextStyles.headlineM.copyWith(
          color: Noray4Colors.darkPrimary,
          fontSize: 18,
        ),
      ),
      content: Text(
        'Si vuelves ahora perderás los datos que ingresaste.',
        style: Noray4TextStyles.body.copyWith(
          color: Noray4Colors.darkOnSurfaceVariant,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Seguir editando',
            style: Noray4TextStyles.body.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Descartar',
            style: Noray4TextStyles.body.copyWith(
              color: Noray4Colors.darkPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
