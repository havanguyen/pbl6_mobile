// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'specialty.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Specialty _$SpecialtyFromJson(Map<String, dynamic> json) => Specialty(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  infoSectionsCount: (json['infoSectionsCount'] as num?)?.toInt() ?? 0,
  createdAt: Specialty._dateTimeFromJson(json['createdAt']),
  updatedAt: Specialty._dateTimeFromJson(json['updatedAt']),
  deletedAt: Specialty._dateTimeFromJson(json['deletedAt']),
);

Map<String, dynamic> _$SpecialtyToJson(Specialty instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'infoSectionsCount': instance.infoSectionsCount,
  'createdAt': Specialty._dateTimeToJson(instance.createdAt),
  'updatedAt': Specialty._dateTimeToJson(instance.updatedAt),
  'deletedAt': Specialty._dateTimeToJson(instance.deletedAt),
};
