import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pbl6mobile/shared/services/store.dart';

import '../../entities/profile.dart';

class AuthService {
  const AuthService._();

  static const AuthService instance = AuthService._();
  static final String? _baseUrl = dotenv.env['API_BASE_URL'];

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Login with email: $email, password: $password');
      print('API URL: $_baseUrl/auth/login');
      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));
      print('Login response: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final Map<String, dynamic> data = responseData['data'];

        await Store.setAccessToken(data['access_token']);
        await Store.setRefreshToken(data['refresh_token']);
        await Store.setUserRole(data['user']['role']);

        return true;
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            print('Login error: ${errorData['message']}');
          } catch (e) {
            print('Login parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      print('Login network error: $e');
      return false;
    }
  }

  static Future<bool> refreshToken() async {
    try {
      final String? refreshToken = await Store.getRefreshToken();
      if (refreshToken == null) {
        print('No refresh token available');
        return false;
      }

      final Map<String, dynamic> requestBody = {
        'refresh_token': refreshToken,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final Map<String, dynamic> data = responseData['data'];

        await Store.setAccessToken(data['access_token']);
        await Store.setRefreshToken(data['refresh_token']);

        print('Token refreshed successfully');
        return true;
      } else {
        print('Refresh failed: ${response.statusCode}');
        await logout();
        return false;
      }
    } catch (e) {
      print('Refresh network error: $e');
      return false;
    }
  }

  static Future<bool> logout() async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        await Store.clearStorage();
        return true;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      await Store.clearStorage();

      if (response.statusCode == 200) {
        print('Logout successful');
        return true;
      } else {
        print('Logout API failed but storage cleared: ${response.statusCode}');
        return true;
      }
    } catch (e) {
      print('Logout error: $e');
      await Store.clearStorage();
      return false;
    }
  }

  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        print('No access token for change password');
        return false;
      }

      final Map<String, dynamic> requestBody = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Password changed successfully');
        return true;
      } else if (response.statusCode == 401) {
        final bool refreshSuccess = await refreshToken();
        if (!refreshSuccess) {
          print('Failed to refresh token for change password');
          return false;
        }

        final String? newAccessToken = await Store.getAccessToken();
        if (newAccessToken == null) {
          print('No new access token after refresh for change password');
          return false;
        }

        final retryResponse = await http.post(
          Uri.parse('$_baseUrl/auth/change-password'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newAccessToken',
          },
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 10));

        if (retryResponse.statusCode == 200) {
          print('Password changed successfully after refresh');
          return true;
        } else {
          if (retryResponse.body.isNotEmpty) {
            try {
              final Map<String, dynamic> errorData = jsonDecode(retryResponse.body);
              print('Change password error after refresh: ${errorData['message']}');
            } catch (e) {
              print('Change password parse error after refresh: $e');
            }
          }
          return false;
        }
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            print('Change password error: ${errorData['message']}');
          } catch (e) {
            print('Change password parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      print('Change password network error: $e');
      return false;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await Store.getAccessToken();
    return token != null;
  }

  static Future<Profile?> getProfile() async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        print('No access token for get profile');
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final Map<String, dynamic> data = responseData['data'];
        return Profile.fromJson(data);
      } else if (response.statusCode == 401) {
        final bool refreshSuccess = await refreshToken();
        if (!refreshSuccess) {
          print('Failed to refresh token');
          return null;
        }

        final String? newAccessToken = await Store.getAccessToken();
        if (newAccessToken == null) {
          print('No new access token after refresh');
          return null;
        }

        final retryResponse = await http.get(
          Uri.parse('$_baseUrl/auth/profile'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newAccessToken',
          },
        ).timeout(const Duration(seconds: 10));

        if (retryResponse.statusCode == 200) {
          final Map<String, dynamic> retryResponseData = jsonDecode(retryResponse.body);
          final Map<String, dynamic> data = retryResponseData['data'];
          return Profile.fromJson(data);
        } else {
          if (retryResponse.body.isNotEmpty) {
            try {
              final Map<String, dynamic> errorData = jsonDecode(retryResponse.body);
              print('Get profile error after refresh: ${errorData['message']}');
            } catch (e) {
              print('Get profile parse error after refresh: $e');
            }
          }
          return null;
        }
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            print('Get profile error: ${errorData['message']}');
          } catch (e) {
            print('Get profile parse error: $e');
          }
        }
        return null;
      }
    } catch (e) {
      print('Get profile network error: $e');
      return null;
    }
  }
}