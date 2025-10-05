// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkLocation _$WorkLocationFromJson(Map<String, dynamic> json) => WorkLocation(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  phone: json['phone'] as String,
  timezone: json['timezone'] as String,
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$WorkLocationToJson(WorkLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'phone': instance.phone,
      'timezone': instance.timezone,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
