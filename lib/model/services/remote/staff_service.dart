import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/model/entities/admin_response.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/services/store.dart';

class StaffService {
  const StaffService._();

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
              if (await AuthService.refreshToken()) {
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

  static Future<GetAdminsResponse> getAdmins({
    String search = '',
    int page = 1,
    int limit = 10,
    bool? isMale,
    String? email,
    String? createdFrom,
    String? createdTo,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final params = {
        'page': page,
        'limit': limit,
        'role': 'ADMIN',
        if (search.isNotEmpty) 'search': search,
        if (isMale != null) 'isMale': isMale,
        if (email != null && email.isNotEmpty) 'email': email,
        if (createdFrom != null && createdFrom.isNotEmpty) 'createdFrom': createdFrom,
        if (createdTo != null && createdTo.isNotEmpty) 'createdTo': createdTo,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
        if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
      };
      final response = await _dio.get('/staffs', queryParameters: params);

      if (response.statusCode == 200) {
        final staffList = (response.data['data'] as List)
            .map((json) => Staff.fromJson(json as Map<String, dynamic>))
            .toList();
        return GetAdminsResponse(
          success: true,
          data: staffList,
          meta: response.data['meta'] ?? {},
        );
      }
      return GetAdminsResponse(success: false, message: response.data['message'] ?? 'API call failed');
    } catch (e) {
      return GetAdminsResponse(success: false, message: 'Lỗi: $e');
    }
  }

  static Future<bool> createAdmin({
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
        'role': 'ADMIN',
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };
      final response = await _dio.post('/staffs', data: requestBody);
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateStaff(
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
      final response = await _dio.patch('/staffs/$id', data: requestBody);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteStaff(String id, {required String password}) async {
    try {
      if (!await AuthService.verifyPassword(password: password)) {
        return false;
      }
      final response = await _dio.delete('/staffs/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}