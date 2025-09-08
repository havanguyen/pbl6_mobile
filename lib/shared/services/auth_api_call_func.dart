import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pbl6mobile/shared/services/store.dart';

class AuthApiCallFunc {
  const AuthApiCallFunc._();

  static const AuthApiCallFunc instance = AuthApiCallFunc._();
  static final String? _baseUrl = dotenv.env['API_BASE_URL'];

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final Map<String, dynamic> data = responseData['data'];

        await Store.setAccessToken(data['token']);
        await Store.setRefreshToken(data['refreshToken']);
        await Store.setUserRole( data['user']['role']);

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
        'refreshToken': refreshToken,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/refresh'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final Map<String, dynamic> data = responseData['data'];

        await Store.setRefreshToken(data['refreshToken']);
        await Store.setAccessToken(data['token']);

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
        Uri.parse('$_baseUrl/logout'),
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
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        print('No access token for change password');
        return false;
      }

      final Map<String, dynamic> requestBody = {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Password changed successfully');
        return true;
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
}