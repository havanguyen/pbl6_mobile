import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/doctor_detail.dart';
import 'package:pbl6mobile/model/entities/doctor_profile.dart';
import 'package:pbl6mobile/model/entities/doctor_response.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/services/store.dart';

class DoctorService {
  const DoctorService._();

  static final String? _baseUrl = dotenv.env['API_BASE_URL'];
  static final Dio _dio = _initializeDio();

  static Dio _initializeDio() {
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
                e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final response = await dio.fetch(e.requestOptions);
                return handler.resolve(response);
              }
            } catch (err) {
              return handler.reject(e);
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
        if (createdFrom != null && createdFrom.isNotEmpty) 'createdFrom': createdFrom,
        if (createdTo != null && createdTo.isNotEmpty) 'createdTo': createdTo,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
        if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
      };

      final response = await _dio.get('/doctors', queryParameters: params);

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
      return GetDoctorsResponse(success: false, message: response.data['message'] ?? 'API call failed');
    } on DioException catch (e) {
      return GetDoctorsResponse(success: false, message: 'Lỗi kết nối: ${e.message}');
    } catch (e) {
      return GetDoctorsResponse(success: false, message: 'Đã xảy ra lỗi không mong muốn.');
    }
  }

  static Future<DoctorDetail?> getDoctorWithProfile(String doctorId) async {
    try {
      final response = await _dio.get('/doctors/$doctorId/complete');
      if (response.statusCode == 200) {
        return DoctorDetail.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Get Doctor with Profile Error: $e');
      return null;
    }
  }

  static Future<DoctorProfile?> createDoctorProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/doctors/profile', data: data);
      if (response.statusCode == 201) {
        return DoctorProfile.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Create Doctor Profile Error: $e');
      return null;
    }
  }

  static Future<DoctorProfile?> updateDoctorProfile(String profileId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/doctors/profile/$profileId', data: data);
      if (response.statusCode == 200) {
        return DoctorProfile.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Update Doctor Profile Error: $e');
      return null;
    }
  }

  static Future<bool> toggleDoctorActive(String profileId, bool isActive) async {
    try {
      final response = await _dio.patch(
        '/doctors/profile/$profileId/toggle-active',
        data: {'isActive': isActive},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Toggle Doctor Active Error: $e');
      return false;
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

      final response = await _dio.post('/doctors', data: requestBody);

      if (response.statusCode == 201) {
        final newDoctorId = response.data['data']?['id'];
        if (newDoctorId != null) {
          final profile = await createDoctorProfile({'staffAccountId': newDoctorId});
          return profile != null;
        }
      }
      return false;
    } catch (e) {
      print('Lỗi khi tạo bác sĩ và hồ sơ: $e');
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
        if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'dateOfBirth': dateOfBirth,
        if (isMale != null) 'isMale': isMale.toString(),
      };

      if (requestBody.isEmpty) return false;

      final response = await _dio.patch('/doctors/$id', data: requestBody);
      return response.statusCode == 200;
    } catch (e) {
      print('Update Doctor Error: $e');
      return false;
    }
  }

  static Future<bool> deleteDoctor(String id, {required String password}) async {
    try {
      final isPasswordValid = await AuthService.verifyPassword(password: password);
      if (!isPasswordValid) {
        print('Password verification failed');
        return false;
      }

      final response = await _dio.delete('/doctors/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Delete Doctor Error: $e');
      return false;
    }
  }
}