import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TestFirebaseScreen extends StatefulWidget {
  const TestFirebaseScreen({super.key});

  @override
  State<TestFirebaseScreen> createState() => _TestFirebaseScreenState();
}

class _TestFirebaseScreenState extends State<TestFirebaseScreen> {
  String _status = 'Not signed in';
  String _docValue = '(none)';

  Future<void> _signInAnon() async {
    setState(() => _status = 'Signing in…');
    await FirebaseAuth.instance.signInAnonymously();
    setState(() => _status = 'Signed in (anon)');
  }

  Future<void> _writeDoc() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.doc('tests/hello').set({
      'owner': uid,
      'value': 'Hello Firestore 👋',
      'ts': FieldValue.serverTimestamp(),
    });
    setState(() => _docValue = 'Wrote: Hello Firestore 👋');
  }

  Future<void> _readDoc() async {
    final snap = await FirebaseFirestore.instance.doc('tests/hello').get();
    setState(() => _docValue = 'Read: ${snap.data()?['value'] ?? '(missing)'}');
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _status = 'Signed out';
      _docValue = '(none)';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creation Schools — Firebase Smoke Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Auth status: $_status'),
            const SizedBox(height: 8),
            Text('Current UID: ${user?.uid ?? '(none)'}'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: _signInAnon,
                  child: const Text('Sign in (anon)'),
                ),
                ElevatedButton(
                  onPressed: _writeDoc,
                  child: const Text('Write Firestore'),
                ),
                ElevatedButton(
                  onPressed: _readDoc,
                  child: const Text('Read Firestore'),
                ),
                TextButton(onPressed: _signOut, child: const Text('Sign out')),
              ],
            ),
            const SizedBox(height: 24),
            Text(_docValue, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
