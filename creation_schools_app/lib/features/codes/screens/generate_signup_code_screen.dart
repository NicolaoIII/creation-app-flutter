import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/auth_state.dart';

class GenerateSignupCodeScreen extends StatefulWidget {
  const GenerateSignupCodeScreen({super.key});

  @override
  State<GenerateSignupCodeScreen> createState() => _GenerateSignupCodeScreenState();
}

class _GenerateSignupCodeScreenState extends State<GenerateSignupCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolId = TextEditingController();

  String _role = 'teacher'; // default
  bool _submitting = false;
  String? _generatedCode;
  String? _error;

  @override
  void dispose() {
    _schoolId.dispose();
    super.dispose();
  }

  String _makeCode({int length = 8}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/I/1
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> _createCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _generatedCode = null; _error = null; });

    try {
      final code = _makeCode();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Doc id == code → fast lookup at signup (no index needed)
      final ref = FirebaseFirestore.instance.collection('signupCodes').doc(code);

      await ref.set({
        'code': code,
        'userType': _role,              // role to grant on redeem
        'schoolId': _schoolId.text.trim().isEmpty ? null : _schoolId.text.trim(),
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'used': false,
        'usedBy': null,
        'usedAt': null,
      });

      setState(() => _generatedCode = code);
    } catch (e) {
      setState(() => _error = 'Could not create code. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final me = auth.profile;
    final myRole = me?.userType ?? 'pending';

    // SuperAdmin: can create any role | Admin: only teacher/parent
    final roleOptions = (myRole == 'superadmin')
        ? const ['superadmin', 'admin', 'teacher', 'parent']
        : const ['teacher', 'parent'];

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Signup Code')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _role,
                        items: roleOptions
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setState(() => _role = v ?? _role),
                        decoration: const InputDecoration(
                          labelText: 'User role to assign',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _schoolId,
                        decoration: const InputDecoration(
                          labelText: 'School ID (optional for now)',
                          hintText: 'e.g., abc123 (we will add a picker soon)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _createCode,
                          child: _submitting
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Generate code'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_generatedCode != null) ...[
                  const SizedBox(height: 20),
                  SelectableText(
                    'Generated code: ${_generatedCode!}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _generatedCode!));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
