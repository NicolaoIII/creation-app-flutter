import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../app/auth_state.dart';
import '../features/auth/screens/unified_entry_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/dashboard/screens/admin_dashboard.dart';
import '../test_firebase_screen.dart';

GoRouter createRouter(BuildContext context) {
  final auth = context.read<AuthState>();
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth, // rebuild on auth changes
    redirect: (ctx, state) {
      final loggedIn = auth.user != null;
      final goingToAdmin = state.matchedLocation.startsWith('/admin');
      if (!loggedIn && goingToAdmin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const UnifiedEntryScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard()),
      GoRoute(path: '/test', builder: (_, __) => const TestFirebaseScreen()),
    ],
  );
}
