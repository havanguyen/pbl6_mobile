import 'package:json_annotation/json_annotation.dart';

part 'patient.g.dart';

@JsonSerializable()
class Patient {
  final String id;
  final String email;
  final String fullName;
  @JsonKey(includeIfNull: false)
  final String? phone;
  @JsonKey(defaultValue: null, fromJson: _boolFromJson)
  final bool? isMale;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? dateOfBirth;
  final String? addressLine;
  final String? district;
  final String? province;

  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? createdAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? updatedAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? deletedAt;

  Patient({
    required this.id,
    required this.email,
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

  factory Patient.fromJson(Map<String, dynamic> json) =>
      _$PatientFromJson(json);
  Map<String, dynamic> toJson() => _$PatientToJson(this);

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