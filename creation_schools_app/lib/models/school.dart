class School {
  final String id;
  final String name;
  final String? district;
  final String? description;
  final String? address;
  final bool isActive;

  School({
    required this.id,
    required this.name,
    this.district,
    this.description,
    this.address,
    this.isActive = true,
  });

  Map<String, dynamic> toMap({String? createdBy}) => {
        'name': name,
        'district': district,
        'description': description,
        'address': address,
        'isActive': isActive,
        if (createdBy != null) 'createdBy': createdBy,
        'createdAt': DateTime.now(), // server ts via set() below
      };

  static School fromMap(String id, Map<String, dynamic> d) => School(
        id: id,
        name: (d['name'] ?? '') as String,
        district: d['district'] as String?,
        description: d['description'] as String?,
        address: d['address'] as String?,
        isActive: (d['isActive'] as bool?) ?? true,
      );
}
