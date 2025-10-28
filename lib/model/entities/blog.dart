import 'package:json_annotation/json_annotation.dart';
import 'blog_category.dart';

part 'blog.g.dart';

@JsonSerializable(explicitToJson: true)
class Blog {
  final String id;
  final String title;
  final String slug;
  final String? thumbnailUrl;
  final String authorId;
  final BlogCategory category;
  final String status;
  @JsonKey(fromJson: BlogCategory.dateTimeFromJson, toJson: BlogCategory.dateTimeToJson)
  final DateTime? publishedAt;
  @JsonKey(fromJson: BlogCategory.dateTimeFromJson, toJson: BlogCategory.dateTimeToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: BlogCategory.dateTimeFromJson, toJson: BlogCategory.dateTimeToJson)
  final DateTime updatedAt;
  final String? content;
  final String? authorName;
  final List<String>? publicIds;

  Blog({
    required this.id,
    required this.title,
    required this.slug,
    this.thumbnailUrl,
    required this.authorId,
    required this.category,
    required this.status,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.content,
    this.authorName,
    this.publicIds,
  });

  factory Blog.fromJson(Map<String, dynamic> json) => _$BlogFromJson(json);
  Map<String, dynamic> toJson() => _$BlogToJson(this);
}