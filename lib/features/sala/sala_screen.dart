import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/services/haptics.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/amarres/models/amarres_models.dart';
import 'package:noray4/features/amarres/providers/amarres_provider.dart';
import 'package:noray4/features/sala/models/sala_models.dart';
import 'package:noray4/features/sala/providers/sala_provider.dart';
import 'package:noray4/features/sala/widgets/chat_bubble.dart';
import 'package:noray4/features/sala/widgets/chat_input_bar.dart';
import 'package:noray4/features/sala/widgets/map_tab.dart';
import 'package:noray4/features/sala/widgets/archivos_tab.dart';
import 'package:noray4/features/sala/widgets/sala_tab_bar.dart';
import 'package:noray4/features/sala/widgets/voz_tab.dart';

class SalaScreen extends ConsumerStatefulWidget {
  final String salaId;
  final Map<String, dynamic>? salaData;

  const SalaScreen({super.key, required this.salaId, this.salaData});

  @override
  ConsumerState<SalaScreen> createState() => _SalaScreenState();
}

class _SalaScreenState extends ConsumerState<SalaScreen> {
  Future<void> _cerrarSalida() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _CerrarSalidaSheet(),
    );
    if (confirmed != true || !mounted) return;

    final sala = ref.read(salaProvider(widget.salaId));
    final nombre =
        (widget.salaData?['nombre'] as String?)?.isNotEmpty == true
            ? widget.salaData!['nombre'] as String
            : sala.nombre;

    final amarre = Amarre(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      fecha: DateTime.now(),
      km: 87,
      duracion: '2h 34m',
      participantes: ['@noe', '@rider_mx', '@moto_cdmx'],
      zona: 'Reciente',
    );

    ref.read(amarresProvider.notifier).addAmarre(amarre);
    await N4Haptics.heavy();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Registro guardado. ¡Buena salida!',
          style: Noray4TextStyles.body.copyWith(
            color: Noray4Colors.darkPrimary,
          ),
        ),
        backgroundColor: Noray4Colors.darkSurfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: Noray4Radius.secondary,
          side: const BorderSide(
            color: Noray4Colors.darkOutlineVariant,
            width: 0.5,
          ),
        ),
      ),
    );

    context.go('/registros');
  }

  @override
  Widget build(BuildContext context) {
    final sala = ref.watch(salaProvider(widget.salaId));
    final notifier = ref.read(salaProvider(widget.salaId).notifier);
    final nombre =
        (widget.salaData?['nombre'] as String?)?.isNotEmpty == true
            ? widget.salaData!['nombre'] as String
            : sala.nombre;

    return Scaffold(
      backgroundColor: Noray4Colors.darkBackground,
      body: Column(
        children: [
          _SalaAppBar(nombre: nombre, onCerrar: _cerrarSalida),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Noray4Spacing.s6),
            child: SalaTabBar(
              activeTab: sala.activeTab,
              onTabSelected: notifier.switchTab,
            ),
          ),
          Expanded(
            child: _TabContent(sala: sala, notifier: notifier),
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ─────────────────────────────────────────────────────────────────

class _SalaAppBar extends StatelessWidget {
  final String nombre;
  final VoidCallback onCerrar;

  const _SalaAppBar({required this.nombre, required this.onCerrar});

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
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(Symbols.arrow_back,
                      size: 24, color: Noray4Colors.darkPrimary),
                ),
                const SizedBox(width: Noray4Spacing.s4),
                Text(
                  nombre,
                  style: Noray4TextStyles.wordmark.copyWith(
                    color: Noray4Colors.darkPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.03 * 18,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: onCerrar,
              child: const Icon(
                Symbols.flag,
                size: 24,
                color: Noray4Colors.darkPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Content ─────────────────────────────────────────────────────────────

class _TabContent extends ConsumerWidget {
  final SalaState sala;
  final SalaNotifier notifier;

  const _TabContent({required this.sala, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (sala.activeTab) {
      case SalaTab.mapa:
        return MapTab(
          sala: sala,
          onPttPressed: () => notifier.setPtt(true),
          onPttReleased: () => notifier.setPtt(false),
        );
      case SalaTab.chat:
        return _ChatTab(sala: sala, notifier: notifier);
      case SalaTab.voz:
        return VozTab(
          sala: sala,
          onPttPressed: () => notifier.setPtt(true),
          onPttReleased: () => notifier.setPtt(false),
        );
      case SalaTab.archivos:
        return const ArchivosTab();
    }
  }
}

class _ChatTab extends StatelessWidget {
  final SalaState sala;
  final SalaNotifier notifier;

  const _ChatTab({required this.sala, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(Noray4Spacing.s6),
            reverse: true,
            itemCount: sala.messages.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: Noray4Spacing.s8),
            itemBuilder: (_, i) {
              final reversed = sala.messages.reversed.toList();
              return ChatBubble(message: reversed[i]);
            },
          ),
        ),
        ChatInputBar(onSend: notifier.sendMessage),
        const SizedBox(height: Noray4Spacing.s2),
      ],
    );
  }
}

// ─── Bottom Sheet Cerrar Salida ───────────────────────────────────────────────

class _CerrarSalidaSheet extends StatelessWidget {
  const _CerrarSalidaSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Noray4Colors.darkOutlineVariant, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Noray4Spacing.s6,
        Noray4Spacing.s4,
        Noray4Spacing.s6,
        Noray4Spacing.s6 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Noray4Colors.darkOutlineVariant,
              borderRadius: Noray4Radius.pill,
            ),
          ),
          const SizedBox(height: Noray4Spacing.s6),

          // Ícono
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Noray4Colors.darkSurfaceContainerHighest,
              borderRadius: Noray4Radius.secondary,
              border: Border.all(
                color: Noray4Colors.darkOutlineVariant,
                width: 0.5,
              ),
            ),
            child: const Icon(
              Symbols.flag,
              size: 22,
              color: Noray4Colors.darkPrimary,
            ),
          ),
          const SizedBox(height: Noray4Spacing.s4),

          // Título
          Text(
            '¿Cerrar esta salida?',
            style: Noray4TextStyles.headlineM.copyWith(
              color: Noray4Colors.darkPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Noray4Spacing.s2),

          // Subtítulo
          Text(
            'Se generará un registro con el recorrido de hoy.',
            style: Noray4TextStyles.body.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Noray4Spacing.s8),

          // Botón confirmar
          _SheetButton(
            label: 'Cerrar y guardar registro',
            primary: true,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: Noray4Spacing.s2),

          // Botón cancelar
          _SheetButton(
            label: 'Seguir rodando',
            primary: false,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatefulWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _SheetButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  State<_SheetButton> createState() => _SheetButtonState();
}

class _SheetButtonState extends State<_SheetButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: widget.primary
                ? Noray4Colors.darkPrimary
                : Colors.transparent,
            borderRadius: Noray4Radius.primary,
            border: widget.primary
                ? null
                : Border.all(
                    color: Noray4Colors.darkOutlineVariant,
                    width: 0.5,
                  ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: Noray4TextStyles.body.copyWith(
                color: widget.primary
                    ? Noray4Colors.darkBackground
                    : Noray4Colors.darkSecondary,
                fontWeight:
                    widget.primary ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
