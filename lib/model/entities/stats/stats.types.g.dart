// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats.types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffStatsByRole _$StaffStatsByRoleFromJson(Map<String, dynamic> json) =>
    StaffStatsByRole(
      superAdmin: json['SUPER_ADMIN'] as int,
      admin: json['ADMIN'] as int,
      doctor: json['DOCTOR'] as int,
    );

Map<String, dynamic> _$StaffStatsByRoleToJson(StaffStatsByRole instance) =>
    <String, dynamic>{
      'SUPER_ADMIN': instance.superAdmin,
      'ADMIN': instance.admin,
      'DOCTOR': instance.doctor,
    };

StaffStats _$StaffStatsFromJson(Map<String, dynamic> json) => StaffStats(
  total: json['total'] as int,
  byRole: StaffStatsByRole.fromJson(json['byRole'] as Map<String, dynamic>),
  recentlyCreated: json['recentlyCreated'] as int,
  deleted: json['deleted'] as int,
);

Map<String, dynamic> _$StaffStatsToJson(StaffStats instance) =>
    <String, dynamic>{
      'total': instance.total,
      'byRole': instance.byRole,
      'recentlyCreated': instance.recentlyCreated,
      'deleted': instance.deleted,
    };

RevenueStats _$RevenueStatsFromJson(Map<String, dynamic> json) => RevenueStats(
  name: json['name'] as String,
  total: Map<String, num>.from(json['total'] as Map),
);

Map<String, dynamic> _$RevenueStatsToJson(RevenueStats instance) =>
    <String, dynamic>{'name': instance.name, 'total': instance.total};

DoctorInfo _$DoctorInfoFromJson(Map<String, dynamic> json) => DoctorInfo(
  id: json['id'] as String,
  staffAccountId: json['staffAccountId'] as String,
  fullName: json['fullName'] as String,
  isActive: json['isActive'] as bool,
  avatarUrl: json['avatarUrl'] as String,
);

Map<String, dynamic> _$DoctorInfoToJson(DoctorInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'staffAccountId': instance.staffAccountId,
      'fullName': instance.fullName,
      'isActive': instance.isActive,
      'avatarUrl': instance.avatarUrl,
    };

RevenueByDoctorStats _$RevenueByDoctorStatsFromJson(
  Map<String, dynamic> json,
) => RevenueByDoctorStats(
  doctorId: json['doctorId'] as String,
  total: Map<String, num>.from(json['total'] as Map),
  doctor: DoctorInfo.fromJson(json['doctor'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RevenueByDoctorStatsToJson(
  RevenueByDoctorStats instance,
) => <String, dynamic>{
  'doctorId': instance.doctorId,
  'total': instance.total,
  'doctor': instance.doctor,
};

PatientStats _$PatientStatsFromJson(Map<String, dynamic> json) => PatientStats(
  totalPatients: json['totalPatients'] as int,
  currentMonthPatients: json['currentMonthPatients'] as int,
  previousMonthPatients: json['previousMonthPatients'] as int,
  growthPercent: (json['growthPercent'] as num).toDouble(),
);

Map<String, dynamic> _$PatientStatsToJson(PatientStats instance) =>
    <String, dynamic>{
      'totalPatients': instance.totalPatients,
      'currentMonthPatients': instance.currentMonthPatients,
      'previousMonthPatients': instance.previousMonthPatients,
      'growthPercent': instance.growthPercent,
    };

AppointmentStats _$AppointmentStatsFromJson(Map<String, dynamic> json) =>
    AppointmentStats(
      totalAppointments: json['totalAppointments'] as int,
      currentMonthAppointments: json['currentMonthAppointments'] as int,
      previousMonthAppointments: json['previousMonthAppointments'] as int,
      growthPercent: (json['growthPercent'] as num).toDouble(),
    );

Map<String, dynamic> _$AppointmentStatsToJson(AppointmentStats instance) =>
    <String, dynamic>{
      'totalAppointments': instance.totalAppointments,
      'currentMonthAppointments': instance.currentMonthAppointments,
      'previousMonthAppointments': instance.previousMonthAppointments,
      'growthPercent': instance.growthPercent,
    };

ReviewsOverviewStats _$ReviewsOverviewStatsFromJson(
  Map<String, dynamic> json,
) => ReviewsOverviewStats(
  totalReviews: json['totalReviews'] as int,
  ratingCounts: Map<String, int>.from(json['ratingCounts'] as Map),
);

Map<String, dynamic> _$ReviewsOverviewStatsToJson(
  ReviewsOverviewStats instance,
) => <String, dynamic>{
  'totalReviews': instance.totalReviews,
  'ratingCounts': instance.ratingCounts,
};

QAOverviewStats _$QAOverviewStatsFromJson(Map<String, dynamic> json) =>
    QAOverviewStats(
      totalQuestions: json['totalQuestions'] as int,
      answeredQuestions: json['answeredQuestions'] as int,
      answerRate: (json['answerRate'] as num).toDouble(),
    );

Map<String, dynamic> _$QAOverviewStatsToJson(QAOverviewStats instance) =>
    <String, dynamic>{
      'totalQuestions': instance.totalQuestions,
      'answeredQuestions': instance.answeredQuestions,
      'answerRate': instance.answerRate,
    };
