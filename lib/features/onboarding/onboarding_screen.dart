import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/auth/auth_models.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/core/auth/google_auth_service.dart';
import 'package:noray4/core/services/haptics.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/onboarding/widgets/avatar_step.dart';

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
    'assets/images/onboarding/step-1.jpg',
  ),
  _Step(
    'Rodando en el mismo canal...',
    'Mapa en vivo, voz PTT y chat para que nadie se pierda en la ruta.',
    'assets/images/onboarding/step-2.jpg',
  ),
  _Step(
    '¡A ver las fotos!',
    'Cada salida queda guardada. Tus kilómetros, tu ruta, tu tripulación y un álbum listo para descargar.',
    'assets/images/onboarding/step-3.jpg',
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Phase { intro, methodPick, emailForm, avatar }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  int _page = 0;
  _Phase _phase = _Phase.intro;
  bool _isGuestLoading = false;
  bool _isGoogleLoading = false;

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
      // Cambio de paso dentro del intro — no reseteamos la animación global,
      // el AnimatedSwitcher interno anima solo el hero y los dots morphean.
      setState(() => _page++);
    } else {
      setState(() => _phase = _Phase.methodPick);
      _stepCtrl.forward(from: 0);
    }
  }

  void _prev() {
    if (_page == 0) return;
    N4Haptics.selection();
    setState(() => _page--);
  }

  void _goTo(_Phase p) {
    N4Haptics.selection();
    setState(() => _phase = p);
    _stepCtrl.forward(from: 0);
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
      if (auth.isAuthenticated) {
        setState(() => _phase = _Phase.avatar);
        _stepCtrl.forward(from: 0);
      }
    } catch (_) {
      // error en authProvider
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
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
              child: switch (_phase) {
                _Phase.avatar => AvatarStep(
                    onDone: () {
                      if (!mounted) return;
                      ref.read(authProvider.notifier).finishAvatarSetup();
                      context.go('/home');
                    },
                  ),
                _Phase.emailForm => _AccountSetupView(
                    onGuest: _enterAsGuest,
                    isGuestLoading: _isGuestLoading,
                    onBack: () => _goTo(_Phase.methodPick),
                    onNeedAvatar: () {
                      if (!mounted) return;
                      setState(() => _phase = _Phase.avatar);
                      _stepCtrl.forward(from: 0);
                    },
                  ),
                _Phase.methodPick => _MethodPickView(
                    onGoogle: _loginWithGoogle,
                    onEmail: () => _goTo(_Phase.emailForm),
                    onGuest: _enterAsGuest,
                    isGoogleLoading: _isGoogleLoading,
                    isGuestLoading: _isGuestLoading,
                  ),
                _Phase.intro => _StepView(
                    step: _steps[_page],
                    page: _page,
                    total: _steps.length,
                    onNext: _next,
                    onPrev: _prev,
                    onGuest: _enterAsGuest,
                    isGuestLoading: _isGuestLoading,
                  ),
              },
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
  final VoidCallback onPrev;
  final VoidCallback onGuest;
  final bool isGuestLoading;

  const _StepView({
    required this.step,
    required this.page,
    required this.total,
    required this.onNext,
    required this.onPrev,
    required this.onGuest,
    required this.isGuestLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -250) {
          onNext();
        } else if (v > 250) {
          onPrev();
        }
      },
      child: Column(
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 520),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(
                begin: const Offset(0.10, 0),
                end: Offset.zero,
              ).animate(anim);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.center,
              children: [...previous, ?current],
            ),
            child: _HeroImage(
              key: ValueKey(step.imageUrl),
              imageUrl: step.imageUrl,
              step: step,
            ),
          ),
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
                label: page < total - 1 ? 'Siguiente' : 'Empezar',
                onTap: onNext,
              ),
              const SizedBox(height: Noray4Spacing.s2),
              _GhostButton(onTap: onGuest, isLoading: isGuestLoading),
            ],
          ),
        ),
      ],
      ),
    );
  }
}

// ─── Account Setup View (paso 3) ─────────────────────────────────────────────

class _AccountSetupView extends ConsumerStatefulWidget {
  final VoidCallback onGuest;
  final bool isGuestLoading;
  final VoidCallback onBack;
  final VoidCallback onNeedAvatar;

  const _AccountSetupView({
    required this.onGuest,
    required this.isGuestLoading,
    required this.onBack,
    required this.onNeedAvatar,
  });

  @override
  ConsumerState<_AccountSetupView> createState() => _AccountSetupViewState();
}

class _AccountSetupViewState extends ConsumerState<_AccountSetupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
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
    if (auth.isAuthenticated) widget.onNeedAvatar();
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
              _BrandHeader(onBack: widget.onBack),
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
              _PrimaryButton(
                label: 'Crear cuenta',
                onTap: _register,
                isLoading: isRegistering,
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
              _PrimaryButton(
                label: 'Entrar',
                onTap: _login,
                isLoading: isLoading,
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
  final VoidCallback? onBack;
  const _BrandHeader({this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (onBack != null)
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Noray4Colors.darkSurfaceContainerLow,
                borderRadius: Noray4Radius.secondary,
                border: Border.all(
                  color: Noray4Colors.darkOutlineVariant,
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Symbols.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: onBack != null ? Noray4Spacing.s4 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Noray',
                      style: Noray4TextStyles.wordmark.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.05 * 28,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '⁴',
                      style: Noray4TextStyles.wordmark.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Noray4Colors.darkAccent,
                      ),
                    ),
                  ],
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
          ),
        ),
        if (onBack == null)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Noray4Colors.darkAccent,
              borderRadius: Noray4Radius.secondary,
            ),
            child: const Icon(
              Symbols.explore,
              color: Color(0xFF0C1C20),
              size: 22,
            ),
          ),
      ],
    );
  }
}

// ─── Method Pick View ────────────────────────────────────────────────────────

class _MethodPickView extends StatelessWidget {
  final Future<void> Function() onGoogle;
  final VoidCallback onEmail;
  final VoidCallback onGuest;
  final bool isGoogleLoading;
  final bool isGuestLoading;

  const _MethodPickView({
    required this.onGoogle,
    required this.onEmail,
    required this.onGuest,
    required this.isGoogleLoading,
    required this.isGuestLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Noray4Spacing.s6,
        Noray4Spacing.s4,
        Noray4Spacing.s6,
        Noray4Spacing.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandHeader(),
          const SizedBox(height: Noray4Spacing.s8 + Noray4Spacing.s4),
          Text(
            'Únete a\nla flota',
            style: Noray4TextStyles.headlineL.copyWith(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.04 * 40,
              height: 1.05,
            ),
          ),
          const SizedBox(height: Noray4Spacing.s2),
          Text(
            'Elige cómo quieres registrarte.',
            style: Noray4TextStyles.body.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant,
              height: 1.5,
            ),
          ),
          const Spacer(),
          _GoogleButton(
            onTap: () => onGoogle(),
            isLoading: isGoogleLoading,
          ),
          const SizedBox(height: Noray4Spacing.s2),
          _OutlineMethodButton(
            label: 'Continuar con email',
            icon: Symbols.alternate_email,
            onTap: onEmail,
          ),
          const SizedBox(height: Noray4Spacing.s4),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 0.5,
                  color: Noray4Colors.darkOutlineVariant,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: Noray4Spacing.s4),
                child: Text(
                  'O',
                  style: Noray4TextStyles.label.copyWith(
                    color: Noray4Colors.darkOutline,
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
          const SizedBox(height: Noray4Spacing.s2),
          _GhostButton(onTap: onGuest, isLoading: isGuestLoading),
          const SizedBox(height: Noray4Spacing.s2),
        ],
      ),
    );
  }
}

class _OutlineMethodButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineMethodButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Noray4Colors.darkSurfaceContainerLow,
          borderRadius: Noray4Radius.primary,
          border: Border.all(
            color: Noray4Colors.darkOutlineVariant,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: Noray4TextStyles.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Image ──────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  final _Step step;

  const _HeroImage({super.key, required this.imageUrl, required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Noray4Spacing.s2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
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
    const inactiveW = 6.0;
    const activeW = 32.0;
    const gap = Noray4Spacing.s2;
    return Row(
      children: [
        for (int i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: gap),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            tween: Tween(end: i == active ? 1.0 : 0.0),
            builder: (context, t, _) {
              return Container(
                height: 4,
                width: inactiveW + (activeW - inactiveW) * t,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    Noray4Colors.darkOutlineVariant,
                    Colors.white,
                    t,
                  ),
                  borderRadius: Noray4Radius.pill,
                ),
              );
            },
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
  final bool isLoading;
  const _PrimaryButton({required this.label, required this.onTap, this.isLoading = false});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: widget.isLoading ? null : () => setState(() => _pressed = false),
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
              color: Noray4Colors.darkAccent,
              borderRadius: Noray4Radius.primary,
              boxShadow: widget.isLoading
                  ? const []
                  : [
                      BoxShadow(
                        color: Noray4Colors.darkAccent.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: -4,
                      ),
                    ],
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
                      widget.label,
                      style: Noray4TextStyles.body.copyWith(
                        color: const Color(0xFF0C1C20),
                        fontWeight: FontWeight.w700,
                      ),
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
