class Patient {
  final String id;
  final String? email;
  final String fullName;
  final String? phone;
  final bool? isMale;
  final DateTime? dateOfBirth;
  final String? addressLine;
  final String? district;
  final String? province;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Patient({
    required this.id,
    this.email,
    required this.fullName,
    this.phone,
    this.isMale,
    this.dateOfBirth,
    this.addressLine,
    this.district,
    this.province,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      fullName: json['fullName'] as String? ?? 'Unknown',
      phone: json['phone'] as String?,
      isMale: _boolFromJson(json['isMale']),
      dateOfBirth: _dateTimeFromJson(json['dateOfBirth']),
      addressLine: json['addressLine'] as String?,
      district: json['district'] as String?,
      province: json['province'] as String?,
      createdAt: _dateTimeFromJson(json['createdAt']),
      updatedAt: _dateTimeFromJson(json['updatedAt']),
      deletedAt: _dateTimeFromJson(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'isMale': isMale,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'addressLine': addressLine,
      'district': district,
      'province': province,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  static bool? _boolFromJson(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return null;
  }

  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null || value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Patient && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
