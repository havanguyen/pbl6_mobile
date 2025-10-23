// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlogCategory _$BlogCategoryFromJson(Map<String, dynamic> json) => BlogCategory(
  id: json['id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String,
  description: json['description'] as String?,
  createdAt: BlogCategory.dateTimeFromJson(json['createdAt']),
  updatedAt: BlogCategory.dateTimeFromJson(json['updatedAt']),
);

Map<String, dynamic> _$BlogCategoryToJson(BlogCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'description': instance.description,
      'createdAt': BlogCategory.dateTimeToJson(instance.createdAt),
      'updatedAt': BlogCategory.dateTimeToJson(instance.updatedAt),
    };