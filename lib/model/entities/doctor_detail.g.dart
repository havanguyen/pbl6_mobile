// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DoctorDetail _$DoctorDetailFromJson(Map<String, dynamic> json) => DoctorDetail(
  id: json['id'] as String,
  fullName: json['fullName'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  isMale: json['isMale'] as bool?,
  dateOfBirth: json['dateOfBirth'] == null
      ? null
      : DateTime.parse(json['dateOfBirth'] as String),
  role: json['role'] as String,
  profileId: json['profileId'] as String?,
  isActive: json['isActive'] as bool,
  degree: json['degree'] as String?,
  position: (json['position'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  introduction: json['introduction'] as String?,
  memberships: (json['memberships'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  awards: (json['awards'] as List<dynamic>?)?.map((e) => e as String).toList(),
  research: json['research'] as String?,
  trainingProcess: (json['trainingProcess'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  experience: (json['experience'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  avatarUrl: json['avatarUrl'] as String?,
  portrait: json['portrait'] as String?,
  specialties: (json['specialties'] as List<dynamic>)
      .map((e) => Specialty.fromJson(e as Map<String, dynamic>))
      .toList(),
  workLocations: (json['workLocations'] as List<dynamic>)
      .map((e) => WorkLocation.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['accountCreatedAt'] == null
      ? null
      : DateTime.parse(json['accountCreatedAt'] as String),
  updatedAt: json['accountUpdatedAt'] == null
      ? null
      : DateTime.parse(json['accountUpdatedAt'] as String),
  profileCreatedAt: json['profileCreatedAt'] == null
      ? null
      : DateTime.parse(json['profileCreatedAt'] as String),
  profileUpdatedAt: json['profileUpdatedAt'] == null
      ? null
      : DateTime.parse(json['profileUpdatedAt'] as String),
);

Map<String, dynamic> _$DoctorDetailToJson(DoctorDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
      'phone': instance.phone,
      'isMale': instance.isMale,
      'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
      'role': instance.role,
      'profileId': instance.profileId,
      'isActive': instance.isActive,
      'degree': instance.degree,
      'position': instance.position,
      'introduction': instance.introduction,
      'memberships': instance.memberships,
      'awards': instance.awards,
      'research': instance.research,
      'trainingProcess': instance.trainingProcess,
      'experience': instance.experience,
      'avatarUrl': instance.avatarUrl,
      'portrait': instance.portrait,
      'specialties': instance.specialties,
      'workLocations': instance.workLocations,
      'accountCreatedAt': instance.createdAt?.toIso8601String(),
      'accountUpdatedAt': instance.updatedAt?.toIso8601String(),
      'profileCreatedAt': instance.profileCreatedAt?.toIso8601String(),
      'profileUpdatedAt': instance.profileUpdatedAt?.toIso8601String(),
    };
