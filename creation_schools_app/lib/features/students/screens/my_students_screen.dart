import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/auth_state.dart';

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

    final studentsQ = FirebaseFirestore.instance
        .collection('students')
        .where(field, arrayContains: uid);

    final schoolsQ = FirebaseFirestore.instance.collection('schools');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: schoolsQ.snapshots(),
        builder: (context, schoolsSnap) {
          if (schoolsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (schoolsSnap.hasError) {
            return const Center(child: Text('Error loading schools'));
          }

          // Build id -> name map
          final schoolsMap = <String, String>{};
          for (final d in schoolsSnap.data?.docs ?? []) {
            final name = (d.data()['name'] ?? d.id) as String;
            schoolsMap[d.id] = name;
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: studentsQ.snapshots(),
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
                  child: Text(isParent ? 'No linked children yet.' : 'No assigned students yet.'),
                );
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final data = d.data();
                  final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                  final adm = (data['admissionNumber'] ?? '') as String;
                  final schoolId = (data['schoolId'] ?? '') as String;
                  final schoolName = schoolsMap[schoolId] ?? schoolId;

                  return ListTile(
                    title: Text(name.isEmpty ? '(no name)' : name),
                    subtitle: Text([
                      if (adm.isNotEmpty) 'Adm: $adm',
                      if (schoolName.isNotEmpty) 'School: $schoolName',
                    ].join(' · ')),
                    onTap: () => context.go('/students/${d.id}'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
