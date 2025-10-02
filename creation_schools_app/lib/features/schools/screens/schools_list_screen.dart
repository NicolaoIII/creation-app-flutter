import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SchoolsListScreen extends StatelessWidget {
  const SchoolsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance.collection('schools').orderBy('name');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schools'),
        actions: [
          TextButton(
            onPressed: () => context.push('/schools/new'),
            child: const Text('Add School'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Error loading schools'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No schools yet. Add the first one.'),
            );
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final name = (d['name'] ?? '') as String;
              final district = (d['district'] ?? '') as String;
              final desc = (d['description'] ?? '') as String;
              return ListTile(
                title: Text(name),
                subtitle: Text(
                  [
                    if (district.isNotEmpty) 'District: $district',
                    if (desc.isNotEmpty) desc,
                  ].join(' · '),
                ),
                trailing: (d['isActive'] == false)
                    ? const Icon(
                        Icons.pause_circle_filled,
                        color: Colors.orange,
                      )
                    : const Icon(Icons.check_circle, color: Colors.green),
              );
            },
          );
        },
      ),
    );
  }
}
