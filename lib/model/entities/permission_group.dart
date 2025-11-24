class PermissionGroup {
  final String id;
  final String name;
  final String description;
  final String tenantId;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  PermissionGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.tenantId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PermissionGroup.fromJson(Map<String, dynamic> json) {
    return PermissionGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      tenantId: json['tenantId'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tenantId': tenantId,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
