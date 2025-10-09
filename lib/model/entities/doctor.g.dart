// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Doctor _$DoctorFromJson(Map<String, dynamic> json) => Doctor(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String,
  phone: json['phone'] as String?,
  role: json['role'] as String,
  isMale: Doctor._boolFromJson(json['isMale']),
  dateOfBirth: Doctor._dateTimeFromJson(json['dateOfBirth']),
  createdAt: Doctor._dateTimeFromJson(json['createdAt']),
  updatedAt: Doctor._dateTimeFromJson(json['updatedAt']),
  deletedAt: Doctor._dateTimeFromJson(json['deletedAt']),
);

Map<String, dynamic> _$DoctorToJson(Doctor instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'email': instance.email,
    'fullName': instance.fullName,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('phone', instance.phone);
  val['role'] = instance.role;
  writeNotNull('isMale', instance.isMale);
  writeNotNull('dateOfBirth', Doctor._dateTimeToJson(instance.dateOfBirth));
  val['createdAt'] = Doctor._dateTimeToJson(instance.createdAt);
  val['updatedAt'] = Doctor._dateTimeToJson(instance.updatedAt);
  writeNotNull('deletedAt', Doctor._dateTimeToJson(instance.deletedAt));
  return val;
}