class MyPermission {
  final String resource;
  final String action;
  final String effect;
  final List<PermissionCondition>? conditions;

  MyPermission({
    required this.resource,
    required this.action,
    required this.effect,
    this.conditions,
  });

  factory MyPermission.fromJson(Map<String, dynamic> json) {
    return MyPermission(
      resource: json['resource'] as String,
      action: json['action'] as String,
      effect: json['effect'] as String,
      conditions: json['conditions'] != null
          ? (json['conditions'] as List)
                .map((e) => PermissionCondition.fromJson(e))
                .toList()
          : null,
    );
  }
}

class PermissionCondition {
  final String field;
  final bool? valueBool;
  final String? valueString;
  final String operator;

  PermissionCondition({
    required this.field,
    this.valueBool,
    this.valueString,
    required this.operator,
  });

  factory PermissionCondition.fromJson(Map<String, dynamic> json) {
    return PermissionCondition(
      field: json['field'] as String,
      valueBool: json['value'] is bool ? json['value'] : null,
      valueString: json['value'] is String ? json['value'] : null,
      operator: json['operator'] as String,
    );
  }

  // Helper to get value as string for display
  String get displayValue => valueBool?.toString() ?? valueString ?? '';
}
