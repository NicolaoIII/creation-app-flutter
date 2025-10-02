import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/brand_logo.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

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
            Text('Parent Dashboard'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/students/mine'),
            child: const Text('My Children'),
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
      body: Center(child: Text('Welcome, parent (uid: $uid)')),
    );
  }
}
