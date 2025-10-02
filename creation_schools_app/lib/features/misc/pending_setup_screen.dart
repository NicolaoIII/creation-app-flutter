import 'package:flutter/material.dart';
class PendingSetupScreen extends StatelessWidget {
  const PendingSetupScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Your account is awaiting setup.\nAn admin will assign your role/school.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
