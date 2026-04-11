import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:noray4/core/network/api_client.dart';
import 'package:noray4/core/network/api_endpoints.dart';

class UserOut {
  final String id;
  final String email;
  final String displayName;
  final bool isGuest;

  const UserOut({
    required this.id,
    required this.email,
    required this.displayName,
    this.isGuest = false,
  });

  factory UserOut.fromJson(Map<String, dynamic> json) => UserOut(
        id: json['_id'] as String,
        email: json['email'] as String? ?? '',
        displayName: json['display_name'] as String,
        isGuest: json['is_guest'] as bool? ?? false,
      );
}

class AuthService {
  final _dio = ApiClient.instance.dio;
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  /// Registro con email + contraseña. Retorna el usuario creado.
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

  /// Login con email + contraseña.
  Future<UserOut> login(String email, String password) async {
    final res = await _dio.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    await _saveToken(res.data);
    return getMe();
  }

  /// Cierra sesión y borra el token local.
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // logout es semántico; borramos el token local sin importar el resultado
    }
    await _storage.delete(key: _tokenKey);
  }

  /// Retorna el usuario autenticado desde el JWT actual.
  Future<UserOut> getMe() async {
    final res = await _dio.get(ApiEndpoints.me);
    return UserOut.fromJson(res.data as Map<String, dynamic>);
  }

  /// Genera un token de invitado con TTL 24h.
  Future<UserOut> getGuestToken() async {
    final res = await _dio.post(ApiEndpoints.guestToken);
    await _saveToken(res.data);
    return getMe();
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }

  Future<void> _saveToken(dynamic data) async {
    final token = data['access_token'] as String;
    await _storage.write(key: _tokenKey, value: token);
  }
}
