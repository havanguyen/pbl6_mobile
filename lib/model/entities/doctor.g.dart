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
  avatarUrl: json['avatarUrl'] as String?,
  createdAt: Doctor._dateTimeFromJson(json['createdAt']),
  updatedAt: Doctor._dateTimeFromJson(json['updatedAt']),
  deletedAt: Doctor._dateTimeFromJson(json['deletedAt']),
);

Map<String, dynamic> _$DoctorToJson(Doctor instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'fullName': instance.fullName,
  'phone': ?instance.phone,
  'role': instance.role,
  'isMale': instance.isMale,
  'dateOfBirth': Doctor._dateTimeToJson(instance.dateOfBirth),
  'avatarUrl': instance.avatarUrl,
  'createdAt': Doctor._dateTimeToJson(instance.createdAt),
  'updatedAt': Doctor._dateTimeToJson(instance.updatedAt),
  'deletedAt': Doctor._dateTimeToJson(instance.deletedAt),
};
