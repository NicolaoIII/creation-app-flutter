import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/auth_state.dart';
import '../features/auth/screens/unified_entry_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/admin_dashboard.dart';
import '../features/dashboard/screens/superadmin_dashboard.dart';
import '../features/dashboard/screens/teacher_dashboard.dart';
import '../features/dashboard/screens/parent_dashboard.dart';
import '../features/misc/loading_screen.dart';
import '../features/misc/pending_setup_screen.dart';
import '../test_firebase_screen.dart';

import '../features/codes/screens/generate_signup_code_screen.dart';

import '../features/schools/screens/schools_list_screen.dart';
import '../features/schools/screens/add_school_screen.dart';

GoRouter createRouter(BuildContext context) {
  final auth = context.read<AuthState>();

  String? roleTarget() {
    final p = auth.profile;
    if (p == null) return null; // profile unknown (briefly during load)
    switch (p.userType) {
      case 'superadmin':
        return '/superadmin';
      case 'admin':
        return '/admin';
      case 'teacher':
        return '/teacher';
      case 'parent':
        return '/parent';
      case 'pending':
      default:
        return '/pending';
    }
  }

  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth, // rebuild router when auth/profile changes
    redirect: (ctx, state) {
      final loggedIn = auth.user != null;
      final loc = state.matchedLocation;

      // Public routes allowed when logged out
      const publicPaths = {'/', '/signup', '/login', '/test'};

      // Not logged in → only allow public paths
      if (!loggedIn) {
        return publicPaths.contains(loc) ? null : '/';
      }

      // Logged in but profile still loading → park on /loading
      if (auth.profileLoading) {
        return loc == '/loading' ? null : '/loading';
      }

      // Profile finished loading and we're on /loading → go to role (or pending)
      if (!auth.profileLoading && loc == '/loading') {
        return roleTarget() ?? '/pending';
      }

      // Logged in & on a public route → send to role
      if (publicPaths.contains(loc)) {
        return roleTarget() ?? '/pending';
      }

      // If on a role route, make sure it matches current role
      if (loc.startsWith('/superadmin') ||
          loc.startsWith('/admin') ||
          loc.startsWith('/teacher') ||
          loc.startsWith('/parent') ||
          loc.startsWith('/pending')) {
        final target = roleTarget() ?? '/pending';
        return loc == target ? null : target;
      }

      // Otherwise allow
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const UnifiedEntryScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: '/codes',
        builder: (_, __) => const GenerateSignupCodeScreen(),
      ),
      GoRoute(path: '/loading', builder: (_, __) => const LoadingScreen()),
      GoRoute(path: '/pending', builder: (_, __) => const PendingSetupScreen()),
      GoRoute(
        path: '/superadmin',
        builder: (_, __) => const SuperAdminDashboard(),
      ),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard()),
      GoRoute(path: '/teacher', builder: (_, __) => const TeacherDashboard()),
      GoRoute(path: '/parent', builder: (_, __) => const ParentDashboard()),
      GoRoute(path: '/test', builder: (_, __) => const TestFirebaseScreen()),
      GoRoute(path: '/schools', builder: (_, __) => const SchoolsListScreen()),
      GoRoute(
        path: '/schools/new',
        builder: (_, __) => const AddSchoolScreen(),
      ),
    ],
  );
}
