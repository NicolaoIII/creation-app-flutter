import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/auth_state.dart';
import 'package:go_router/go_router.dart';

class MyStudentsScreen extends StatelessWidget {
  const MyStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final profile = auth.profile;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final isParent = profile?.userType == 'parent';
    final title = isParent ? 'My Children' : 'My Students';

    final field = isParent ? 'guardianIds' : 'assignedTeacherIds';
    final q = FirebaseFirestore.instance
        .collection('students')
        .where(field, arrayContains: uid);
    // You can add .orderBy('createdAt', descending: true) later; it will prompt an index.

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Error loading students'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                isParent
                    ? 'No linked children yet.'
                    : 'No assigned students yet.',
              ),
            );
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final name =
                  '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
              final adm = data['admissionNumber'] ?? '';
              final schoolId = data['schoolId'] ?? '';
              return ListTile(
                title: Text(name.isEmpty ? '(no name)' : name),
                subtitle: Text(
                  [
                    if (adm != '') 'Adm: $adm',
                    if (schoolId != '') 'School: $schoolId',
                  ].join(' · '),
                ),
                onTap: () => context.go('/students/${d.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
