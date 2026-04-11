import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:noray4/core/network/api_client.dart';
import 'package:noray4/core/network/api_endpoints.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class UserOut {
  final String id;
  final String email;
  final String displayName;
  final bool isGuest;
  final bool isActive;

  const UserOut({
    required this.id,
    required this.email,
    required this.displayName,
    this.isGuest = false,
    this.isActive = true,
  });

  factory UserOut.fromJson(Map<String, dynamic> json) => UserOut(
        id: json['_id'] as String,
        email: json['email'] as String? ?? '',
        displayName: json['display_name'] as String,
        isGuest: json['is_guest'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
      );
}

// ── Repository ───────────────────────────────────────────────────────────────

class AuthRepository {
  final _dio = ApiClient.instance.dio;
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  /// Crea cuenta con email + contraseña. Persiste el token recibido.
  Future<UserOut> register(
      String email, String password, String displayName) async {
    final res = await _dio.post(ApiEndpoints.register, data: {
      'email': email,
      'password': password,
      'display_name': displayName,
    });
    await _saveToken(res.data);
    return getMe();
  }

  /// Login con email + contraseña. Persiste el token recibido.
  Future<UserOut> login(String email, String password) async {
    final res = await _dio.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    await _saveToken(res.data);
    return getMe();
  }

  /// Cierra sesión en el backend y borra el token local.
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // logout es semántico; borramos token local aunque el backend falle
    }
    await _storage.delete(key: _tokenKey);
  }

  /// Retorna el usuario autenticado según el JWT almacenado.
  Future<UserOut> getMe() async {
    final res = await _dio.get(ApiEndpoints.me);
    return UserOut.fromJson(res.data as Map<String, dynamic>);
  }

  /// Obtiene un token de invitado (TTL 24h) y lo persiste.
  Future<UserOut> guestToken() async {
    final res = await _dio.post(ApiEndpoints.guestToken);
    await _saveToken(res.data);
    return getMe();
  }

  /// Login / registro con Google. Intenta login primero; si 401, registra.
  /// La contraseña es 'Noray4_' + primeros 28 chars del idToken (34 chars total).
  Future<UserOut> loginWithGoogle(
      String idToken, String email, String displayName) async {
    final password = 'Noray4_${idToken.substring(0, 28)}';

    debugPrint('GOOGLE → email:$email name:$displayName pass_len:${password.length}');

    // 1. Intenta login
    try {
      return await login(email, password);
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) rethrow;
    }

    // 2. Si 401 → registra
    debugPrint('REGISTER → email:$email name:$displayName pass_len:${password.length}');
    final res = await _dio.post(ApiEndpoints.register, data: {
      'email': email,
      'password': password,
      'display_name': displayName,
    });
    await _storage.write(
      key: _tokenKey,
      value: res.data['access_token'] as String,
    );
    return getMe();
  }

  Future<void> _saveToken(dynamic data) async {
    final token = data['access_token'] as String;
    await _storage.write(key: _tokenKey, value: token);
  }
}
