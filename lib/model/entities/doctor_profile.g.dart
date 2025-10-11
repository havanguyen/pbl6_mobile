// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DoctorProfile _$DoctorProfileFromJson(Map<String, dynamic> json) =>
    DoctorProfile(
      id: json['id'] as String,
      staffAccountId: json['staffAccountId'] as String,
      isActive: json['isActive'] as bool,
      degree: json['degree'] as String?,
      position:
      (json['position'] as List<dynamic>).map((e) => e as String).toList(),
      introduction: json['introduction'] as String?,
      memberships: (json['memberships'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      awards:
      (json['awards'] as List<dynamic>).map((e) => e as String).toList(),
      research: json['research'] as String?,
      trainingProcess: (json['trainingProcess'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      experience: (json['experience'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      avatarUrl: json['avatarUrl'] as String?,
      portrait: json['portrait'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      specialties: (json['specialties'] as List<dynamic>)
          .map((e) => Specialty.fromJson(e as Map<String, dynamic>))
          .toList(),
      workLocations: (json['workLocations'] as List<dynamic>)
          .map((e) => WorkLocation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DoctorProfileToJson(DoctorProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'staffAccountId': instance.staffAccountId,
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
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'specialties': instance.specialties,
      'workLocations': instance.workLocations,
    };