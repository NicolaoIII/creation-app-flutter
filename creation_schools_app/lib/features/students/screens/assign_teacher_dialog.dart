import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignTeacherDialog extends StatefulWidget {
  final String schoolId;
  const AssignTeacherDialog({super.key, required this.schoolId});

  @override
  State<AssignTeacherDialog> createState() => _AssignTeacherDialogState();
}

class _AssignTeacherDialogState extends State<AssignTeacherDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'teacher')
        .where('schoolIds', arrayContains: widget.schoolId);

    return AlertDialog(
      title: const Text('Assign Teacher'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search (name or email)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: q.snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) return const Center(child: Text('Error loading teachers'));
                  final docs = snap.data?.docs ?? [];
                  final filtered = docs.where((d) {
                    if (_query.isEmpty) return true;
                    final data = d.data();
                    final name = ('${data['firstName'] ?? ''} ${data['lastName'] ?? ''}').toLowerCase();
                    final email = (data['email'] ?? '').toString().toLowerCase();
                    return name.contains(_query) || email.contains(_query);
                  }).toList();

                  if (filtered.isEmpty) return const Center(child: Text('No teachers found'));

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final d = filtered[i];
                      final data = d.data();
                      final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                      final email = (data['email'] ?? '') as String;
                      return ListTile(
                        title: Text(name.isEmpty ? '(no name)' : name),
                        subtitle: (email.isEmpty) ? null : Text(email),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).pop(d.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      ],
    );
  }
}
