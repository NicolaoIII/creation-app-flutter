import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/auth_state.dart';
import 'assign_teacher_dialog.dart';
import 'link_parent_dialog.dart';

class StudentDetailScreen extends StatelessWidget {
  final String id;
  const StudentDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('students').doc(id);

    return Scaffold(
      appBar: AppBar(title: const Text('Student details')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Student not found'));
          }
          final d = snap.data!.data()!;
          final name = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
          final adm = d['admissionNumber'] ?? '';
          final schoolId = (d['schoolId'] ?? '') as String;
          final teacherIds = ((d['assignedTeacherIds'] ?? []) as List).cast<String>();
          final parentIds = ((d['guardianIds'] ?? []) as List).cast<String>();

          final auth = context.watch<AuthState>();
          final role = auth.profile?.userType ?? 'pending';
          final isAdmin = role == 'admin' || role == 'superadmin';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                name.isEmpty ? '(no name)' : name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (adm != '') Text('Admission: $adm'),
              if (schoolId != '') _SchoolNameLine(schoolId: schoolId), // 👈 name, not ID
              if (d['grade'] != null) Text('Class/Form: ${d['grade']}'),
              if (d['gender'] != null) Text('Gender: ${d['gender']}'),
              if (d['dob'] != null) Text('DOB: ${d['dob']}'),
              if (d['address'] != null) Text('Address: ${d['address']}'),
              const SizedBox(height: 16),
              Text('Active: ${d['isActive'] == false ? 'No' : 'Yes'}'),
              const Divider(height: 32),

              // Assigned Teachers
              Row(
                children: [
                  const Expanded(
                    child: Text('Assigned teachers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  if (isAdmin)
                    TextButton.icon(
                      onPressed: () async {
                        final selectedUid = await showDialog<String?>(
                          context: context,
                          builder: (_) => AssignTeacherDialog(schoolId: schoolId),
                        );
                        if (!context.mounted || selectedUid == null) return;
                        await ref.update({
                          'assignedTeacherIds': FieldValue.arrayUnion([selectedUid]),
                        });
                      },
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add Teacher'),
                    ),
                ],
              ),
              _UserListChips(userIds: teacherIds, allowRemove: isAdmin, onRemove: (uid) async {
                await ref.update({
                  'assignedTeacherIds': FieldValue.arrayRemove([uid]),
                });
              }),
              const SizedBox(height: 8),

              // Parents / Guardians
              Row(
                children: [
                  const Expanded(
                    child: Text('Parents / Guardians', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  if (isAdmin)
                    TextButton.icon(
                      onPressed: () async {
                        final selectedUid = await showDialog<String?>(
                          context: context,
                          builder: (_) => const LinkParentDialog(),
                        );
                        if (!context.mounted || selectedUid == null) return;
                        await ref.update({
                          'guardianIds': FieldValue.arrayUnion([selectedUid]),
                        });
                      },
                      icon: const Icon(Icons.group_add),
                      label: const Text('Link Parent'),
                    ),
                ],
              ),
              _UserListChips(userIds: parentIds, allowRemove: isAdmin, onRemove: (uid) async {
                await ref.update({
                  'guardianIds': FieldValue.arrayRemove([uid]),
                });
              }),
            ],
          );
        },
      ),
    );
  }
}

class _SchoolNameLine extends StatelessWidget {
  final String schoolId;
  const _SchoolNameLine({required this.schoolId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('schools').doc(schoolId);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        String label = schoolId;
        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data()!;
          final name = (data['name'] ?? '') as String;
          if (name.isNotEmpty) label = name;
        }
        return Text('School: $label');
      },
    );
  }
}

/// (unchanged)
class _UserListChips extends StatelessWidget {
  final List<String> userIds;
  final bool allowRemove;
  final Future<void> Function(String uid) onRemove;

  const _UserListChips({
    required this.userIds,
    required this.allowRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (userIds.isEmpty) {
      return const Text('None linked yet.');
    }

    final take = userIds.length > 10 ? userIds.sublist(0, 10) : userIds;
    final q = FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: take);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snap.hasError) return const Text('Could not load users');

        final docs = snap.data?.docs ?? [];
        final chips = docs.map((d) {
          final data = d.data();
          final display = [
            if ((data['firstName'] ?? '').toString().isNotEmpty) data['firstName'],
            if ((data['lastName'] ?? '').toString().isNotEmpty) data['lastName'],
          ].join(' ').trim();
          final email = (data['email'] ?? '') as String;
          final label = display.isEmpty ? (email.isEmpty ? d.id : email) : display;

          return Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 6),
            child: Chip(
              label: Text(label),
              onDeleted: allowRemove ? () => onRemove(d.id) : null,
            ),
          );
        }).toList();

        return Wrap(children: chips);
      },
    );
  }
}
