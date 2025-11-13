import 'package:json_annotation/json_annotation.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';

part 'doctor_detail.g.dart';

@JsonSerializable(explicitToJson: true)
class DoctorDetail {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final bool isMale;
  final DateTime? dateOfBirth;
  final String role;
  final String profileId;
  final bool isActive;
  final String? degree;
  final List<String> position;
  final String? introduction;
  final List<String> memberships;
  final List<String> awards;
  final String? research;
  final List<String> trainingProcess;
  final List<String> experience;
  final String? avatarUrl;
  final String? portrait;
  final List<Specialty> specialties;
  final List<WorkLocation> workLocations;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime profileCreatedAt;
  final DateTime profileUpdatedAt;

  DoctorDetail({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.isMale,
    this.dateOfBirth,
    required this.role,
    required this.profileId,
    required this.isActive,
    this.degree,
    required this.position,
    this.introduction,
    required this.memberships,
    required this.awards,
    this.research,
    required this.trainingProcess,
    required this.experience,
    this.avatarUrl,
    this.portrait,
    required this.specialties,
    required this.workLocations,
    required this.createdAt,
    required this.updatedAt,
    required this.profileCreatedAt,
    required this.profileUpdatedAt,
  });

  factory DoctorDetail.fromJson(Map<String, dynamic> json) =>
      _$DoctorDetailFromJson(json);

  Map<String, dynamic> toJson() => _$DoctorDetailToJson(this);

  DoctorDetail copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    bool? isMale,
    DateTime? dateOfBirth,
    String? role,
    String? profileId,
    bool? isActive,
    String? degree,
    List<String>? position,
    String? introduction,
    List<String>? memberships,
    List<String>? awards,
    String? research,
    List<String>? trainingProcess,
    List<String>? experience,
    String? avatarUrl,
    String? portrait,
    List<Specialty>? specialties,
    List<WorkLocation>? workLocations,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? profileCreatedAt,
    DateTime? profileUpdatedAt,
  }) {
    return DoctorDetail(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isMale: isMale ?? this.isMale,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
      profileId: profileId ?? this.profileId,
      isActive: isActive ?? this.isActive,
      degree: degree ?? this.degree,
      position: position ?? this.position,
      introduction: introduction ?? this.introduction,
      memberships: memberships ?? this.memberships,
      awards: awards ?? this.awards,
      research: research ?? this.research,
      trainingProcess: trainingProcess ?? this.trainingProcess,
      experience: experience ?? this.experience,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      portrait: portrait ?? this.portrait,
      specialties: specialties ?? this.specialties,
      workLocations: workLocations ?? this.workLocations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileCreatedAt: profileCreatedAt ?? this.profileCreatedAt,
      profileUpdatedAt: profileUpdatedAt ?? this.profileUpdatedAt,
    );
  }
}