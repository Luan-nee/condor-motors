class Branch {
  final int id;
  final String name;
  final String address;
  final String type; // 'central' o 'sucursal'
  final String? phone;
  final String? manager;
  final bool isActive;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    this.phone,
    this.manager,
    this.isActive = true,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      type: json['type'] as String,
      phone: json['phone'] as String?,
      manager: json['manager'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'type': type,
      'phone': phone,
      'manager': manager,
      'isActive': isActive,
    };
  }
} 