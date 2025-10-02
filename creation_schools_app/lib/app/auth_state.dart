import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class AuthState extends ChangeNotifier {
  AuthState() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      _user = u;
      _listenToProfile(u?.uid);
      notifyListeners();
    });
  }

  User? _user;
  User? get user => _user;

  AppUser? _profile;
  AppUser? get profile => _profile;

  bool _profileLoading = false;
  bool get profileLoading => _profileLoading;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  void _listenToProfile(String? uid) {
    _profileSub?.cancel();
    _profile = null;
    if (uid == null) {
      notifyListeners();
      return;
    }
    _profileLoading = true;
    notifyListeners();

    _profileSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
          _profileLoading = false;
          if (snap.exists && snap.data() != null) {
            _profile = AppUser.fromMap(snap.id, snap.data()!);
          } else {
            _profile = null;
          }
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
