import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});
  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _grade = TextEditingController();
  final _guardianName = TextEditingController();
  final _guardianPhone = TextEditingController();
  final _address = TextEditingController();

  String? _gender;
  String? _schoolId;
  DateTime? _dob;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _grade.dispose();
    _guardianName.dispose();
    _guardianPhone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 25);
    final last = DateTime(now.year - 3);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 10),
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  // Normalize + combine key fields into a single stable fingerprint
  String _fingerprint({
    required String schoolId,
    required String firstName,
    required String lastName,
    String? dobIso,
    String? guardianPhone,
  }) {
    String norm(String s) => s.trim().toLowerCase();
    String normPhone(String s) =>
        s.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    return [
      norm(schoolId),
      norm(firstName),
      norm(lastName),
      norm(dobIso ?? ''),
      normPhone(guardianPhone ?? ''),
    ].join('|'); // used as doc id in studentsFp/
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_schoolId == null || _schoolId!.isEmpty) {
      setState(() => _error = 'Please select a school.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final fs = FirebaseFirestore.instance;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final dobIso = _dob?.toIso8601String();
      final fp = _fingerprint(
        schoolId: _schoolId!,
        firstName: _first.text,
        lastName: _last.text,
        dobIso: dobIso,
        guardianPhone: _guardianPhone.text,
      );
      final year = DateTime.now().year.toString();

      // Run one atomic transaction: reserve fingerprint, increment counter, create student
      final result = await fs.runTransaction((tx) async {
        final fpRef = fs.collection('studentsFp').doc(fp);
        final fpSnap = await tx.get(fpRef);
        if (fpSnap.exists) {
          throw Exception(
            'A student with the same name, DOB and guardian phone already exists in this school.',
          );
        }

        final counterRef = fs.doc('counters/admissions-$_schoolId-$year');
        final counterSnap = await tx.get(counterRef);
        final current = (counterSnap.data()?['value'] as int?) ?? 0;
        final next = current + 1;
        final admissionNumber = '$year-${next.toString().padLeft(5, '0')}';

        final studentRef = fs.collection('students').doc();

        final data = {
          'firstName': _first.text.trim(),
          'lastName': _last.text.trim(),
          'gender': _gender,
          'dob': dobIso,
          'schoolId': _schoolId,
          'grade': _grade.text.trim().isEmpty ? null : _grade.text.trim(),
          'admissionNumber': admissionNumber,
          'guardianName': _guardianName.text.trim().isEmpty
              ? null
              : _guardianName.text.trim(),
          'guardianPhone': _guardianPhone.text.trim().isEmpty
              ? null
              : _guardianPhone.text.trim(),
          'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
          'assignedTeacherIds': <String>[],
          'guardianIds': <String>[],
          'fingerprint': fp,
          'isActive': true,
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Reserve fingerprint (create once)
        tx.set(fpRef, {
          'studentRef': studentRef.path,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Increment counter
        tx.set(counterRef, {
          'value': next,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Create student
        tx.set(studentRef, data);

        return {'admissionNumber': admissionNumber};
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student added • ${result['admissionNumber']}')),
      );

      // Return to list (pop when pushed, else hard route)
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        context.go('/students');
      }
    } on Exception catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } catch (_) {
      setState(() => _error = 'Could not save student. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolsQ = FirebaseFirestore.instance
        .collection('schools')
        .orderBy('name');

    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _first,
                          decoration: const InputDecoration(
                            labelText: 'First name',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _last,
                          decoration: const InputDecoration(
                            labelText: 'Last name',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // School picker
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: schoolsQ.snapshots(),
                    builder: (context, snap) {
                      final docs = snap.data?.docs ?? [];
                      final items = docs
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.id,
                              child: Text((d.data()['name'] ?? d.id) as String),
                            ),
                          )
                          .toList();
                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'School'),
                        initialValue:
                            _schoolId, // latest Flutter uses initialValue
                        items: items,
                        onChanged: (v) => setState(() => _schoolId = v),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Select a school' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Gender + DOB
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Gender (optional)',
                          ),
                          initialValue: _gender,
                          items: const [
                            DropdownMenuItem(
                              value: 'male',
                              child: Text('Male'),
                            ),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text('Female'),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text('Other'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _gender = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickDob,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date of birth (optional)',
                            ),
                            child: Text(
                              _dob == null
                                  ? 'Pick date'
                                  : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _grade,
                    decoration: const InputDecoration(
                      labelText: 'Class/Form (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _guardianName,
                    decoration: const InputDecoration(
                      labelText: 'Guardian name (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _guardianPhone,
                    decoration: const InputDecoration(
                      labelText: 'Guardian phone (optional)',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(
                      labelText: 'Address (optional)',
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save student'),
                    ),
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
