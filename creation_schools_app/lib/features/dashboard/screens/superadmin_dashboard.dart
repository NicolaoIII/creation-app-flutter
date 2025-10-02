import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/auth_state.dart';
import '../../../core/widgets/brand_logo.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final p = auth.profile;
    final displayName = [
      if ((p?.firstName ?? '').isNotEmpty) p!.firstName,
      if ((p?.lastName  ?? '').isNotEmpty) p!.lastName,
    ].join(' ').trim();
    final fallback = FirebaseAuth.instance.currentUser?.email ?? 'SuperAdmin';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            const BrandLogo(height: 40),
            const SizedBox(width: 10),
            const Text('SuperAdmin Dashboard'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => context.go('/schools'), child: const Text('Schools')),
          TextButton(onPressed: () => context.go('/students'), child: const Text('Students')),
          TextButton(onPressed: () => context.go('/codes'), child: const Text('Signup Codes')),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/');
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome, ${displayName.isEmpty ? fallback : displayName}'),
      ),
    );
  }
}
