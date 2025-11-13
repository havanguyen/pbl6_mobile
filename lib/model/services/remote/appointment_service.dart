import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/appointment_response.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';

class AppointmentService {
  final Dio _dio = AuthService.getSecureDioInstance();

  Future<AppointmentResponse?> getAppointments({
    required DateTime fromDate,
    required DateTime toDate,
    String? status,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final params = {
        'fromDate': formatter.format(fromDate),
        'toDate': formatter.format(toDate),
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      };

      final response = await _dio.get(
        '/appointments',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        return AppointmentResponse.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print("Get appointments error: $e");
      if (e.response != null) {
        print("DioException Response: ${e.response?.data}");
      }
      return null;
    } catch (e) {
      print("Unexpected error: $e");
      return null;
    }
  }
}