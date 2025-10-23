// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Blog _$BlogFromJson(Map<String, dynamic> json) => Blog(
  id: json['id'] as String,
  title: json['title'] as String,
  slug: json['slug'] as String,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  authorId: json['authorId'] as String,
  category:
  BlogCategory.fromJson(json['category'] as Map<String, dynamic>),
  status: json['status'] as String,
  publishedAt: BlogCategory.dateTimeFromJson(json['publishedAt']),
  createdAt: BlogCategory.dateTimeFromJson(json['createdAt'])!,
  updatedAt: BlogCategory.dateTimeFromJson(json['updatedAt'])!,
  content: json['content'] as String?,
);

Map<String, dynamic> _$BlogToJson(Blog instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'slug': instance.slug,
  'thumbnailUrl': instance.thumbnailUrl,
  'authorId': instance.authorId,
  'category': instance.category.toJson(),
  'status': instance.status,
  'publishedAt': BlogCategory.dateTimeToJson(instance.publishedAt),
  'createdAt': BlogCategory.dateTimeToJson(instance.createdAt)!,
  'updatedAt': BlogCategory.dateTimeToJson(instance.updatedAt)!,
  'content': instance.content,
};