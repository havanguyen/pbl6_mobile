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
  final String? profileId;
  @JsonKey(defaultValue: null, fromJson: _boolFromJson)
  final bool? isMale;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? dateOfBirth;
  final String? avatarUrl;

  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? createdAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? updatedAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? deletedAt;

  @JsonKey(defaultValue: 30)
  final int appointmentDuration; // Added field

  Doctor({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.profileId,
    this.isMale,
    this.dateOfBirth,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.appointmentDuration = 30,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    // Modify json to handle missing fields for Public Profile response
    final Map<String, dynamic> data = Map<String, dynamic>.from(json);
    data['email'] ??= ''; // Public profile doesn't return email
    data['role'] ??= 'doctor'; // Default role for public profile

    final doctor = _$DoctorFromJson(data);
    return Doctor(
      id: doctor.id,
      email: doctor.email,
      fullName: doctor.fullName,
      role: doctor.role,
      createdAt: doctor.createdAt,
      updatedAt: doctor.updatedAt,
      phone: doctor.phone,
      profileId: doctor.profileId,
      isMale: doctor.isMale,
      dateOfBirth: doctor.dateOfBirth,
      avatarUrl: doctor.avatarUrl,
      deletedAt: doctor.deletedAt,
      appointmentDuration: json['appointmentDuration'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    final val = _$DoctorToJson(this);
    val['appointmentDuration'] = appointmentDuration;
    return val;
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

  static String? _dateTimeToJson(DateTime? date) => date?.toIso8601String();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Doctor && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
