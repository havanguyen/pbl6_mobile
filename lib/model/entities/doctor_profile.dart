import 'package:json_annotation/json_annotation.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';

part 'doctor_profile.g.dart';

@JsonSerializable()
class DoctorProfile {
  final String id;
  final String staffAccountId;
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Specialty> specialties;
  final List<WorkLocation> workLocations;

  DoctorProfile({
    required this.id,
    required this.staffAccountId,
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
    required this.createdAt,
    required this.updatedAt,
    required this.specialties,
    required this.workLocations,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) => _$DoctorProfileFromJson(json);
  Map<String, dynamic> toJson() => _$DoctorProfileToJson(this);
}