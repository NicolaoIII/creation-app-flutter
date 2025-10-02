import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/brand_logo.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '(none)';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: const [
            BrandLogo(height: 40),
            SizedBox(width: 10),
            Text('Admin Dashboard'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/codes'),
            child: const Text('Signup Codes'),
          ),

          TextButton(
            onPressed: () => context.go('/schools'),
            child: const Text('Schools'),
          ),


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
        child: Text('Hello Admin (uid: $uid)'),
      ),
    );
  }
}
