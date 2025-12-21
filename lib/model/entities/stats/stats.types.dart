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

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      id: json['id'] as String? ?? '',
      staffAccountId: json['staffAccountId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Unknown Doctor',
      isActive: json['isActive'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'staffAccountId': staffAccountId,
    'fullName': fullName,
    'isActive': isActive,
    'avatarUrl': avatarUrl,
  };
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

/// Doctor booking stats
@JsonSerializable()
class DoctorBookingStats {
  final int total;
  final int bookedCount;
  final int confirmedCount;
  final int cancelledCount;
  final int completedCount;
  final double completedRate;

  DoctorBookingStats({
    required this.total,
    required this.bookedCount,
    required this.confirmedCount,
    required this.cancelledCount,
    required this.completedCount,
    required this.completedRate,
  });

  factory DoctorBookingStats.fromJson(Map<String, dynamic> json) {
    return DoctorBookingStats(
      total: json['total'] as int? ?? 0,
      bookedCount: json['bookedCount'] as int? ?? 0,
      confirmedCount: json['confirmedCount'] as int? ?? 0,
      cancelledCount: json['cancelledCount'] as int? ?? 0,
      completedCount: json['completedCount'] as int? ?? 0,
      completedRate: (json['completedRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'bookedCount': bookedCount,
    'confirmedCount': confirmedCount,
    'cancelledCount': cancelledCount,
    'completedCount': completedCount,
    'completedRate': completedRate,
  };
}

/// Doctor content stats
@JsonSerializable()
class DoctorContentStats {
  final int totalReviews;
  final double averageRating;
  final int totalAnswers;
  final int totalAcceptedAnswers;
  final double answerAcceptedRate;
  final int totalBlogs;

  DoctorContentStats({
    required this.totalReviews,
    required this.averageRating,
    required this.totalAnswers,
    required this.totalAcceptedAnswers,
    required this.answerAcceptedRate,
    required this.totalBlogs,
  });

  factory DoctorContentStats.fromJson(Map<String, dynamic> json) {
    return DoctorContentStats(
      totalReviews: json['totalReviews'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalAnswers: json['totalAnswers'] as int? ?? 0,
      totalAcceptedAnswers: json['totalAcceptedAnswers'] as int? ?? 0,
      answerAcceptedRate:
          (json['answerAcceptedRate'] as num?)?.toDouble() ?? 0.0,
      totalBlogs: json['totalBlogs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalReviews': totalReviews,
    'averageRating': averageRating,
    'totalAnswers': totalAnswers,
    'totalAcceptedAnswers': totalAcceptedAnswers,
    'answerAcceptedRate': answerAcceptedRate,
    'totalBlogs': totalBlogs,
  };
}

/// Doctor my stats
@JsonSerializable()
class DoctorMyStats {
  final DoctorBookingStats booking;
  final DoctorContentStats content;

  DoctorMyStats({required this.booking, required this.content});

  factory DoctorMyStats.fromJson(Map<String, dynamic> json) {
    return DoctorMyStats(
      booking: DoctorBookingStats.fromJson(
        json['booking'] as Map<String, dynamic>,
      ),
      content: DoctorContentStats.fromJson(
        json['content'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'booking': booking.toJson(),
    'content': content.toJson(),
  };
}

/// Doctor Booking Stats Item for List
class DoctorBookingStatsItem {
  final DoctorInfo doctor;
  final int total;
  final int bookedCount;
  final int confirmedCount;
  final int cancelledCount;
  final int completedCount;
  final double completedRate;

  DoctorBookingStatsItem({
    required this.doctor,
    required this.total,
    required this.bookedCount,
    required this.confirmedCount,
    required this.cancelledCount,
    required this.completedCount,
    required this.completedRate,
  });

  factory DoctorBookingStatsItem.fromJson(Map<String, dynamic> json) {
    return DoctorBookingStatsItem(
      doctor: DoctorInfo.fromJson(json['doctor'] as Map<String, dynamic>),
      total: json['total'] as int? ?? 0,
      bookedCount: json['bookedCount'] as int? ?? 0,
      confirmedCount: json['confirmedCount'] as int? ?? 0,
      cancelledCount: json['cancelledCount'] as int? ?? 0,
      completedCount: json['completedCount'] as int? ?? 0,
      completedRate: (json['completedRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'doctor': doctor.toJson(),
    'total': total,
    'bookedCount': bookedCount,
    'confirmedCount': confirmedCount,
    'cancelledCount': cancelledCount,
    'completedCount': completedCount,
    'completedRate': completedRate,
  };
}

class DoctorBookingStatsResponse {
  final List<DoctorBookingStatsItem> data;
  final Map<String, dynamic>? meta;

  DoctorBookingStatsResponse({required this.data, this.meta});

  factory DoctorBookingStatsResponse.fromJson(Map<String, dynamic> json) {
    return DoctorBookingStatsResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map(
                (e) =>
                    DoctorBookingStatsItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}

/// Doctor Content Stats Item for List
class DoctorContentStatsItem {
  final DoctorInfo doctor;
  final int totalReviews;
  final double averageRating;
  final int totalAnswers;
  final int totalAcceptedAnswers;
  final double answerAcceptedRate;
  final int totalBlogs;

  DoctorContentStatsItem({
    required this.doctor,
    required this.totalReviews,
    required this.averageRating,
    required this.totalAnswers,
    required this.totalAcceptedAnswers,
    required this.answerAcceptedRate,
    required this.totalBlogs,
  });

  factory DoctorContentStatsItem.fromJson(Map<String, dynamic> json) {
    return DoctorContentStatsItem(
      doctor: DoctorInfo.fromJson(json['doctor'] as Map<String, dynamic>),
      totalReviews: json['totalReviews'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalAnswers: json['totalAnswers'] as int? ?? 0,
      totalAcceptedAnswers: json['totalAcceptedAnswers'] as int? ?? 0,
      answerAcceptedRate:
          (json['answerAcceptedRate'] as num?)?.toDouble() ?? 0.0,
      totalBlogs: json['totalBlogs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'doctor': doctor.toJson(),
    'totalReviews': totalReviews,
    'averageRating': averageRating,
    'totalAnswers': totalAnswers,
    'totalAcceptedAnswers': totalAcceptedAnswers,
    'answerAcceptedRate': answerAcceptedRate,
    'totalBlogs': totalBlogs,
  };
}

class DoctorContentStatsResponse {
  final List<DoctorContentStatsItem> data;
  final Map<String, dynamic>? meta;

  DoctorContentStatsResponse({required this.data, this.meta});

  factory DoctorContentStatsResponse.fromJson(Map<String, dynamic> json) {
    return DoctorContentStatsResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map(
                (e) =>
                    DoctorContentStatsItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}
