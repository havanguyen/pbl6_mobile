import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/dto/appointment_dto.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
import 'package:pbl6mobile/model/entities/appointment_response.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';

class AppointmentService {
  final Dio _dio = AuthService.getSecureDioInstance();

  Future<AppointmentResponse?> getAppointments({
    required DateTime fromDate,
    required DateTime toDate,
    String? status,
    String? doctorId,
    String? workLocationId,
    String? specialtyId,
    String? patientId,
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
        if (doctorId != null) 'doctorId': doctorId,
        if (workLocationId != null) 'workLocationId': workLocationId,
        if (specialtyId != null) 'specialtyId': specialtyId,
        if (patientId != null) 'patientId': patientId,
      };

      final response = await _dio.get('/appointments', queryParameters: params);
      print('--- [DEBUG] AppointmentService.getAppointments ---');
      print('Params: $params');
      print('Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Response Data count: ${(response.data['data'] as List).length}');
      } else {
        print('Response Body: ${response.data}');
      }

      if (response.statusCode == 200) {
        print('--- [DEBUG] Parsing AppointmentResponse... ---');
        final result = AppointmentResponse.fromJson(response.data);
        print(
          '--- [DEBUG] Parsed successfully. Success: ${result.success}, Data count: ${result.data.length} ---',
        );
        return result;
      }
      return null;
    } catch (e) {
      print('--- [ERROR] AppointmentService.getAppointments: $e');
      return null;
    }
  }

  Future<AppointmentData?> getAppointmentById(String id) async {
    try {
      final response = await _dio.get('/appointments/$id');
      if (response.statusCode == 200) {
        return AppointmentData.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<DoctorSlot>?> getDoctorSlots({
    required String doctorId,
    required String date,
    String? locationId,
  }) async {
    try {
      final params = {
        'doctorId': doctorId,
        'serviceDate': date,
        if (locationId != null) 'workLocationId': locationId,
      };

      final response = await _dio.get(
        '/doctors/profile/$doctorId/slots',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => DoctorSlot.fromJson(e)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> holdSlot(HoldAppointmentRequest request) async {
    try {
      final response = await _dio.post(
        '/appointments/hold',
        data: request.toJson(),
      );
      print('--- [DEBUG] holdSlot Status: ${response.statusCode} ---');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['data']['eventId'];
      }
      print('--- [ERROR] holdSlot Response: ${response.data} ---');
      return null;
    } catch (e) {
      print('--- [ERROR] holdSlot Exception: $e ---');
      return null;
    }
  }

  Future<bool> createAppointment(CreateAppointmentRequest request) async {
    try {
      final response = await _dio.post('/appointments', data: request.toJson());
      print('--- [DEBUG] createAppointment Status: ${response.statusCode} ---');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('--- [ERROR] createAppointment Response: ${response.data} ---');
      }
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('--- [ERROR] createAppointment Exception: $e ---');
      return false;
    }
  }

  Future<bool> cancelAppointment(String id, String reason) async {
    try {
      final response = await _dio.delete(
        '/appointments/$id',
        data: {'reason': reason},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rescheduleAppointment(
    String id,
    String timeStart,
    String timeEnd,
  ) async {
    try {
      final response = await _dio.patch(
        '/appointments/$id/reschedule',
        data: {'timeStart': timeStart, 'timeEnd': timeEnd},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> completeAppointment(String id) async {
    try {
      final response = await _dio.patch('/appointments/$id/complete');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> confirmAppointment(String id) async {
    try {
      final response = await _dio.patch('/appointments/$id/confirm');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAppointment(
    String id,
    String notes,
    double price,
    String currency,
    String status,
    String reason,
  ) async {
    try {
      final response = await _dio.patch(
        '/appointments/$id',
        data: {
          'notes': notes,
          'priceAmount': price,
          'currency': currency,
          'status': status,
          'reason': reason,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
