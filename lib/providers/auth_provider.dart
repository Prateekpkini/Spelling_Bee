import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppUser {
  final String email;
  AppUser(this.email);
}

/// Provider tracking the current auth state (mocking the Firebase stream).
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

    // Artificial network delay
    await Future.delayed(const Duration(seconds: 1));

    final validLogins = {
      'everest@gmail.com': 'admin@123',
      'developer@gmail.com': 'dev@123',
      'tester@gmail.com': 'test@123',
    };

    if (validLogins.containsKey(email) && validLogins[email] == password) {
      final user = AppUser(email);
      state = AsyncValue.data(user);
      _ref.read(authStateProvider.notifier).state = AsyncValue.data(user);
    } else {
      final error = Exception('invalid-credential');
      state = AsyncValue.error(error, StackTrace.current);
      // Revert auth state back to unauthenticated on failure
      _ref.read(authStateProvider.notifier).state = const AsyncValue.data(null);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.data(null);
    _ref.read(authStateProvider.notifier).state = const AsyncValue.data(null);
  }
}
