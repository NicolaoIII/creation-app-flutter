import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentsListScreen extends StatelessWidget {
  const StudentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studentsQ = FirebaseFirestore.instance
        .collection('students')
        .orderBy('createdAt', descending: true)
        .limit(200);

    final schoolsQ = FirebaseFirestore.instance.collection('schools');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          TextButton(
            onPressed: () =>
                context.push('/students/new'), // push so back works
            child: const Text('Add Student'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: schoolsQ.snapshots(),
        builder: (context, schoolsSnap) {
          if (schoolsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (schoolsSnap.hasError) {
            return const Center(child: Text('Error loading schools'));
          }

          // Build a map: schoolId -> schoolName
          final schoolsMap = <String, String>{};
          for (final d in schoolsSnap.data?.docs ?? []) {
            final name = (d.data()['name'] ?? d.id) as String;
            schoolsMap[d.id] = name;
          }

          // Now stream students
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: studentsQ.snapshots(),
            builder: (context, studentsSnap) {
              if (studentsSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (studentsSnap.hasError) {
                return const Center(child: Text('Error loading students'));
              }
              final docs = studentsSnap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No students yet.'));
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final data = d.data();
                  final name =
                      '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                          .trim();
                  final adm = (data['admissionNumber'] ?? '') as String;
                  final schoolId = (data['schoolId'] ?? '') as String;
                  final schoolName = schoolsMap[schoolId] ?? schoolId;

                  return ListTile(
                    title: Text(name.isEmpty ? '(no name)' : name),
                    subtitle: Text(
                      [
                        if (adm.isNotEmpty) 'Adm: $adm',
                        if (schoolName.isNotEmpty) 'School: $schoolName',
                      ].join(' · '),
                    ),
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
