import '../models/user.dart';

abstract class AuthService {
  Stream<AppUser?> authStateChanges();
  Future<AppUser?> login({
    required String email,
    required String password,
    required UserRole role,
  });

  Future<AppUser?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? handlerRole,
    String? canteen,
  });

  Future<void> logout();

  AppUser? get currentUser;
}
