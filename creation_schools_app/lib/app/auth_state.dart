import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  AuthState() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((u) {
      _user = u;
      notifyListeners();
    });
  }

  User? _user;
  User? get user => _user;

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
