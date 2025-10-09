// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'info_section.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InfoSection _$InfoSectionFromJson(Map<String, dynamic> json) => InfoSection(
  id: json['id'] as String,
  name: json['name'] as String,
  content: json['content'] as String,
  specialtyId: json['specialtyId'] as String,
  createdAt: InfoSection._dateTimeFromJson(json['createdAt']),
  updatedAt: InfoSection._dateTimeFromJson(json['updatedAt']),
);

Map<String, dynamic> _$InfoSectionToJson(InfoSection instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'content': instance.content,
    'specialtyId': instance.specialtyId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('createdAt', InfoSection._dateTimeToJson(instance.createdAt));
  writeNotNull('updatedAt', InfoSection._dateTimeToJson(instance.updatedAt));
  return val;
}