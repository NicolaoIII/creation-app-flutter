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
  State<GenerateSignupCodeScreen> createState() =>
      _GenerateSignupCodeScreenState();
}

class _GenerateSignupCodeScreenState extends State<GenerateSignupCodeScreen> {
  final _formKey = GlobalKey<FormState>();

  String _role = 'teacher'; // default
  String? _selectedSchoolId; // picked from Firestore list
  bool _submitting = false;
  String? _generatedCode;
  String? _error;

  String _makeCode({int length = 8}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/I/1
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> _createCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _generatedCode = null;
      _error = null;
    });

    try {
      final code = _makeCode();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Doc id == code → fast lookup at signup (no index needed)
      final ref = FirebaseFirestore.instance
          .collection('signupCodes')
          .doc(code);

      await ref.set({
        'code': code,
        'userType': _role, // role to grant on redeem
        'schoolId': (_selectedSchoolId == null || _selectedSchoolId!.isEmpty)
            ? null
            : _selectedSchoolId,
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

    final schoolsQuery = FirebaseFirestore.instance
        .collection('schools')
        .orderBy('name')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? {},
          toFirestore: (data, _) => data,
        );

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
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Role picker (uses initialValue per latest Flutter)
                      DropdownButtonFormField<String>(
                        initialValue: _role,
                        items: roleOptions
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _role = v ?? _role),
                        decoration: const InputDecoration(
                          labelText: 'User role to assign',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // School picker (live from Firestore)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: schoolsQuery.snapshots(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          if (snap.hasError) {
                            return const Text('Could not load schools');
                          }
                          final docs = snap.data?.docs ?? [];

                          // Dropdown items: (none) + all schools
                          final items = <DropdownMenuItem<String?>>[
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('(No school — optional)'),
                            ),
                            ...docs.map((d) {
                              final id = d.id;
                              final name = (d.data()['name'] ?? '') as String;
                              return DropdownMenuItem<String?>(
                                value: id,
                                child: Text(name.isEmpty ? id : name),
                              );
                            }),
                          ];

                          return DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: _selectedSchoolId,
                            items: items,
                            onChanged: (v) =>
                                setState(() => _selectedSchoolId = v),
                            decoration: const InputDecoration(
                              labelText: 'School (optional)',
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _createCode,
                          child: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _generatedCode!),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied to clipboard'),
                        ),
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
