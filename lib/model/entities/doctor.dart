import 'package:json_annotation/json_annotation.dart';

part 'doctor.g.dart';

@JsonSerializable()
class Doctor {
  final String id;
  final String email;
  final String fullName;
  @JsonKey(includeIfNull: false)
  final String? phone;
  final String role;
  @JsonKey(defaultValue: null, fromJson: _boolFromJson)
  final bool? isMale;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? dateOfBirth;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? createdAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? updatedAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? deletedAt;

  Doctor({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.isMale,
    this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) => _$DoctorFromJson(json);
  Map<String, dynamic> toJson() => _$DoctorToJson(this);

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

  static String? _dateTimeToJson(DateTime? date) => date?.toIso8601String();
}