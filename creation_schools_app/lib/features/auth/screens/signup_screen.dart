import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _required(String? v, String field) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  String? _emailRule(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  String? _passwordRule(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    return null;
  }

  Future<void> _redeemSignupCode({
    required String code,
    required String uid,
  }) async {
    final fs = FirebaseFirestore.instance;

    await fs.runTransaction((tx) async {
      final codeRef = fs
          .collection('signupCodes')
          .doc(code.trim().toUpperCase());
      final codeSnap = await tx.get(codeRef);

      if (!codeSnap.exists) {
        throw Exception('Invalid signup code.');
      }
      final data = codeSnap.data()!;
      if (data['used'] == true) {
        throw Exception('This code has already been used.');
      }

      final role = (data['userType'] as String?) ?? 'pending';
      final schoolId = (data['schoolId'] as String?)?.trim();

      final userRef = fs.collection('users').doc(uid);

      final profileUpdate = <String, Object?>{
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'email': _email.text.trim(),
        'userType': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (schoolId != null && schoolId.isNotEmpty) {
        profileUpdate['schoolIds'] = FieldValue.arrayUnion([schoolId]);
      }

      // Merge ensures we don't overwrite other fields if present
      tx.set(userRef, profileUpdate, SetOptions(merge: true));

      tx.update(codeRef, {
        'used': true,
        'usedBy': uid,
        'usedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1) Create Firebase Auth user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      // 2) Set display name
      await cred.user?.updateDisplayName(
        '${_first.text.trim()} ${_last.text.trim()}',
      );

      // 3) Redeem code → writes Firestore profile (role + school) and marks code used
      await _redeemSignupCode(code: _code.text, uid: cred.user!.uid);

      // 4) (Optional) send verification email (non-blocking)
      try {
        await cred.user?.sendEmailVerification();
      } catch (_) {}

      if (!mounted) return;
      // Router will redirect from public route to the role page automatically
      context.go('/loading');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Signup failed');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  TextFormField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Signup code',
                      hintText: 'Enter code (e.g., 7K9F4QX2)',
                    ),
                    validator: (v) => _required(v, 'Signup code'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _first,
                          decoration: const InputDecoration(
                            labelText: 'First name',
                          ),
                          validator: (v) => _required(v, 'First name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _last,
                          decoration: const InputDecoration(
                            labelText: 'Last name',
                          ),
                          validator: (v) => _required(v, 'Last name'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: _emailRule,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password (min 8 chars)',
                    ),
                    validator: _passwordRule,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Confirm your password'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signup,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create account'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : () => context.go('/login'),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
