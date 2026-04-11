import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/auth/auth_models.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/core/auth/google_auth_service.dart';
import 'package:noray4/core/services/haptics.dart';
import 'package:noray4/core/theme/noray4_theme.dart';

// ─── Datos de los 3 pasos ────────────────────────────────────────────────────

class _Step {
  final String headline;
  final String body;
  final String imageUrl;
  const _Step(this.headline, this.body, this.imageUrl);
}

const _steps = [
  _Step(
    'Convoca a la flota...',
    'Crea salidas, comparte tu ruta en tiempo real y rueda siempre conectado con tu gente.',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
  ),
  _Step(
    'Rodando en el mismo canal...',
    'Mapa en vivo, voz PTT y chat para que nadie se pierda en la ruta.',
    'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=800',
  ),
  _Step(
    '¡A ver las fotos!',
    'Cada salida queda guardada. Tus kilómetros, tu ruta, tu tripulación y un álbum listo para descargar.',
    'https://images.unsplash.com/photo-1449426468159-d96dbf08f19f?w=800',
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  int _page = 0;
  bool _showNameInput = false;
  bool _isGuestLoading = false;

  // Fondo animado — ciclo de 6 s entre 3 tonos oscuros
  late final AnimationController _bgCtrl;
  late final Animation<Color?> _bgColor;

  // Transición entre pasos — fade + slide horizontal
  late final AnimationController _stepCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _bgColor = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFF000000),
          end: const Color(0xFF1A1A1A),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFF1A1A1A),
          end: const Color(0xFF0D0D0D),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFF0D0D0D),
          end: const Color(0xFF000000),
        ),
        weight: 1,
      ),
    ]).animate(_bgCtrl);

    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    final curved = CurvedAnimation(
      parent: _stepCtrl,
      curve: Curves.easeInOutCubic,
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(curved);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(curved);

    _stepCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _stepCtrl.dispose();
    super.dispose();
  }

  void _next() {
    N4Haptics.selection();
    if (_page < _steps.length - 1) {
      setState(() => _page++);
    } else {
      setState(() => _showNameInput = true);
    }
    _stepCtrl.forward(from: 0);
  }

  Future<void> _enterAsGuest() async {
    if (_isGuestLoading) return;
    N4Haptics.light();
    setState(() => _isGuestLoading = true);
    await ref.read(authProvider.notifier).loginAsGuest();
    if (!mounted) return;
    setState(() => _isGuestLoading = false);
    final error = ref.read(authProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFF2A2A29),
        ),
      );
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgColor,
      builder: (context, _) => Scaffold(
        backgroundColor: _bgColor.value ?? const Color(0xFF000000),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: _showNameInput
                  ? _AccountSetupView(
                      onGuest: _enterAsGuest,
                      isGuestLoading: _isGuestLoading,
                    )
                  : _StepView(
                      step: _steps[_page],
                      page: _page,
                      total: _steps.length,
                      onNext: _next,
                      onGuest: _enterAsGuest,
                      isGuestLoading: _isGuestLoading,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Step View ───────────────────────────────────────────────────────────────

class _StepView extends StatelessWidget {
  final _Step step;
  final int page;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onGuest;
  final bool isGuestLoading;

  const _StepView({
    required this.step,
    required this.page,
    required this.total,
    required this.onNext,
    required this.onGuest,
    required this.isGuestLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Noray4Spacing.s6,
            Noray4Spacing.s4,
            Noray4Spacing.s6,
            0,
          ),
          child: const _BrandHeader(),
        ),
        const SizedBox(height: Noray4Spacing.s4),
        Expanded(
          child: _HeroImage(imageUrl: step.imageUrl, step: step),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Noray4Spacing.s6,
            Noray4Spacing.s6,
            Noray4Spacing.s6,
            Noray4Spacing.s4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepDots(total: total, active: page),
              const SizedBox(height: Noray4Spacing.s6),
              _PrimaryButton(
                label: page < total - 1 ? 'Siguiente' : 'Crear mi cuenta',
                onTap: onNext,
              ),
              const SizedBox(height: Noray4Spacing.s2),
              _GhostButton(onTap: onGuest, isLoading: isGuestLoading),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Account Setup View (paso 3) ─────────────────────────────────────────────

class _AccountSetupView extends ConsumerStatefulWidget {
  final VoidCallback onGuest;
  final bool isGuestLoading;

  const _AccountSetupView({
    required this.onGuest,
    required this.isGuestLoading,
  });

  @override
  ConsumerState<_AccountSetupView> createState() => _AccountSetupViewState();
}

class _AccountSetupViewState extends ConsumerState<_AccountSetupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    if (_isGoogleLoading) return;
    N4Haptics.light();
    setState(() => _isGoogleLoading = true);
    try {
      final result = await GoogleAuthService().signIn();
      if (result == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }
      await ref.read(authProvider.notifier).loginWithGoogle(
            result['idToken']!,
            result['email']!,
            result['displayName']!,
          );
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) context.go('/home');
    } catch (_) {
      // error manejado por authProvider
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    N4Haptics.medium();
    await ref.read(authProvider.notifier).register(
      _emailCtrl.text.trim(),
      _passCtrl.text,
      _nameCtrl.text.trim().isEmpty ? 'Rider' : _nameCtrl.text.trim(),
    );
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) context.go('/home');
  }

  void _showLoginSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LoginSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isRegistering = auth.isLoading && !widget.isGuestLoading;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null &&
          next.error != prev?.error &&
          !widget.isGuestLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFF2A2A29),
          ),
        );
      }
    });

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Noray4Spacing.s6,
          Noray4Spacing.s4,
          Noray4Spacing.s6,
          0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandHeader(),
              const SizedBox(height: Noray4Spacing.s8),
              Text(
                '¿Cómo te conocen\ntus camaradas?',
                style: Noray4TextStyles.headlineL.copyWith(
                  color: Colors.white,
                  letterSpacing: -0.03 * 32,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: Noray4Spacing.s6),
              // Nombre (estilo container nativo del onboarding)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Noray4Spacing.s4,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Noray4Colors.darkSurfaceContainerLow,
                  borderRadius: Noray4Radius.secondary,
                  border: Border.all(
                    color: Noray4Colors.darkOutlineVariant,
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  style: Noray4TextStyles.headlineM.copyWith(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tu nombre de rider',
                    hintStyle: Noray4TextStyles.headlineM.copyWith(
                      color: Noray4Colors.darkOutline,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: Noray4Spacing.s2),
              _AuthField(
                controller: _emailCtrl,
                hint: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Email inválido' : null,
              ),
              const SizedBox(height: Noray4Spacing.s2),
              _AuthField(
                controller: _passCtrl,
                hint: 'Contraseña',
                obscure: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: Noray4Spacing.s8),
              _GoogleButton(
                onTap: _loginWithGoogle,
                isLoading: _isGoogleLoading,
              ),
              const SizedBox(height: Noray4Spacing.s2),
              isRegistering
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : _PrimaryButton(
                      label: 'Crear cuenta',
                      onTap: _register,
                    ),
              const SizedBox(height: Noray4Spacing.s2),
              Center(
                child: TextButton(
                  onPressed: isRegistering ? null : _showLoginSheet,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    overlayColor: Colors.transparent,
                  ),
                  child: Text(
                    'Ya tengo cuenta',
                    style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkSecondary,
                    ),
                  ),
                ),
              ),
              _GhostButton(
                onTap: widget.onGuest,
                isLoading: widget.isGuestLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Login Sheet ─────────────────────────────────────────────────────────────

class _LoginSheet extends ConsumerStatefulWidget {
  const _LoginSheet();

  @override
  ConsumerState<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends ConsumerState<_LoginSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    N4Haptics.medium();
    await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFF2A2A29),
          ),
        );
      }
      // Cierra el sheet; el router redirige /onboarding → /home automáticamente
      if (!next.isLoading &&
          next.isAuthenticated &&
          prev?.isAuthenticated != true) {
        Navigator.of(context).pop();
      }
    });

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Noray4Spacing.s6,
          Noray4Spacing.s4,
          Noray4Spacing.s6,
          Noray4Spacing.s6,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Color(0xFF474747), width: 0.5),
            left: BorderSide(color: Color(0xFF474747), width: 0.5),
            right: BorderSide(color: Color(0xFF474747), width: 0.5),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: Noray4Spacing.s6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF474747),
                    borderRadius: Noray4Radius.pill,
                  ),
                ),
              ),
              Text(
                'Entrar',
                style: Noray4TextStyles.headlineM.copyWith(color: Colors.white),
              ),
              const SizedBox(height: Noray4Spacing.s6),
              _AuthField(
                controller: _emailCtrl,
                hint: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Email inválido' : null,
              ),
              const SizedBox(height: Noray4Spacing.s2),
              _AuthField(
                controller: _passCtrl,
                hint: 'Contraseña',
                obscure: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: Noray4Spacing.s6),
              isLoading
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : _PrimaryButton(
                      label: 'Entrar',
                      onTap: () {
                        _login();
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Auth Field ──────────────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: Noray4TextStyles.body.copyWith(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Noray4Colors.darkSurfaceContainerLow,
        hintText: hint,
        hintStyle:
            Noray4TextStyles.body.copyWith(color: Noray4Colors.darkOutline),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Noray4Spacing.s4,
          vertical: 14,
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFE57373),
          fontSize: 11,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: Noray4Radius.secondary,
          borderSide: BorderSide(
            color: Noray4Colors.darkOutlineVariant,
            width: 0.5,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: Noray4Radius.secondary,
          borderSide: BorderSide(color: Colors.white38, width: 0.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: Noray4Radius.secondary,
          borderSide: BorderSide(color: Color(0xFFE57373), width: 0.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: Noray4Radius.secondary,
          borderSide: BorderSide(color: Color(0xFFE57373), width: 0.5),
        ),
      ),
    );
  }
}

// ─── Brand Header ────────────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Noray⁴',
              style: Noray4TextStyles.wordmark.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.05 * 28,
                color: Colors.white,
              ),
            ),
            Text(
              'CONECTA. RUEDA. VUELVE.',
              style: Noray4TextStyles.label.copyWith(
                color: Noray4Colors.darkOutline,
                letterSpacing: 0.08 * 10,
              ),
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: Noray4Radius.secondary,
          ),
          child: const Icon(
            Symbols.explore,
            color: Noray4Colors.darkBackground,
            size: 22,
          ),
        ),
      ],
    );
  }
}

// ─── Hero Image ──────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  final _Step step;

  const _HeroImage({required this.imageUrl, required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Noray4Spacing.s4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                color: Noray4Colors.darkSurfaceContainerLow,
                child: const Icon(
                  Symbols.image_not_supported,
                  color: Noray4Colors.darkOutlineVariant,
                  size: 48,
                ),
              ),
            ),
            // Overlay gradiente oscuro desde el centro hacia abajo
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.35, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
            ),
            // Texto sobre imagen
            Positioned(
              left: Noray4Spacing.s6,
              right: Noray4Spacing.s6,
              bottom: Noray4Spacing.s6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.headline,
                    style: Noray4TextStyles.headlineM.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: Noray4Spacing.s2),
                  Text(
                    step.body,
                    style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step Dots ───────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final int total;
  final int active;
  const _StepDots({required this.total, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: Noray4Spacing.s2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            width: i == active ? 28 : 6,
            decoration: BoxDecoration(
              color: i == active
                  ? Colors.white
                  : Noray4Colors.darkOutlineVariant,
              borderRadius: Noray4Radius.pill,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Primary Button ──────────────────────────────────────────────────────────

class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
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
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: Noray4Radius.primary,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: Noray4TextStyles.body.copyWith(
                color: Noray4Colors.darkBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Google Button ───────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const _GoogleButton({required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: Noray4Radius.primary,
          border: Border.all(
            color: const Color(0xFFD4D4D0),
            width: 0.5,
          ),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF111110),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.g_mobiledata,
                    color: Color(0xFF111110),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Continuar con Google',
                    style: Noray4TextStyles.body.copyWith(
                      color: const Color(0xFF111110),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Ghost Button ────────────────────────────────────────────────────────────

class _GhostButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const _GhostButton({required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: isLoading ? null : onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          overlayColor: Colors.transparent,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Column(
                children: [
                  Text(
                    'Entrar sin cuenta',
                    style: Noray4TextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Únete a una salida con QR',
                    style: Noray4TextStyles.bodySmall.copyWith(
                      color: Noray4Colors.darkOutline,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
