import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/entities/specialty_response.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/services/store.dart';

class SpecialtyService {
  const SpecialtyService._();

  static final String? _baseUrl = dotenv.env['API_BASE_URL'];
  static final Dio _dio = _initializeDio();

  static Dio _initializeDio() {
    print('--- [DEBUG] SpecialtyService initializing Dio ---');
    print('--- [DEBUG] Base URL: $_baseUrl ---');
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
        // ...
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
          print(
            '--- [DEBUG] SpecialtyService Request: ${options.method} ${options.path} ---',
          );
          final accessToken = await Store.getAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          print(
            '--- [ERROR] SpecialtyService DioError: ${e.message}, Status: ${e.response?.statusCode} ---',
          );
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

  static Future<GetSpecialtiesResponse> getAllSpecialties({
    int page = 1,
    int limit = 10,
    String? search,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  }) async {
    try {
      final params = {
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _dio.get('/specialties', queryParameters: params);

      if (response.statusCode == 200) {
        final specialtyList = (response.data['data'] as List)
            .map((json) => Specialty.fromJson(json as Map<String, dynamic>))
            .toList();
        return GetSpecialtiesResponse(
          success: true,
          data: specialtyList,
          meta: response.data['meta'] ?? {},
        );
      }
      return GetSpecialtiesResponse(
        success: false,
        message: response.data['message'] ?? 'API call failed',
      );
    } catch (e) {
      return GetSpecialtiesResponse(success: false, message: 'Lỗi: $e');
    }
  }

  static Future<List<Specialty>> getPublicSpecialties() async {
    try {
      final response = await _dio.get('/specialties/public');

      if (response.statusCode == 200) {
        if (response.data is List) {
          return (response.data as List)
              .map((json) => Specialty.fromJson(json as Map<String, dynamic>))
              .toList();
        } else if (response.data is Map && response.data['data'] is List) {
          return (response.data['data'] as List)
              .map((json) => Specialty.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching public specialties: $e');
      return [];
    }
  }

  static Future<bool> createSpecialty({
    required String name,
    String? description,
  }) async {
    try {
      final requestBody = {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      };
      final response = await _dio.post('/specialties', data: requestBody);
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateSpecialty({
    required String id,
    String? name,
    String? description,
  }) async {
    try {
      final requestBody = {
        if (name != null && name.isNotEmpty) 'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      };
      if (requestBody.isEmpty) return false;
      final response = await _dio.patch('/specialties/$id', data: requestBody);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteSpecialty(
    String id, {
    required String password,
  }) async {
    try {
      if (!await AuthService.verifyPassword(password: password)) {
        return false;
      }
      final response = await _dio.delete('/specialties/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getInfoSections(
    String specialtyId,
  ) async {
    try {
      final response = await _dio.get(
        '/specialties/$specialtyId/info-sections',
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return {'success': false, 'data': []};
    } catch (e) {
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  static Future<bool> createInfoSection({
    required String specialtyId,
    required String name,
    required String content,
  }) async {
    try {
      final requestBody = {
        'specialtyId': specialtyId,
        'name': name,
        'content': content,
      };
      final response = await _dio.post(
        '/specialties/info-sections',
        data: requestBody,
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateInfoSection({
    required String id,
    String? name,
    String? content,
  }) async {
    try {
      final requestBody = {
        if (name != null && name.isNotEmpty) 'name': name,
        if (content != null && content.isNotEmpty) 'content': content,
      };
      if (requestBody.isEmpty) return false;
      final response = await _dio.patch(
        '/specialties/info-sections/$id',
        data: requestBody,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteInfoSection(
    String id, {
    required String password,
  }) async {
    try {
      if (!await AuthService.verifyPassword(password: password)) {
        return false;
      }
      final response = await _dio.delete('/specialties/info-section/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
