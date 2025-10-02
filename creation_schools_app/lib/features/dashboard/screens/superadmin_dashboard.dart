import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/brand_logo.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '(none)';
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(children: const [BrandLogo(height: 40), SizedBox(width: 10), Text('SuperAdmin Dashboard')]),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/');
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: Center(child: Text('Hello SuperAdmin (uid: $uid)')),
    );
  }
}
