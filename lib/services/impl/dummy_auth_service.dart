import 'dart:async';

import '../../models/user.dart';
import '../auth_service.dart';

class DummyAuthService implements AuthService {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  DummyAuthService() {
    _controller.add(null);
  }

  @override
  Stream<AppUser?> authStateChanges() async* {
    // Always emit the current user state immediately when a listener subscribes
    // so that UI like the SplashScreen can react and navigate.
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser?> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final user = AppUser(
      id: email,
      name: role == UserRole.student ? 'Student User' : 'Handler User',
      email: email,
      role: role,
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? handlerRole,
    String? canteen,
  }) async {
    final user = AppUser(
      id: email,
      name: name,
      email: email,
      role: role,
      handlerRole: handlerRole,
      canteen: canteen,
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _controller.add(null);
  }
}
