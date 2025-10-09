import 'package:json_annotation/json_annotation.dart';

part 'info_section.g.dart';

@JsonSerializable()
class InfoSection {
  final String id;
  final String name;
  final String content;
  final String specialtyId;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? createdAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? updatedAt;

  InfoSection({
    required this.id,
    required this.name,
    required this.content,
    required this.specialtyId,
    this.createdAt,
    this.updatedAt,
  });

  factory InfoSection.fromJson(Map<String, dynamic> json) =>
      _$InfoSectionFromJson(json);
  Map<String, dynamic> toJson() => _$InfoSectionToJson(this);

  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null || value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String? _dateTimeToJson(DateTime? date) => date?.toIso8601String();
}