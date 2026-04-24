class CurrentUser {
  final String id;
  final String riderId;
  final String email;
  final String nombre;
  final String ciudad;
  final String bio;
  final String? avatarUrl;
  final bool isGuest;

  const CurrentUser({
    required this.id,
    this.riderId = '',
    this.email = '',
    required this.nombre,
    this.ciudad = '',
    this.bio = '',
    this.avatarUrl,
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

  CurrentUser copyWith({
    String? nombre,
    String? ciudad,
    String? bio,
    String? riderId,
    String? avatarUrl,
  }) =>
      CurrentUser(
        id: id,
        riderId: riderId ?? this.riderId,
        email: email,
        nombre: nombre ?? this.nombre,
        ciudad: ciudad ?? this.ciudad,
        bio: bio ?? this.bio,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isGuest: isGuest,
      );
}

class AuthState {
  final CurrentUser? user;
  final bool onboardingDone;
  final bool pendingAvatarSetup;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.onboardingDone = false,
    this.pendingAvatarSetup = false,
    this.isLoading = true,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    CurrentUser? user,
    bool? onboardingDone,
    bool? pendingAvatarSetup,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        user: user ?? this.user,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        pendingAvatarSetup: pendingAvatarSetup ?? this.pendingAvatarSetup,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
