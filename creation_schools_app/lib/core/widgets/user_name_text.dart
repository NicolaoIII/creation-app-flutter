import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../util/user_display.dart';

class UserNameText extends StatelessWidget {
  final String uid;
  final TextStyle? style;
  final String? prefix; // e.g., "Created by: "
  const UserNameText({super.key, required this.uid, this.style, this.prefix});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final label = userDisplayFromData(snap.data?.data(), uid);
        return Text('${prefix ?? ''}$label', style: style);
      },
    );
  }
}
