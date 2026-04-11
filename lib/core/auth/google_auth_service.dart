import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._();

  final _googleSignIn = GoogleSignIn(
    serverClientId:
        '296589404935-jujkds4oabk2qvcgcqltmbk2f125k6ff.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Inicia el flujo OAuth de Google. Retorna {idToken, email, displayName}
  /// o null si el usuario cancela.
  Future<Map<String, String>?> signIn() async {
    final account = await _googleSignIn.signIn();
    debugPrint('GOOGLE account: ${account?.email}');
    if (account == null) return null;
    final auth = await account.authentication;
    debugPrint('GOOGLE idToken: ${auth.idToken?.substring(0, 20)}');
    debugPrint('GOOGLE accessToken: ${auth.accessToken?.substring(0, 20)}');
    final idToken = auth.idToken ?? '';
    if (idToken.isEmpty) throw Exception('Google idToken vacío');
    return {
      'idToken': idToken,
      'email': account.email,
      'displayName': account.displayName ?? account.email.split('@')[0],
    };
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
