import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spelling_bee/services/api_service.dart';

class AppUser {
  final String id;
  final String role;
  final String name;
  final String email;
  final String? jwtToken;

  AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.jwtToken,
  });
}

/// Provider tracking the current auth state
final authStateProvider = StateProvider<AsyncValue<AppUser?>>((ref) {
  return const AsyncValue.data(null);
});

/// Notifier for login/logout operations.
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    _ref.read(authStateProvider.notifier).state = const AsyncValue.loading();

    try {
      final response = await apiService.login(email, password);
      final token = response['token'];
      apiService.setToken(token);

      final userData = response['user'];
      final user = AppUser(
        id: userData['id']?.toString() ?? '',
        role: userData['role'] ?? '',
        name: userData['name'] ?? '',
        email: userData['email'] ?? '',
        jwtToken: token,
      );

      state = AsyncValue.data(user);
      _ref.read(authStateProvider.notifier).state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      _ref.read(authStateProvider.notifier).state = const AsyncValue.data(null);
    }
  }

  Future<void> signOut() async {
    apiService.clearToken();
    state = const AsyncValue.data(null);
    _ref.read(authStateProvider.notifier).state = const AsyncValue.data(null);
  }
}
