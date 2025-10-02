class AppUser {
  final String uid;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String userType; // superadmin | admin | teacher | parent | pending
  final List<String> schoolIds;

  AppUser({
    required this.uid,
    required this.userType,
    this.firstName,
    this.lastName,
    this.email,
    this.schoolIds = const [],
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      email: data['email'] as String?,
      userType: (data['userType'] as String?) ?? 'pending',
      schoolIds: (data['schoolIds'] as List?)?.cast<String>() ?? const [],
    );
  }
}
