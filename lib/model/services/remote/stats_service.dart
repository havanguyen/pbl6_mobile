import 'package:dio/dio.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/model/entities/stats/stats.types.dart';

class StatsService {
  StatsService._();

  static final Dio _dio = AuthService.getSecureDioInstance();

  /// GET /staffs/stats
  static Future<StaffStats?> getStaffStats() async {
    try {
      final response = await _dio.get('/staffs/stats');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          return StaffStats.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      // Allow DioException to propagate or handle logging here
      if (e is DioException) {
        // Optionally log or rethrow specific errors
      }
      rethrow;
    }
  }

  /// GET /stats/revenue
  static Future<List<RevenueStats>> getRevenueStats() async {
    try {
      final response = await _dio.get('/stats/revenue');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((e) => RevenueStats.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// GET /stats/revenue-by-doctor
  static Future<List<RevenueByDoctorStats>> getRevenueByDoctorStats({
    int limit = 5,
  }) async {
    try {
      final response = await _dio.get(
        '/stats/revenue-by-doctor',
        queryParameters: {'limit': limit},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((e) => RevenueByDoctorStats.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// GET /stats/patients
  static Future<PatientStats?> getPatientStats() async {
    try {
      final response = await _dio.get('/stats/patients');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          return PatientStats.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /stats/appointments
  static Future<AppointmentStats?> getAppointmentStats() async {
    try {
      final response = await _dio.get('/stats/appointments');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          return AppointmentStats.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /stats/reviews-overview
  static Future<ReviewsOverviewStats?> getReviewsOverviewStats() async {
    try {
      final response = await _dio.get('/stats/reviews-overview');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          return ReviewsOverviewStats.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /stats/qa-overview
  static Future<QAOverviewStats?> getQAOverviewStats() async {
    try {
      final response = await _dio.get('/stats/qa-overview');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          return QAOverviewStats.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /stats/doctors/me
  static Future<DoctorMyStats?> getDoctorMyStats() async {
    try {
      final response = await _dio.get('/stats/doctors/me');
      if (response.statusCode == 200 && response.data != null) {
        // The API returns the object directly or wrapped in data?
        // ReactJS: return response.data
        // Flutter usually wraps in 'data' field standard response.
        // Assuming standard response wrapper:
        final data = response.data['data'] ?? response.data;
        if (data != null) {
          return DoctorMyStats.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        // Handle specific errors potentially
      }
      rethrow;
    }
  }

  /// GET /stats/doctors/booking
  static Future<DoctorBookingStatsResponse?> getDoctorsBookingStats({
    int page = 1,
    int limit = 10,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final response = await _dio.get(
        '/stats/doctors/booking',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (sortBy != null) 'sortBy': sortBy,
          if (sortOrder != null) 'sortOrder': sortOrder,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        // API usually wraps in standard response, but TS impl suggests direct data mapping
        // Assuming standard backend response structure: { success: true, data: { data: [], meta: {} } }
        // or directly { data: [], meta: {} } if 'data' field is the payload.
        // Let's assume standard response handling:
        if (response.data != null) {
          return DoctorBookingStatsResponse.fromJson(response.data);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /stats/doctors/content
  static Future<DoctorContentStatsResponse?> getDoctorsContentStats({
    int page = 1,
    int limit = 10,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final response = await _dio.get(
        '/stats/doctors/content',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (sortBy != null) 'sortBy': sortBy,
          if (sortOrder != null) 'sortOrder': sortOrder,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        if (response.data != null) {
          return DoctorContentStatsResponse.fromJson(response.data);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
