import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/brand_logo.dart';

class UnifiedEntryScreen extends StatelessWidget {
  const UnifiedEntryScreen({super.key});

  Future<void> _demoLogin(BuildContext context) async {
    await FirebaseAuth.instance.signInAnonymously();
    if (context.mounted) context.go('/admin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: const [
            BrandLogo(height: 40),
            SizedBox(width: 10),
            Text('Creation Schools — Entry'),
          ],
        ),
      ),
      body: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Login (email/password)'),
            ),

            ElevatedButton(
              onPressed: () => _demoLogin(context),
              child: const Text('Continue (demo) to Admin'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/signup'),
              child: const Text('Go to Signup'),
            ),
            TextButton(
              onPressed: () => context.go('/test'),
              child: const Text('Open Firebase Test'),
            ),
          ],
        ),
      ),
    );
  }
}
