import 'package:json_annotation/json_annotation.dart';

part 'blog_category.g.dart';

@JsonSerializable()
class BlogCategory {
  final String id;
  final String name;
  final String? slug;
  final String? description;
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  final DateTime? createdAt;
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  final DateTime? updatedAt;

  BlogCategory({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory BlogCategory.fromJson(Map<String, dynamic> json) => _$BlogCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$BlogCategoryToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BlogCategory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  static DateTime? dateTimeFromJson(dynamic value) {
    if (value == null || value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static String? dateTimeToJson(DateTime? date) => date?.toUtc().toIso8601String();
}