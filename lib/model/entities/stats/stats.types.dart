import 'package:json_annotation/json_annotation.dart';

part 'stats.types.g.dart';

/// Staff stats by role
@JsonSerializable()
class StaffStatsByRole {
  @JsonKey(name: 'SUPER_ADMIN')
  final int superAdmin;
  @JsonKey(name: 'ADMIN')
  final int admin;
  @JsonKey(name: 'DOCTOR')
  final int doctor;

  StaffStatsByRole({
    required this.superAdmin,
    required this.admin,
    required this.doctor,
  });

  factory StaffStatsByRole.fromJson(Map<String, dynamic> json) =>
      _$StaffStatsByRoleFromJson(json);
  Map<String, dynamic> toJson() => _$StaffStatsByRoleToJson(this);
}

/// Staff stats response
@JsonSerializable()
class StaffStats {
  final int total;
  final StaffStatsByRole byRole;
  final int recentlyCreated;
  final int deleted;

  StaffStats({
    required this.total,
    required this.byRole,
    required this.recentlyCreated,
    required this.deleted,
  });

  factory StaffStats.fromJson(Map<String, dynamic> json) =>
      _$StaffStatsFromJson(json);
  Map<String, dynamic> toJson() => _$StaffStatsToJson(this);
}

/// Revenue stats by month/period
@JsonSerializable()
class RevenueStats {
  final String name; // e.g. "Jan", "Feb"
  final Map<String, num> total; // e.g. "VND": 1000

  RevenueStats({required this.name, required this.total});

  factory RevenueStats.fromJson(Map<String, dynamic> json) =>
      _$RevenueStatsFromJson(json);
  Map<String, dynamic> toJson() => _$RevenueStatsToJson(this);
}

/// Doctor sub-object for RevenueByDoctorStats
@JsonSerializable()
class DoctorInfo {
  final String id;
  final String staffAccountId;
  final String fullName;
  final bool isActive;
  final String avatarUrl;

  DoctorInfo({
    required this.id,
    required this.staffAccountId,
    required this.fullName,
    required this.isActive,
    required this.avatarUrl,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) =>
      _$DoctorInfoFromJson(json);
  Map<String, dynamic> toJson() => _$DoctorInfoToJson(this);
}

/// Revenue stats by doctor
@JsonSerializable()
class RevenueByDoctorStats {
  final String doctorId;
  final Map<String, num> total;
  final DoctorInfo doctor;

  RevenueByDoctorStats({
    required this.doctorId,
    required this.total,
    required this.doctor,
  });

  factory RevenueByDoctorStats.fromJson(Map<String, dynamic> json) =>
      _$RevenueByDoctorStatsFromJson(json);
  Map<String, dynamic> toJson() => _$RevenueByDoctorStatsToJson(this);
}

/// Patient stats
@JsonSerializable()
class PatientStats {
  final int totalPatients;
  final int currentMonthPatients;
  final int previousMonthPatients;
  final double growthPercent;

  PatientStats({
    required this.totalPatients,
    required this.currentMonthPatients,
    required this.previousMonthPatients,
    required this.growthPercent,
  });

  factory PatientStats.fromJson(Map<String, dynamic> json) =>
      _$PatientStatsFromJson(json);
  Map<String, dynamic> toJson() => _$PatientStatsToJson(this);
}

/// Appointment stats
@JsonSerializable()
class AppointmentStats {
  final int totalAppointments;
  final int currentMonthAppointments;
  final int previousMonthAppointments;
  final double growthPercent;

  AppointmentStats({
    required this.totalAppointments,
    required this.currentMonthAppointments,
    required this.previousMonthAppointments,
    required this.growthPercent,
  });

  factory AppointmentStats.fromJson(Map<String, dynamic> json) =>
      _$AppointmentStatsFromJson(json);
  Map<String, dynamic> toJson() => _$AppointmentStatsToJson(this);
}

/// Reviews overview stats
@JsonSerializable()
class ReviewsOverviewStats {
  final int totalReviews;
  final Map<String, int> ratingCounts;

  ReviewsOverviewStats({
    required this.totalReviews,
    required this.ratingCounts,
  });

  factory ReviewsOverviewStats.fromJson(Map<String, dynamic> json) =>
      _$ReviewsOverviewStatsFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewsOverviewStatsToJson(this);
}

/// QA overview stats
@JsonSerializable()
class QAOverviewStats {
  final int totalQuestions;
  final int answeredQuestions;
  final double answerRate;

  QAOverviewStats({
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.answerRate,
  });

  factory QAOverviewStats.fromJson(Map<String, dynamic> json) =>
      _$QAOverviewStatsFromJson(json);
  Map<String, dynamic> toJson() => _$QAOverviewStatsToJson(this);
}
