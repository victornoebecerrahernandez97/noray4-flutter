import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noray4/core/auth/auth_models.dart';
import 'package:noray4/core/auth/auth_repository.dart';
import 'package:noray4/features/perfil/services/riders_service.dart';

const _keyOnboarding = 'onboarding_done';

class AuthNotifier extends StateNotifier<AuthState> {
  final _repo = AuthRepository();
  final _riders = RidersService();

  AuthNotifier() : super(const AuthState());

  Future<({String id, String? avatarUrl})> _fetchRiderInfo() async {
    try {
      final rider = await _riders.getMyRider();
      debugPrint('[AUTH] riderId fetched: ${rider.id}');
      return (id: rider.id, avatarUrl: rider.avatarUrl);
    } catch (e) {
      debugPrint('[AUTH] _fetchRiderInfo ERROR: $e');
      return (id: '', avatarUrl: null);
    }
  }

  // ── Arranque ──────────────────────────────────────────────────────────────

  /// Llamado explícitamente desde main.dart antes de que GoRouter evalúe guards.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_keyOnboarding) ?? false;
    if (!done) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      final user = await _repo.getMe();
      final info = await _fetchRiderInfo();
      state = AuthState(
        user: CurrentUser(
          id: user.id,
          riderId: info.id,
          email: user.email,
          nombre: user.displayName,
          avatarUrl: info.avatarUrl,
          isGuest: user.isGuest,
        ),
        onboardingDone: true,
        isLoading: false,
      );
    } catch (_) {
      // Token expirado o inválido — vuelve a onboarding
      await prefs.remove(_keyOnboarding);
      state = const AuthState(isLoading: false);
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> register(
      String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.register(email, password, displayName);
      final info = await _fetchRiderInfo();
      await _setOnboardingDone();
      state = AuthState(
        user: CurrentUser(
          id: user.id,
          riderId: info.id,
          email: user.email,
          nombre: user.displayName,
          avatarUrl: info.avatarUrl,
        ),
        onboardingDone: true,
        pendingAvatarSetup: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.login(email, password);
      final info = await _fetchRiderInfo();
      await _setOnboardingDone();
      state = AuthState(
        user: CurrentUser(
          id: user.id,
          riderId: info.id,
          email: user.email,
          nombre: user.displayName,
          avatarUrl: info.avatarUrl,
        ),
        onboardingDone: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> loginWithGoogle(
      String idToken, String email, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.loginWithGoogle(idToken, email, displayName);
      final info = await _fetchRiderInfo();
      await _setOnboardingDone();
      state = AuthState(
        user: CurrentUser(
          id: user.id,
          riderId: info.id,
          email: user.email,
          nombre: user.displayName,
          avatarUrl: info.avatarUrl,
        ),
        onboardingDone: true,
        pendingAvatarSetup: info.avatarUrl == null || info.avatarUrl!.isEmpty,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> loginAsGuest() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.guestToken();
      final info = await _fetchRiderInfo();
      await _setOnboardingDone();
      state = AuthState(
        user: CurrentUser(
          id: user.id,
          riderId: info.id,
          email: user.email,
          nombre: user.displayName,
          avatarUrl: info.avatarUrl,
          isGuest: true,
        ),
        onboardingDone: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboarding);
    state = const AuthState(isLoading: false);
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get isAuthenticated => state.isAuthenticated;
  bool get isGuest => state.user?.isGuest ?? false;

  // ── Compat: onboarding actual (solo nombre, sin email) ───────────────────

  Future<void> createAccount(String nombre) async {
    await loginAsGuest();
    if (state.user != null) {
      state = state.copyWith(
        user: state.user!.copyWith(nombre: nombre.isEmpty ? 'Rider' : nombre),
      );
    }
  }

  Future<void> updateProfile({
    required String nombre,
    required String ciudad,
    required String bio,
  }) async {
    state = state.copyWith(
      user: state.user?.copyWith(nombre: nombre, ciudad: ciudad, bio: bio),
    );
  }

  /// Guarda avatar preset (URL de comunidad) en backend + estado.
  Future<void> setAvatarPreset(String url) async {
    try {
      final rider = await _riders.setAvatarUrl(url);
      state = state.copyWith(
        user: state.user?.copyWith(avatarUrl: rider.avatarUrl ?? url),
        pendingAvatarSetup: false,
      );
    } catch (e) {
      debugPrint('[AUTH] setAvatarPreset ERROR: $e');
      rethrow;
    }
  }

  /// Sube imagen desde galería/cámara y sincroniza el avatar.
  Future<void> uploadAvatarFile(String filePath) async {
    try {
      final rider = await _riders.uploadAvatarFile(filePath);
      state = state.copyWith(
        user: state.user?.copyWith(avatarUrl: rider.avatarUrl),
        pendingAvatarSetup: false,
      );
    } catch (e) {
      debugPrint('[AUTH] uploadAvatarFile ERROR: $e');
      rethrow;
    }
  }

  /// Cierra el paso de avatar sin elegir (Omitir).
  void finishAvatarSetup() {
    state = state.copyWith(pendingAvatarSetup: false);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarding, true);
  }

  String _parseError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
    }
    final msg = e.toString();
    if (msg.contains('409')) return 'El email ya está registrado.';
    if (msg.contains('401')) return 'Credenciales incorrectas.';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Sin conexión. Verifica tu red.';
    }
    return 'Ocurrió un error. Intenta de nuevo.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
