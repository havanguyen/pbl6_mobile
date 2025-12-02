import 'package:dio/dio.dart';
import 'package:pbl6mobile/model/entities/office_hour.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';

class OfficeHourService {
  final Dio _dio = AuthService.getSecureDioInstance();

  Future<List<OfficeHour>?> getOfficeHours({
    String? doctorId,
    String? workLocationId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (doctorId != null) queryParams['doctorId'] = doctorId;
      if (workLocationId != null)
        queryParams['workLocationId'] = workLocationId;

      final response = await _dio.get(
        '/office-hours',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final groupedData = data['data'];
          // Flatten the grouped response similar to React hook
          final List<dynamic> allOfficeHours = [
            ...groupedData['global'] ?? [],
            ...groupedData['workLocation'] ?? [],
            ...groupedData['doctor'] ?? [],
            ...groupedData['doctorInLocation'] ?? [],
          ];

          return allOfficeHours
              .map((json) => OfficeHour.fromJson(json))
              .toList();
        }
      }
      return null;
    } catch (e) {
      print('Error fetching office hours: $e');
      return null;
    }
  }

  Future<bool> createOfficeHour({
    String? doctorId,
    String? workLocationId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    bool isGlobal = false,
  }) async {
    try {
      final response = await _dio.post(
        '/office-hours',
        data: {
          'doctorId': doctorId,
          'workLocationId': workLocationId,
          'dayOfWeek': dayOfWeek,
          'startTime': startTime,
          'endTime': endTime,
          'isGlobal': isGlobal,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error creating office hour: $e');
      return false;
    }
  }

  Future<bool> deleteOfficeHour(String id) async {
    try {
      final response = await _dio.delete('/office-hours/$id');

      if (response.statusCode == 200) {
        return response.data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error deleting office hour: $e');
      return false;
    }
  }
}
