class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String? gender; // 'male' | 'female' | 'other'
  final DateTime? dob;
  final String schoolId;
  final String? grade; // class/form
  final String admissionNumber;
  final String? guardianName;
  final String? guardianPhone;
  final String? address;
  final bool isActive;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.schoolId,
    required this.admissionNumber,
    this.gender,
    this.dob,
    this.grade,
    this.guardianName,
    this.guardianPhone,
    this.address,
    this.isActive = true,
  });

  Map<String, dynamic> toMap({String? createdBy}) => {
    'firstName': firstName,
    'lastName': lastName,
    'gender': gender,
    'dob': dob?.toIso8601String(),
    'schoolId': schoolId,
    'grade': grade,
    'admissionNumber': admissionNumber,
    'guardianName': guardianName,
    'guardianPhone': guardianPhone,
    'address': address,
    'isActive': isActive,
    if (createdBy != null) 'createdBy': createdBy,
    'createdAt': DateTime.now(), // server ts set in screen
  };

  static Student fromMap(String id, Map<String, dynamic> d) => Student(
    id: id,
    firstName: (d['firstName'] ?? '') as String,
    lastName: (d['lastName'] ?? '') as String,
    gender: d['gender'] as String?,
    dob: (d['dob'] is String) ? DateTime.tryParse(d['dob']) : null,
    schoolId: (d['schoolId'] ?? '') as String,
    grade: d['grade'] as String?,
    admissionNumber: (d['admissionNumber'] ?? '') as String,
    guardianName: d['guardianName'] as String?,
    guardianPhone: d['guardianPhone'] as String?,
    address: d['address'] as String?,
    isActive: (d['isActive'] as bool?) ?? true,
  );
}
