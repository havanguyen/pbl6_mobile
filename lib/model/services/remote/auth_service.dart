import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pbl6mobile/shared/services/store.dart';

import '../../entities/profile.dart';


class AuthService {
  const AuthService._();

  static final String? _baseUrl = dotenv.env['API_BASE_URL'];

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl!,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static final Dio _secureDio = _initializeSecureDio();

  static Dio _initializeSecureDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl!,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
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
              if (await refreshToken()) {
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

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'];
        await Store.setAccessToken(data['access_token']);
        await Store.setRefreshToken(data['refresh_token']);
        await Store.setUserRole(data['user']['role']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await Store.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'];
        await Store.setAccessToken(data['access_token']);
        await Store.setRefreshToken(data['refresh_token']);
        return true;
      }
      await logout();
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> logout() async {
    try {
      await _secureDio.post('/auth/logout');
    } finally {
      await Store.clearStorage();
    }
    return true;
  }

  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _secureDio.post(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await Store.getAccessToken();
    return token != null;
  }

  static Future<Profile?> getProfile() async {
    try {
      final response = await _secureDio.get('/auth/profile');
      if (response.statusCode == 200) {
        return Profile.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> verifyPassword({
    required String password,
  }) async {
    try {
      final response = await _secureDio.post(
        '/auth/verify-password',
        data: {'password': password},
      );
      if (response.statusCode == 200) {
        return response.data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}