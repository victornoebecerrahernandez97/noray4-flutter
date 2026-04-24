import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/features/amarres/amarres_screen.dart';
import 'package:noray4/features/amarres/models/amarres_models.dart';
import 'package:noray4/features/amarres/screens/amarre_detalle_screen.dart';
import 'package:noray4/features/foro/foro_post_detail_screen.dart';
import 'package:noray4/features/foro/foro_screen.dart';
import 'package:noray4/features/home/home_screen.dart';
import 'package:noray4/features/home/screens/notificaciones_screen.dart';
import 'package:noray4/features/onboarding/onboarding_screen.dart';
import 'package:noray4/features/perfil/configuracion/configuracion_screen.dart';
import 'package:noray4/features/perfil/perfil_screen.dart';
import 'package:noray4/features/perfil/screens/editar_perfil_screen.dart';
import 'package:noray4/features/perfil/tripulacion/tripulacion_screen.dart';
import 'package:noray4/features/rutas/ruta_detail_screen.dart';
import 'package:noray4/features/rutas/rutas_screen.dart';
import 'package:noray4/features/sala/screens/crear_sala_screen.dart';
import 'package:noray4/features/sala/sala_screen.dart';
import 'package:noray4/shared/screens/main_shell.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, _) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authProvider);
    if (auth.isLoading) return null;
    final isOnboarding = state.matchedLocation.startsWith('/onboarding');
    if (!auth.onboardingDone && !isOnboarding) return '/onboarding';
    if (auth.pendingAvatarSetup && !isOnboarding) return '/onboarding';
    if (auth.onboardingDone && !auth.pendingAvatarSetup && isOnboarding) {
      return '/home';
    }
    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/notificaciones',
        name: 'notificaciones',
        builder: (context, state) => const NotificacionesScreen(),
      ),
      GoRoute(
        path: '/salida/nueva',
        name: 'crear-sala',
        builder: (context, state) => const CrearSalaScreen(),
      ),
      GoRoute(
        path: '/sala/:id',
        name: 'sala',
        builder: (context, state) => SalaScreen(
          salaId: state.pathParameters['id']!,
          salaData: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/amarres',
        name: 'amarres',
        builder: (context, state) => const AmarresScreen(),
      ),
      GoRoute(
        path: '/amarres/detalle',
        name: 'amarre-detalle',
        builder: (context, state) => AmarreDetalleScreen(
          amarre: state.extra as Amarre,
        ),
      ),
      GoRoute(
        path: '/rutas/:id',
        name: 'ruta-detail',
        builder: (context, state) =>
            RutaDetailScreen(rutaId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/foro',
        name: 'foro',
        builder: (context, state) => const ForoScreen(),
      ),
      GoRoute(
        path: '/foro/:id',
        name: 'post-detail',
        builder: (context, state) =>
            ForoPostDetailScreen(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tripulacion',
        name: 'tripulacion',
        builder: (context, state) => const TripulacionScreen(),
      ),
      GoRoute(
        path: '/configuracion',
        name: 'configuracion',
        builder: (context, state) => const ConfiguracionScreen(),
      ),
      GoRoute(
        path: '/perfil/editar',
        name: 'editar-perfil',
        builder: (context, state) => const EditarPerfilScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/rutas',
              name: 'rutas',
              builder: (context, state) => const RutasScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/registros',
              name: 'registros',
              builder: (context, state) => const AmarresScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/perfil',
              name: 'perfil',
              builder: (context, state) => const PerfilScreen(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      backgroundColor: Color(0xFF131312),
      body: Center(child: Text('404', style: TextStyle(color: Colors.white))),
    ),
  );
});
