import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spelling_bee/providers/auth_provider.dart';
import 'package:spelling_bee/screens/admin/super_admin_dashboard.dart';
import 'package:spelling_bee/screens/examiner/login_screen.dart';
import 'package:spelling_bee/screens/examiner/dashboard_screen.dart';
import 'package:spelling_bee/screens/examiner/register_student_screen.dart';
import 'package:spelling_bee/screens/examiner/my_students_screen.dart';
import 'package:spelling_bee/screens/examiner/leaderboard_screen.dart';
import 'package:spelling_bee/screens/student/token_screen.dart';
import 'package:spelling_bee/screens/student/game_screen.dart';
import 'package:spelling_bee/screens/student/result_screen.dart';
import 'package:spelling_bee/screens/error_screen.dart';

/// A ChangeNotifier that listens to the authStateProvider and notifies
/// GoRouter when auth state changes so redirects are re-evaluated.
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(this._ref) {
    _ref.listen<AsyncValue<AppUser?>>(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
  final Ref _ref;
}

/// GoRouter provider with auth-aware routing.
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Base URL redirects to login
      if (state.uri.path == '/') return '/login';

      // Check if this is a student-facing route (starts with /play)
      final isPlayerRoute = state.uri.path.startsWith('/play');

      // Student routes don't require auth
      if (isPlayerRoute) return null;

      // For examiner routes, check auth dynamically
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isLoginRoute = state.uri.path == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) {
        final user = authState.value!;
        return user.role == 'superadmin' ? '/admin' : '/dashboard';
      }

      // If a superadmin tries to access examiner dashboard, redirect them to admin
      if (isLoggedIn && (state.uri.path == '/dashboard' || state.uri.path == '/my_students')) {
        if (authState.value!.role == 'superadmin') return '/admin';
      }

      // Guard admin route — only superadmins
      if (state.uri.path.startsWith('/admin')) {
        if (!isLoggedIn) return '/login';
        if (authState.value!.role != 'superadmin') return '/dashboard';
      }

      return null;
    },
    errorBuilder: (context, state) => ErrorScreen(
      message: 'Page not found: ${state.uri.path}',
    ),
    routes: [
      // ── Super Admin Routes ───────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (context, state) => const SuperAdminDashboard(),
      ),

      // ── Examiner Routes ──────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterStudentScreen(),
      ),
      GoRoute(
        path: '/my_students',
        builder: (context, state) => const MyStudentsScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),

      // ── Student Routes ───────────────────────────────────────────
      GoRoute(
        path: '/play',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          if (token == null || token.isEmpty) {
            return const ErrorScreen(
              message: 'No game token provided. Please use the link sent by your examiner.',
            );
          }
          return TokenScreen(token: token);
        },
      ),
      GoRoute(
        path: '/play/game/:studentId',
        builder: (context, state) {
          final studentId = state.pathParameters['studentId']!;
          return GameScreen(studentId: studentId);
        },
      ),
      GoRoute(
        path: '/play/result/:studentId',
        builder: (context, state) {
          final studentId = state.pathParameters['studentId']!;
          return ResultScreen(studentId: studentId);
        },
      ),
    ],
  );
});
