import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/core/router/app_router.dart';
import 'package:noray4/core/theme/noray4_theme.dart';

void main() {
  runApp(const ProviderScope(child: Noray4App()));
}

class Noray4App extends ConsumerStatefulWidget {
  const Noray4App({super.key});

  @override
  ConsumerState<Noray4App> createState() => _Noray4AppState();
}

class _Noray4AppState extends ConsumerState<Noray4App> {
  @override
  void initState() {
    super.initState();
    // Restaura sesión antes de que GoRouter evalúe el guard de autenticación.
    ref.read(authProvider.notifier).init();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Noray4',
      debugShowCheckedModeBanner: false,
      theme: Noray4Theme.light,
      darkTheme: Noray4Theme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
