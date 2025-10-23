// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Staff _$StaffFromJson(Map<String, dynamic> json) => Staff(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String,
  phone: json['phone'] as String?,
  role: json['role'] as String,
  isMale: Staff._boolFromJson(json['isMale']),
  dateOfBirth: Staff._dateTimeFromJson(json['dateOfBirth']),
  createdAt: Staff._dateTimeFromJson(json['createdAt']),
  updatedAt: Staff._dateTimeFromJson(json['updatedAt']),
  deletedAt: Staff._dateTimeFromJson(json['deletedAt']),
);

Map<String, dynamic> _$StaffToJson(Staff instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'fullName': instance.fullName,
  'phone': ?instance.phone,
  'role': instance.role,
  'isMale': instance.isMale,
  'dateOfBirth': Staff._dateTimeToJson(instance.dateOfBirth),
  'createdAt': Staff._dateTimeToJson(instance.createdAt),
  'updatedAt': Staff._dateTimeToJson(instance.updatedAt),
  'deletedAt': Staff._dateTimeToJson(instance.deletedAt),
};
