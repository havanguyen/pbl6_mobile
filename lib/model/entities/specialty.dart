import 'package:json_annotation/json_annotation.dart';

part 'specialty.g.dart';

@JsonSerializable()
class Specialty {
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'infoSectionsCount', defaultValue: 0)
  final int infoSectionsCount;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? createdAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? updatedAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? deletedAt;

  Specialty({
    required this.id,
    required this.name,
    this.description,
    required this.infoSectionsCount,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Specialty.fromJson(Map<String, dynamic> json) =>
      _$SpecialtyFromJson(json);
  Map<String, dynamic> toJson() => _$SpecialtyToJson(this);

  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null || value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String? _dateTimeToJson(DateTime? date) => date?.toIso8601String();
}