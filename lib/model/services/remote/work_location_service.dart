import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/services/store.dart';

class LocationWorkService {
  const LocationWorkService._();

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

  static Future<Map<String, dynamic>> getAllLocations({
    String sortBy = 'createdAt',
    String sortOrder = 'ASC',
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final params = {
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'includeMetadata': true,
        'page': page,
        'limit': limit,
      };
      final response = await _dio.get('/work-locations', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getLocationById(String id) async {
    try {
      final response = await _dio.get('/work-locations/$id');
      return response.data;
    } catch (e) {
      return {'success': false, 'data': null, 'message': e.toString()};
    }
  }

  static Future<bool> createLocation({
    required String name,
    required String address,
    required String phone,
    required String timezone,
  }) async {
    try {
      final requestBody = {
        'name': name,
        'address': address,
        'phone': phone,
        'timezone': timezone,
      };
      final response = await _dio.post('/work-locations', data: requestBody);
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateLocation({
    required String id,
    String? name,
    String? address,
    String? phone,
    String? timezone,
    bool? isActive,
  }) async {
    try {
      final requestBody = {
        if (name != null && name.isNotEmpty) 'name': name,
        if (address != null && address.isNotEmpty) 'address': address,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
        if (isActive != null) 'isActive': isActive,
      };
      if (requestBody.isEmpty) return false;
      final response = await _dio.patch('/work-locations/$id', data: requestBody);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteLocation(String id, {required String password}) async {
    try {
      if (!await AuthService.verifyPassword(password: password)) {
        return false;
      }
      final response = await _dio.delete('/work-locations/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}