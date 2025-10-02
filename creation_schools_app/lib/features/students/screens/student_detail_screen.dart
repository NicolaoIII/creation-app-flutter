import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          if (!snap.data!.exists)
            return const Center(child: Text('Student not found'));
          final d = snap.data!.data()!;
          final name = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Admission: ${d['admissionNumber'] ?? ''}'),
              Text('School: ${d['schoolId'] ?? ''}'),
              if (d['grade'] != null) Text('Class/Form: ${d['grade']}'),
              if (d['gender'] != null) Text('Gender: ${d['gender']}'),
              if (d['dob'] != null) Text('DOB: ${d['dob']}'),
              if (d['guardianName'] != null)
                Text('Guardian: ${d['guardianName']}'),
              if (d['guardianPhone'] != null)
                Text('Phone: ${d['guardianPhone']}'),
              if (d['address'] != null) Text('Address: ${d['address']}'),
              const SizedBox(height: 16),
              Text('Active: ${d['isActive'] == false ? 'No' : 'Yes'}'),
            ],
          );
        },
      ),
    );
  }
}
