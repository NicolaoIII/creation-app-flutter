import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LinkParentDialog extends StatefulWidget {
  const LinkParentDialog({super.key});

  @override
  State<LinkParentDialog> createState() => _LinkParentDialogState();
}

class _LinkParentDialogState extends State<LinkParentDialog> {
  final _email = TextEditingController();
  String? _error;
  bool _searching = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _results = [];

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter an email to search');
      return;
    }
    setState(() {
      _error = null;
      _searching = true;
      _results = [];
    });

    try {
      // Search exact email. (We can add an `emailLower` field later to make this case-insensitive.)
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'parent')
          .where('email', isEqualTo: email)
          .limit(10)
          .get();

      setState(() => _results = snap.docs);
    } catch (_) {
      setState(() => _error = 'Search failed. Try again.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Link Parent by Email'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Parent email',
                hintText: 'parent@example.com',
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _searching ? null : _search,
                child: _searching
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Search'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_results.isNotEmpty) ...[
              const Divider(height: 24),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final d = _results[i];
                    final data = d.data();
                    final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                    final email = (data['email'] ?? '') as String;
                    return ListTile(
                      title: Text(name.isEmpty ? '(no name)' : name),
                      subtitle: (email.isEmpty) ? null : Text(email),
                      trailing: const Icon(Icons.link),
                      onTap: () => Navigator.of(context).pop(d.id),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
