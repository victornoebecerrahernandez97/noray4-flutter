class CurrentUser {
  final String id;
  final String email;
  final String nombre;
  final String ciudad;
  final String bio;
  final bool isGuest;

  const CurrentUser({
    required this.id,
    this.email = '',
    required this.nombre,
    this.ciudad = '',
    this.bio = '',
    this.isGuest = false,
  });

  static const guest =
      CurrentUser(id: 'guest', nombre: 'Invitado', isGuest: true);

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
        id: json['_id'] as String,
        email: json['email'] as String? ?? '',
        nombre: json['display_name'] as String,
        isGuest: json['is_guest'] as bool? ?? false,
      );

  CurrentUser copyWith({String? nombre, String? ciudad, String? bio}) =>
      CurrentUser(
        id: id,
        email: email,
        nombre: nombre ?? this.nombre,
        ciudad: ciudad ?? this.ciudad,
        bio: bio ?? this.bio,
        isGuest: isGuest,
      );
}

class AuthState {
  final CurrentUser? user;
  final bool onboardingDone;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.onboardingDone = false,
    this.isLoading = true,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    CurrentUser? user,
    bool? onboardingDone,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        user: user ?? this.user,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
