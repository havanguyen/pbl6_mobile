import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/doctor_detail.dart';
import 'package:pbl6mobile/model/entities/doctor_profile.dart';
import 'package:pbl6mobile/model/entities/doctor_response.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/services/store.dart';

class DoctorService {
  const DoctorService._();

  static final String? _baseUrl = dotenv.env['API_BASE_URL'];
  static final Dio _secureDio = _initializeSecureDio();

  static Dio _initializeSecureDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl!,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        logPrint: print,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
        ],
        retryableExtraStatuses: {status429TooManyRequests},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await Store.getAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            try {
              final refreshSuccess = await AuthService.refreshToken();
              if (refreshSuccess) {
                final newAccessToken = await Store.getAccessToken();
                e.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
                final options = Options(
                  method: e.requestOptions.method,
                  headers: e.requestOptions.headers,
                );
                final response = await dio.request(
                  e.requestOptions.path,
                  options: options,
                  data: e.requestOptions.data,
                  queryParameters: e.requestOptions.queryParameters,
                );
                return handler.resolve(response);
              } else {
                await AuthService.logout();
              }
            } catch (err) {
              await AuthService.logout();
              return handler.reject(DioException(
                requestOptions: e.requestOptions,
                error: err,
                response: e.response,
              ));
            }
          }
          return handler.next(e);
        },
      ),
    );

    return dio;
  }

  static Future<GetDoctorsResponse> getDoctors({
    String search = '',
    int page = 1,
    int limit = 10,
    bool? isMale,
    String? createdFrom,
    String? createdTo,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final params = {
        'page': page,
        'limit': limit,
        if (search.isNotEmpty) 'search': search,
        if (isMale != null) 'isMale': isMale,
        if (createdFrom != null && createdFrom.isNotEmpty)
          'createdFrom': createdFrom,
        if (createdTo != null && createdTo.isNotEmpty) 'createdTo': createdTo,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
        if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
      };

      final response = await _secureDio.get('/doctors', queryParameters: params);

      if (response.statusCode == 200) {
        final doctorList = (response.data['data'] as List)
            .map((json) => Doctor.fromJson(json as Map<String, dynamic>))
            .toList();
        return GetDoctorsResponse(
          success: true,
          data: doctorList,
          meta: response.data['meta'] ?? {},
        );
      }
      return GetDoctorsResponse(
          success: false, message: response.data['message'] ?? 'API call failed');
    } on DioException catch (e) {
      return GetDoctorsResponse(
          success: false, message: 'Lỗi kết nối: ${e.message}');
    } catch (e) {
      return GetDoctorsResponse(
          success: false, message: 'Đã xảy ra lỗi không mong muốn.');
    }
  }

  static Future<DoctorDetail?> getDoctorWithProfile(String doctorId) async {
    try {
      final response = await _secureDio.get('/doctors/$doctorId/complete');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final Map<String, dynamic> dataToParse = response.data['data'];

        debugPrint("--- [DEBUG] BẮT ĐẦU PARSE GetDoctorWithProfile ---");
        debugPrint(jsonEncode(dataToParse));

        try {
          if (dataToParse['specialties'] != null) {
            debugPrint("[DEBUG] Đang parse Specialties...");
            (dataToParse['specialties'] as List<dynamic>)
                .forEach((e) => Specialty.fromJson(e as Map<String, dynamic>));
            debugPrint("[DEBUG] Parse Specialties THÀNH CÔNG");
          }

          if (dataToParse['workLocations'] != null) {
            debugPrint("[DEBUG] Đang parse WorkLocations...");
            (dataToParse['workLocations'] as List<dynamic>).forEach(
                    (e) => WorkLocation.fromJson(e as Map<String, dynamic>));
            debugPrint("[DEBUG] Parse WorkLocations THÀNH CÔNG");
          }

          debugPrint("[DEBUG] Đang parse DoctorDetail (chính)...");
          final doctorDetail = DoctorDetail.fromJson(dataToParse);
          debugPrint("[DEBUG] PARSE DOCTOR DETAIL THÀNH CÔNG!");

          return doctorDetail;
        } catch (e, stackTrace) {
          debugPrint("--- [DEBUG] LỖI PARSING NGHIÊM TRỌNG ---");
          debugPrint("Lỗi: ${e.toString()}");
          debugPrint("Stack Trace: $stackTrace");

          if (e is TypeError) {
            debugPrint(
                "LỖI TYPEERROR: Rất có thể một model con (Specialty, WorkLocation) bị lỗi cast.");
          }
          debugPrint("--- HẾT LỖI PARSING ---");
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Get Doctor with Profile Error: $e');
      if (e is DioException) {
        print('DioException response: ${e.response?.data}');
      }
      return null;
    }
  }

  static Future<DoctorProfile?> createDoctorProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _secureDio.post('/doctors/profile', data: data);
      if (response.statusCode == 201 && response.data['data'] != null) {
        return DoctorProfile.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Create Doctor Profile Error: $e');
      if (e is DioException) {
        print('DioException response: ${e.response?.data}');
      }
      return null;
    }
  }

  static Future<DoctorProfile?> updateDoctorProfile(
      String profileId, Map<String, dynamic> data) async {
    try {
      final response =
      await _secureDio.patch('/doctors/profile/$profileId', data: data);
      if (response.statusCode == 200 && response.data['data'] != null) {
        return DoctorProfile.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Update Doctor Profile Error: $e');
      if (e is DioException) {
        print('DioException response: ${e.response?.data}');
      }
      return null;
    }
  }

  static Future<DoctorProfile?> toggleDoctorActive(
      String profileId, bool isActive) async {
    try {
      print(
          "➡️ [SERVICE] Sending PATCH request to '/doctors/profile/$profileId/toggle-active'");
      print("   - Payload: {'isActive': $isActive}");

      final response = await _secureDio.patch(
        '/doctors/profile/$profileId/toggle-active',
        data: {'isActive': isActive},
      );

      print(
          "⬅️ [SERVICE] Received response with statusCode: ${response.statusCode}");

      if (response.statusCode == 200 && response.data['data'] != null) {
        print("   - Response data: ${response.data['data']}");
        final profile = DoctorProfile.fromJson(response.data['data']);
        print(
            "   - Successfully parsed DoctorProfile. New isActive: ${profile.isActive}");
        return profile;
      } else {
        print(
            "   - Response was successful but data is null or status code is not 200.");
        return null;
      }
    } catch (e) {
      print("🔥 [SERVICE-ERROR] Toggle Doctor Active failed: $e");
      if (e is DioException) {
        print("   - DioException details: ${e.response?.data}");
      }
      return null;
    }
  }

  static Future<bool> createDoctor({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String dateOfBirth,
    required bool isMale,
  }) async {
    try {
      final requestBody = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'isMale': isMale.toString(),
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };

      final response = await _secureDio.post('/doctors', data: requestBody);

      return response.statusCode == 201;
    } catch (e) {
      print('Lỗi khi tạo bác sĩ: $e');
      if (e is DioException) {
        print('DioException response: ${e.response?.data}');
      }
      return false;
    }
  }

  static Future<bool> updateDoctor(
      String id, {
        String? fullName,
        String? email,
        String? password,
        String? phone,
        String? dateOfBirth,
        bool? isMale,
      }) async {
    try {
      final requestBody = {
        if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (dateOfBirth != null && dateOfBirth.isNotEmpty)
          'dateOfBirth': dateOfBirth,
        if (isMale != null) 'isMale': isMale.toString(),
      };

      if (requestBody.isEmpty) return false;

      final response = await _secureDio.patch('/doctors/$id', data: requestBody);
      return response.statusCode == 200;
    } catch (e) {
      print('Update Doctor Error: $e');
      if (e is DioException) {
        print('DioException response: ${e.response?.data}');
      }
      return false;
    }
  }

  static Future<bool> deleteDoctor(String id, {required String password}) async {
    try {
      final isPasswordValid =
      await AuthService.verifyPassword(password: password);
      if (!isPasswordValid) {
        print('Password verification failed');
        return false;
      }

      final response = await _secureDio.delete('/doctors/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Delete Doctor Error: $e');
      if (e is DioException) {
        print('DioException response: ${e.response?.data}');
      }
      return false;
    }
  }

  static Future<DoctorDetail?> getSelfProfileComplete() async {
    try {
      final response = await _secureDio.get('/doctors/profile/me');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final Map<String, dynamic> dataToParse = response.data['data'];

        debugPrint("--- [DEBUG] BẮT ĐẦU PARSE GetSelfProfileComplete ---");
        debugPrint(jsonEncode(dataToParse));

        try {
          if (dataToParse['specialties'] != null) {
            debugPrint("[DEBUG] Đang parse Specialties...");
            (dataToParse['specialties'] as List<dynamic>)
                .forEach((e) => Specialty.fromJson(e as Map<String, dynamic>));
            debugPrint("[DEBUG] Parse Specialties THÀNH CÔNG");
          }

          if (dataToParse['workLocations'] != null) {
            debugPrint("[DEBUG] Đang parse WorkLocations...");
            (dataToParse['workLocations'] as List<dynamic>).forEach(
                    (e) => WorkLocation.fromJson(e as Map<String, dynamic>));
            debugPrint("[DEBUG] Parse WorkLocations THÀNH CÔNG");
          }

          debugPrint("[DEBUG] Đang parse DoctorDetail (chính)...");
          final doctorDetail = DoctorDetail.fromJson(dataToParse);
          debugPrint("[DEBUG] PARSE DOCTOR DETAIL THÀNH CÔNG!");

          return doctorDetail;
        } catch (e, stackTrace) {
          debugPrint("--- [DEBUG] LỖI PARSING NGHIÊM TRỌNG ---");
          debugPrint("Lỗi: ${e.toString()}");
          debugPrint("Stack Trace: $stackTrace");

          if (e is TypeError) {
            debugPrint(
                "LỖI TYPEERROR: Rất có thể một model con (Specialty, WorkLocation) bị lỗi cast.");
          }
          debugPrint("--- HẾT LỖI PARSING ---");
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Get Self Profile Complete Error: $e');
      if (e is DioException) {
        print('DioException response: ${e.response?.data}');
      }
      return null;
    }
  }

  static Future<DoctorProfile?> updateSelfProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _secureDio.patch('/doctors/profile/me', data: data);
      if (response.statusCode == 200 && response.data['data'] != null) {
        return DoctorProfile.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Update Self Profile Error: $e');
      if (e is DioException) {
        print('DioException response: ${e.response?.data}');
      }
      return null;
    }
  }
}