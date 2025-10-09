// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'specialty.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Specialty _$SpecialtyFromJson(Map<String, dynamic> json) => Specialty(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  infoSectionsCount: json['infoSectionsCount'] as int? ?? 0,
  createdAt: Specialty._dateTimeFromJson(json['createdAt']),
  updatedAt: Specialty._dateTimeFromJson(json['updatedAt']),
  deletedAt: Specialty._dateTimeFromJson(json['deletedAt']),
);

Map<String, dynamic> _$SpecialtyToJson(Specialty instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('description', instance.description);
  val['infoSectionsCount'] = instance.infoSectionsCount;
  writeNotNull('createdAt', Specialty._dateTimeToJson(instance.createdAt));
  writeNotNull('updatedAt', Specialty._dateTimeToJson(instance.updatedAt));
  writeNotNull('deletedAt', Specialty._dateTimeToJson(instance.deletedAt));
  return val;
}