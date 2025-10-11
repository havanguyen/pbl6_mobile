import 'package:json_annotation/json_annotation.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';

part 'doctor_detail.g.dart';

@JsonSerializable()
class DoctorDetail {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final bool? isMale;
  final DateTime? dateOfBirth;
  final String role;
  final String? profileId;
  final bool isActive;
  final String? degree;
  final List<String>? position;
  final String? introduction;
  final List<String>? memberships;
  final List<String>? awards;
  final String? research;
  final List<String>? trainingProcess;
  final List<String>? experience;
  final String? avatarUrl;
  final String? portrait;
  final List<Specialty> specialties;
  final List<WorkLocation> workLocations;
  @JsonKey(name: 'accountCreatedAt')
  final DateTime? createdAt;
  @JsonKey(name: 'accountUpdatedAt')
  final DateTime? updatedAt;
  final DateTime? profileCreatedAt;
  final DateTime? profileUpdatedAt;

  DoctorDetail({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.isMale,
    this.dateOfBirth,
    required this.role,
    this.profileId,
    required this.isActive,
    this.degree,
    this.position,
    this.introduction,
    this.memberships,
    this.awards,
    this.research,
    this.trainingProcess,
    this.experience,
    this.avatarUrl,
    this.portrait,
    required this.specialties,
    required this.workLocations,
    this.createdAt,
    this.updatedAt,
    this.profileCreatedAt,
    this.profileUpdatedAt,
  });

  factory DoctorDetail.fromJson(Map<String, dynamic> json) => _$DoctorDetailFromJson(json);
  Map<String, dynamic> toJson() => _$DoctorDetailToJson(this);
}