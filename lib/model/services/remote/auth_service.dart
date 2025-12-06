import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pbl6mobile/shared/services/store.dart';

import '../../entities/profile.dart';
import '../local/profile_cache_service.dart';
import 'package:pbl6mobile/shared/utils/global_keys.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';

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

  static Dio getSecureDioInstance() => _secureDio;

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
          print('--> ${options.method.toUpperCase()} ${options.uri}');
          print('Headers: ${options.headers}');
          if (options.data != null) {
            print('Body: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('<-- ${response.statusCode} ${response.requestOptions.uri}');
          print('Response: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          print('*** DioError ***');
          print('Error: ${e.message}');
          if (e.response != null) {
            print('Error Response Status: ${e.response?.statusCode}');
            print('Error Response Data: ${e.response?.data}');
          } else {
            print('Error Request Options: ${e.requestOptions}');
          }

          if (e.response?.statusCode == 401) {
            print('--- Handling 401 Unauthorized ---');
            if (e.requestOptions.path == '/auth/refresh') {
              print('Refresh token failed with 401, logging out.');
              await logout();
              return handler.reject(e);
            }

            try {
              print('Attempting to refresh token...');
              if (await refreshToken()) {
                print(
                  'Token refreshed successfully. Retrying original request...',
                );
                final newAccessToken = await Store.getAccessToken();
                e.requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';

                final response = await _secureDio.fetch(e.requestOptions);
                return handler.resolve(response);
              } else {
                print('Refresh token failed, logging out.');
                await logout();
              }
            } catch (err) {
              print('Error during token refresh or retry: $err');
              await logout();
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
        if (data != null &&
            data['access_token'] != null &&
            data['refresh_token'] != null &&
            data['user']?['role'] != null) {
          await Store.setAccessToken(data['access_token']);
          await Store.setRefreshToken(data['refresh_token']);
          await Store.setUserRole(data['user']['role']);
          print('Login successful for role: ${data['user']['role']}');
          return true;
        } else {
          print('Login response missing data: ${response.data}');
          return false;
        }
      }
      print('Login failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      print("Login error: $e");
      if (e is DioException) {
        print("DioException Response: ${e.response?.data}");
      }
      return false;
    }
  }

  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await Store.getRefreshToken();
      if (refreshToken == null) {
        print('No refresh token found.');
        return false;
      }
      print('Attempting to refresh token...');
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null &&
            data['access_token'] != null &&
            data['refresh_token'] != null) {
          await Store.setAccessToken(data['access_token']);
          await Store.setRefreshToken(data['refresh_token']);
          print('Token refreshed successfully.');
          return true;
        } else {
          print('Refresh token response missing data: ${response.data}');
          await logout();
          return false;
        }
      }
      print('Refresh token failed with status: ${response.statusCode}');
      await logout();
      return false;
    } catch (e) {
      print("Refresh token error: $e");
      if (e is DioException) {
        print("DioException Response: ${e.response?.data}");
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          print('Refresh token invalid, logging out.');
          await logout();
        }
      } else {
        print('Non-Dio error during refresh: $e');
      }
      return false;
    }
  }

  static Future<bool> logout() async {
    print('Logging out...');
    try {
      final refreshToken = await Store.getRefreshToken();
      if (refreshToken != null) {
        await _secureDio.delete('/auth/logout');
        print('API logout call successful.');
      } else {
        print('No refresh token found, skipping API logout call.');
      }
    } catch (e) {
      print("Error during API logout call: $e");
      if (e is DioException) {
        print("DioException Response: ${e.response?.data}");
      }
    } finally {
      await Store.clearStorage();
      await ProfileCacheService.instance.clearProfile();
      print('Local storage cleared.');
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.login,
        (route) => false,
      );
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
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Change password error: $e");
      if (e is DioException) {
        print("DioException Response: ${e.response?.data}");
      }
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
      if (response.statusCode == 200 && response.data?['data'] != null) {
        return Profile.fromJson(response.data['data']);
      }
      print('Get profile failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      print("Get profile error: $e");
      if (e is DioException) {
        print("DioException Response: ${e.response?.data}");
      }
      return null;
    }
  }

  static Future<bool> verifyPassword({required String password}) async {
    try {
      final response = await _secureDio.post(
        '/auth/verify-password',
        data: {'password': password},
      );
      if (response.statusCode == 201 && response.data != null) {
        return response.data['success'] ?? false;
      }
      print('Verify password failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      print("Verify password error: $e");
      if (e is DioException) {
        print("DioException Response: ${e.response?.data}");
      }
      return false;
    }
  }

  static Future<bool> requestPasswordReset({required String email}) async {
    try {
      final response = await _dio.post(
        '/auth/password-reset/request',
        data: {'email': email},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Request password reset error: $e");
      if (e is DioException) {
        print("DioException Response: ${e.response?.data}");
      }
      return false;
    }
  }

  static Future<bool> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/password-reset/verify-code',
        data: {'email': email, 'code': code},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Verify reset code error: $e");
      if (e is DioException) {
        print("DioException Response: ${e.response?.data}");
      }
      return false;
    }
  }

  static Future<bool> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/password-reset/confirm',
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Confirm password reset error: $e");
      if (e is DioException) {
        print("DioException Response: ${e.response?.data}");
      }
      return false;
    }
  }
}
