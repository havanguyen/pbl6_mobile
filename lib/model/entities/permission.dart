class Permission {
  final String id;
  final String permissionId;
  final String resource;
  final String action;
  final String description;
  final String effect;
  final List<dynamic>? conditions;
  final String createdAt;

  Permission({
    required this.id,
    required this.permissionId,
    required this.resource,
    required this.action,
    required this.description,
    required this.effect,
    this.conditions,
    required this.createdAt,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] ?? '',
      permissionId: json['permissionId'] ?? '',
      resource: json['resource'] ?? '',
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      effect: json['effect'] ?? 'ALLOW',
      conditions: json['conditions'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'permissionId': permissionId,
      'resource': resource,
      'action': action,
      'description': description,
      'effect': effect,
      'conditions': conditions,
      'createdAt': createdAt,
    };
  }
}
