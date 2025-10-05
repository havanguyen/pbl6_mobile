import 'package:json_annotation/json_annotation.dart';

part 'staff.g.dart';

@JsonSerializable()
class Staff {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final bool isMale;
  final DateTime dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;

  Staff({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.isMale,
    required this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);
  Map<String, dynamic> toJson() => _$StaffToJson(this);
}