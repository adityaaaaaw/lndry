class EmployeeModel {
  const EmployeeModel({
    required this.id,
    required this.vendorId,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.permissions = const [],
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String vendorId;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final List<String> permissions;
  final bool isActive;
  final DateTime? createdAt;

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String? ?? '',
      vendorId: json['vendor_id'] as String? ?? json['vendorId'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'VENDOR_STAFF',
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'permissions': permissions,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  EmployeeModel copyWith({
    String? id,
    String? vendorId,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? role,
    List<String>? permissions,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
